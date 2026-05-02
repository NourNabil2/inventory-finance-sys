// lib/features/customers/presentation/cubit/invoices_cubit.dart
// Full replacement — fixes:
//   1. recordPayment now immediately updates paymentSummary in state
//   2. returnSingleItem accepts qty
//   3. Return allowed on any non-canceled invoice

import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/invoices_repository.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

part 'invoices_state.dart';

class InvoicesCubit extends Cubit<InvoicesState> {
  final InvoicesRepository _repository;

  List<InvoiceEntity> _currentInvoices = [];
  String? _currentCustomerId;

  InvoicesCubit(this._repository) : super(InvoicesInitial());

  // ── Fetch list ───────────────────────────────────────────────────────────

  Future<void> fetchInvoices(String customerId) async {
    _currentCustomerId = customerId;
    emit(InvoicesLoading());
    final result = await _repository.getCustomerInvoices(customerId);
    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (list) {
        _currentInvoices = list;
        emit(InvoicesLoaded(invoices: list));
      },
    );
  }

  // ── Select / deselect ────────────────────────────────────────────────────

  Future<void> selectInvoice(String? invoiceId) async {
    final current = state;

    if (invoiceId == null) {
      // لو عندنا invoices حطها، لو لأ ابعت empty list
      final invoices = current is InvoicesLoaded ? current.invoices : <InvoiceEntity>[];
      emit(InvoicesLoaded(invoices: invoices));
      return;
    }

    // ✅ مش محتاجين InvoicesLoaded عشان نجيب التفاصيل
    final previousInvoices = current is InvoicesLoaded
        ? current.invoices
        : <InvoiceEntity>[];

    emit(InvoicesLoading());

    final result = await _repository.getInvoiceDetails(invoiceId);
    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (invoice) async {
        final summaryResult = await _repository.getPaymentSummary(invoiceId);
        final summary = summaryResult.fold((_) => null, (s) => s);
        emit(InvoicesLoaded(
          invoices: previousInvoices, // ✅ مش هنخسر القائمة
          selectedInvoice: invoice,
          paymentSummary: summary,
        ));
      },
    );
  }

  // ── Create with payment ──────────────────────────────────────────────────

  Future<void> createInvoiceWithPayment({
    required InvoiceEntity invoice,
    required List<InvoiceItemEntity> items,
    required double amountPaid,
    required String method,
  }) async {
    emit(InvoicesLoading());
    final result = await _repository.createInvoiceWithPayment(
      invoice: invoice,
      items: items,
      amountPaid: amountPaid,
      method: method,
    );
    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (invoiceId) {
        emit(InvoiceCreated(invoiceId: invoiceId));
        if (_currentCustomerId != null) {
          fetchInvoices(_currentCustomerId!);
        }
      },
    );
  }

  // ── Record payment — updates summary IMMEDIATELY ─────────────────────────

  Future<void> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    emit(PaymentRecording());
    final result = await _repository.recordPaymentAndGetSummary(
      invoiceId: invoiceId,
      amount: amount,
      method: method,
    );
    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (freshSummary) async {
        // Emit PaymentRecorded WITH the fresh summary — no extra round-trip
        emit(PaymentRecorded(summary: freshSummary));

        // Refresh the invoice detail (status may have changed to 'completed')
        final detailResult = await _repository.getInvoiceDetails(invoiceId);
        detailResult.fold(
              (_) {},
              (invoice) {
            final current = state;
            final invoices = current is InvoicesLoaded
                ? current.invoices
                : _currentInvoices;
            emit(InvoicesLoaded(
              invoices: invoices,
              selectedInvoice: invoice,
              paymentSummary: freshSummary,
            ));
          },
        );

        // Refresh list (customer debt updated)
        if (_currentCustomerId != null) {
          fetchInvoices(_currentCustomerId!);
        }
      },
    );
  }

  // ── Return single item (with qty) ────────────────────────────────────────
  // Allowed on ANY non-canceled invoice (active OR completed)

  Future<void> returnSingleItem({
    required String invoiceItemId,
    required String invoiceId,
    int? qty, // null = return all remaining
  }) async {
    emit(ItemReturning(invoiceItemId: invoiceItemId));
    final result = await _repository.returnSingleItem(invoiceItemId, qty: qty);
    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (_) {
        emit(ItemReturned(invoiceItemId: invoiceItemId));
        // Refresh detail view
        selectInvoice(invoiceId);
        if (_currentCustomerId != null) {
          fetchInvoices(_currentCustomerId!);
        }
      },
    );
  }

  // ── Edit invoice ─────────────────────────────────────────────────────────

  Future<void> editInvoice({
    required String invoiceId,
    required InvoiceEntity originalInvoice,
    required List<InvoiceItemEntity> newItems,
    required Map<String, Map<String, dynamic>> modifiedItems, // 👈
    double? newDiscountFlat,
  }) async {
    emit(InvoicesLoading());

    final oldNetTotal = (originalInvoice.items
        .fold(0.0, (s, i) => s + i.lineTotal) -
        originalInvoice.discount)
        .clamp(0, double.infinity);

    double newSubtotal = 0;
    for (final item in originalInvoice.items) {
      final mod          = modifiedItems[item.id];
      final days         = (mod?['days']         as int?)    ?? item.days;
      final qty          = (mod?['qty']          as int?)    ?? item.qty;
      final pricePerDay  = (mod?['pricePerDay']  as double?) ?? item.pricePerDay;
      final flatDiscount = (mod?['flatDiscount'] as double?) ?? item.itemDiscount;
      newSubtotal +=
          (days * qty * pricePerDay - flatDiscount).clamp(0, double.infinity);
    }
    for (final item in newItems) {
      newSubtotal += item.lineTotal;
    }

    final newDiscount    = newDiscountFlat ?? originalInvoice.discount;
    final newNetTotal    = (newSubtotal - newDiscount).clamp(0, double.infinity);
    final additionalDebt = (newNetTotal - oldNetTotal).clamp(0, double.infinity);

    final result = await _repository.editInvoice(
      invoiceId:       invoiceId,
      newItems:        newItems,
      existingUpdates: modifiedItems,
      additionalDebt:  additionalDebt,
      newDiscount:     newDiscountFlat,
      currentItems:    originalInvoice.items,
    );

    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (_) async {
        if (_currentCustomerId != null) {
          await fetchInvoices(_currentCustomerId!);
        }
        await selectInvoice(invoiceId);
      },
    );
  }

  // ── Update status ────────────────────────────────────────────────────────

  Future<void> updateStatus(
      String invoiceId,
      InvoiceStatus status,
      String customerId,
      ) async {
    final result =
    await _repository.updateStatus(invoiceId, status, customerId);
    result.fold(
          (f) => emit(InvoicesError(f.message)),
          (_) => fetchInvoices(customerId),
    );
  }

  /// Exports all invoices for a customer (filtered by date range) to Excel.
  Future<void> exportCustomerReport({
    required String customerId,
    required String customerName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(ExportingReport());

    final result = await _repository.getCustomerInvoicesForExport(
      customerId: customerId,
      startDate: startDate,
      endDate: endDate,
    );

    await result.fold(
          (f) async {
        emit(InvoicesError(f.message));
        // Restore previous list state
        final listResult = await _repository.getCustomerInvoices(customerId);
        listResult.fold(
              (_) {},
              (list) => emit(InvoicesLoaded(invoices: list)),
        );
      },
          (invoices) async {
        try {
          final excel = Excel.createExcel();
          final sheetName = 'تقرير $customerName';
          final Sheet sheet = excel[sheetName];
          excel.setDefaultSheet(sheetName);
          sheet.isRTL = true;

          // ── Column widths ───────────────────────────────────────────────
          sheet.setColumnWidth(0, 18);  // رقم الفاتورة
          sheet.setColumnWidth(1, 16);  // التاريخ
          sheet.setColumnWidth(2, 14);  // الحالة
          sheet.setColumnWidth(3, 14);  // الإجمالي
          sheet.setColumnWidth(4, 14);  // الخصم
          sheet.setColumnWidth(5, 14);  // الصافي
          sheet.setColumnWidth(6, 40);  // الأصناف

          final CellStyle titleStyle = CellStyle(
            bold: true,
            fontSize: 14,
            horizontalAlign: HorizontalAlign.Center,
          );
          final CellStyle headerStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
          final CellStyle dataStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
            textWrapping: TextWrapping.WrapText,
          );
          final CellStyle boldDataStyle = CellStyle(
            bold: true,
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );
          final CellStyle amountStyle = CellStyle(
            horizontalAlign: HorizontalAlign.Center,
            verticalAlign: VerticalAlign.Center,
          );

          int row = 0;

          void writeRow(List<CellValue> values, CellStyle style) {
            sheet.appendRow(values);
            for (int i = 0; i < values.length; i++) {
              sheet
                  .cell(CellIndex.indexByColumnRow(
                  columnIndex: i, rowIndex: row))
                  .cellStyle = style;
            }
            row++;
          }

          final dateStr = startDate.isAtSameMomentAs(endDate)
              ? DateFormat('yyyy-MM-dd').format(startDate)
              : '${DateFormat('yyyy-MM-dd').format(startDate)} → ${DateFormat('yyyy-MM-dd').format(endDate)}';

          // ── Title ────────────────────────────────────────────────────────
          sheet.appendRow([
            TextCellValue('تقرير فواتير العميل: $customerName ($dateStr)')
          ]);
          sheet
              .cell(CellIndex.indexByString('A1'))
              .cellStyle = titleStyle;
          row++;
          sheet.appendRow([TextCellValue('')]);
          row++;

          // ── Column headers ────────────────────────────────────────────────
          writeRow([
            TextCellValue('رقم الفاتورة'),
            TextCellValue('التاريخ'),
            TextCellValue('الحالة'),
            TextCellValue('الإجمالي'),
            TextCellValue('الخصم'),
            TextCellValue('الصافي'),
            TextCellValue('الأصناف'),
          ], headerStyle);

          // ── Invoice rows ──────────────────────────────────────────────────
          double totalGross = 0;
          double totalDiscount = 0;
          double totalNet = 0;

          for (final inv in invoices) {
            // Build items summary string
            final itemsSummary = inv.items.isEmpty
                ? '—'
                : inv.items.map((item) {
              final name = item.itemName ?? item.itemId.substring(0, 8);
              final returned = item.returnedQty > 0
                  ? ' (مرتجع: ${item.returnedQty}/${item.qty})'
                  : '';
              return '$name × ${item.qty} × ${item.days} يوم$returned';
            }).join('\n');

            final statusLabel = switch (inv.status) {
              InvoiceStatus.active => 'نشطة',
              InvoiceStatus.completed => 'مكتملة',
              InvoiceStatus.canceled => 'ملغية',
              InvoiceStatus.draft => 'مسودة',
            };

            writeRow([
              TextCellValue(inv.invoiceNumber),
              TextCellValue(
                  DateFormat('yyyy-MM-dd').format(inv.createdAt)),
              TextCellValue(statusLabel),
              DoubleCellValue(inv.totalAmount),
              DoubleCellValue(inv.discount),
              DoubleCellValue(inv.netTotal),
              TextCellValue(itemsSummary),
            ], dataStyle);

            totalGross += inv.totalAmount;
            totalDiscount += inv.discount;
            totalNet += inv.netTotal;
          }

          // ── Totals row ────────────────────────────────────────────────────
          sheet.appendRow([TextCellValue('')]);
          row++;
          writeRow([
            TextCellValue('الإجماليات'),
            TextCellValue(''),
            TextCellValue('${invoices.length} فاتورة'),
            DoubleCellValue(totalGross),
            DoubleCellValue(totalDiscount),
            DoubleCellValue(totalNet),
            TextCellValue(''),
          ], boldDataStyle);

          // ── Encode and save ───────────────────────────────────────────────
          final bytes = excel.encode();
          if (bytes != null) {
            final fileName =
                'Customer_${customerName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
            await FileSaver.instance.saveFile(
              name: fileName,
              bytes: Uint8List.fromList(bytes),
              ext: 'xlsx',
              mimeType: MimeType.microsoftExcel,
            );
          }

          emit(ReportExported());

          // Restore invoice list
          final listResult =
          await _repository.getCustomerInvoices(customerId);
          listResult.fold(
                (_) {},
                (list) => emit(InvoicesLoaded(invoices: list)),
          );
        } catch (e) {
          emit(InvoicesError('حدث خطأ أثناء التصدير: $e'));
        }
      },
    );
  }
}

