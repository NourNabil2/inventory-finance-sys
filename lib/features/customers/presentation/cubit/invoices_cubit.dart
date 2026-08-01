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
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_template_entity.dart';
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
          invoices: previousInvoices,
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

  // ── Templates ────────────────────────────────────────────────────────────

  Future<List<InvoiceTemplateEntity>> getInvoiceTemplates() async {
    final result = await _repository.getInvoiceTemplates();
    return result.fold(
      (f) {
        emit(InvoicesError(f.message));
        return [];
      },
      (list) => list,
    );
  }

  Future<void> saveInvoiceTemplate(String name, List<TemplateItemModel> items) async {
    emit(InvoicesLoading());
    final result = await _repository.saveInvoiceTemplate(name: name, items: items);
    result.fold(
      (f) => emit(InvoicesError(f.message)),
      (_) {
        if (_currentInvoices.isNotEmpty) {
          emit(InvoicesLoaded(invoices: _currentInvoices));
        } else {
          emit(InvoicesInitial());
        }
      },
    );
  }

  Future<void> deleteInvoiceTemplate(String id) async {
    final result = await _repository.deleteInvoiceTemplate(id);
    result.fold(
      (f) => emit(InvoicesError(f.message)),
      (_) {}, // do nothing on success, UI will reload
    );
  }

  // ── Details ──────────────────────────────────────────────────────────────

  Future<void> editInvoice({
    required String invoiceId,
    required InvoiceEntity originalInvoice,
    required List<InvoiceItemEntity> newItems,
    required Map<String, Map<String, dynamic>> modifiedItems,
    double? newDiscountFlat,
    List<String>? deletedItemIds,
    String? newStatus,
    String? jobName,
    String? production,
  }) async {
    emit(InvoicesLoading());

    // final oldNetTotal = (originalInvoice.items
    //     .fold(0.0, (s, i) => s + i.lineTotal) -
    //     originalInvoice.discount)
    //     .clamp(0, double.infinity);
    // double newSubtotal = 0;
    // for (final item in originalInvoice.items) {
    //   final mod          = modifiedItems[item.id];
    //   final days         = (mod?['days']         as int?)    ?? item.days;
    //   final qty          = (mod?['qty']          as int?)    ?? item.qty;
    //   final pricePerDay  = (mod?['pricePerDay']  as double?) ?? item.pricePerDay;
    //   final flatDiscount = (mod?['flatDiscount'] as double?) ?? item.itemDiscount;
    //   newSubtotal +=
    //       (days * qty * pricePerDay - flatDiscount).clamp(0, double.infinity);
    // }
    // for (final item in newItems) {
    //   newSubtotal += item.lineTotal;
    // }
    //
    // final newDiscount    = newDiscountFlat ?? originalInvoice.discount;
    // final newNetTotal    = (newSubtotal - newDiscount).clamp(0, double.infinity);
    // final additionalDebt = (newNetTotal - oldNetTotal).clamp(0, double.infinity);

    final result = await _repository.editInvoice(
      invoiceId:       invoiceId,
      newItems:        newItems,
      existingUpdates: modifiedItems,
      newDiscount:     newDiscountFlat,
      currentItems:    originalInvoice.items,
      deletedItemIds:  deletedItemIds,
      jobName: jobName,
      newStatus:       newStatus,
      production: production,
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
          (_) async {
        await selectInvoice(invoiceId);
        fetchInvoices(customerId);
      },
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
        final listResult = await _repository.getCustomerInvoices(customerId);
        listResult.fold((_) {}, (list) => emit(InvoicesLoaded(invoices: list)));
      },
          (invoices) async {
        try {
          // ── تجهيز الإجماليات مسبقاً ──────────────────────────────────────
          double totalGross = 0, totalDiscount = 0, totalNet = 0;
          int activeCount = 0, completedCount = 0, canceledCount = 0;
          for (final inv in invoices) {
            totalGross    += inv.totalAmount;
            totalDiscount += inv.discount;
            totalNet      += inv.netTotal;
            switch (inv.status) {
              case InvoiceStatus.active:    activeCount++;    break;
              case InvoiceStatus.completed: completedCount++; break;
              case InvoiceStatus.canceled:  canceledCount++;  break;
              default: break;
            }
          }

          final dateStr = startDate.isAtSameMomentAs(endDate)
              ? DateFormat('yyyy-MM-dd').format(startDate)
              : '${DateFormat('yyyy-MM-dd').format(startDate)} → ${DateFormat('yyyy-MM-dd').format(endDate)}';

          // ── إنشاء الملف ───────────────────────────────────────────────────
          final excel = Excel.createExcel();
          excel.delete('Sheet1');

          // ══════════════════════════════════════════════════════════════════
          //  SHEET 1 — الملخص
          // ══════════════════════════════════════════════════════════════════
          excel['summary'];
          final Sheet summary = excel.sheets['summary']!;
          summary.isRTL = true;
          _buildInvoiceSummarySheet(
            sheet: summary,
            customerName: customerName,
            dateStr: dateStr,
            invoicesCount: invoices.length,
            activeCount: activeCount,
            completedCount: completedCount,
            canceledCount: canceledCount,
            totalGross: totalGross,
            totalDiscount: totalDiscount,
            totalNet: totalNet,
            invoices: invoices,
          );

          // ══════════════════════════════════════════════════════════════════
          //  SHEET 2 — تفاصيل الفواتير
          // ══════════════════════════════════════════════════════════════════
          excel['details'];
          final Sheet details = excel.sheets['details']!;
          details.isRTL = true;
          _buildInvoiceDetailsSheet(
            sheet: details,
            customerName: customerName,
            dateStr: dateStr,
            invoices: invoices,
            totalGross: totalGross,
            totalDiscount: totalDiscount,
            totalNet: totalNet,
          );

          excel.rename('summary', 'الملخص');
          excel.rename('details', 'الفواتير');
          excel.setDefaultSheet('الملخص');

          // ── حفظ ──────────────────────────────────────────────────────────
          final bytes = excel.encode();
          if (bytes != null) {
            final fileName =
                'تقرير_${customerName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
            await FileSaver.instance.saveFile(
              name: fileName,
              bytes: Uint8List.fromList(bytes),
              ext: 'xlsx',
              mimeType: MimeType.microsoftExcel,
            );
          }

          emit(ReportExported());

          final listResult = await _repository.getCustomerInvoices(customerId);
          listResult.fold((_) {}, (list) => emit(InvoicesLoaded(invoices: list)));
        } catch (e) {
          emit(InvoicesError('حدث خطأ أثناء التصدير: $e'));
        }
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  SHEET 1 — الملخص
  // ══════════════════════════════════════════════════════════════════════════════
  void _buildInvoiceSummarySheet({
    required Sheet sheet,
    required String customerName,
    required String dateStr,
    required int invoicesCount,
    required int activeCount,
    required int completedCount,
    required int canceledCount,
    required double totalGross,
    required double totalDiscount,
    required double totalNet,
    required List<dynamic> invoices,
  }) {
    int row = 0;

    // ── [1] Main title ──────────────────────────────────────────────────────
    _xSet(sheet, row, 0,
      value: TextCellValue(_ar('تقرير فواتير العميل: $customerName')),
      style: _xS(bold: true, fontSize: 16, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_xIdx(row, 0), _xIdx(row, 5));
    row++;

    // ── [2] Period ──────────────────────────────────────────────────────────
    _xSet(sheet, row, 0,
      value: TextCellValue(_ar('الفترة: $dateStr')),
      style: _xS(bold: true, fontSize: 12, bg: '2E86AB', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_xIdx(row, 0), _xIdx(row, 5));
    row++;

    // ── [3] Issue date ──────────────────────────────────────────────────────
    _xSet(sheet, row, 0,
      value: TextCellValue(_ar('تاريخ الإصدار: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')),
      style: _xS(fontSize: 10, bg: 'EBF5FB', fg: '555555',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_xIdx(row, 0), _xIdx(row, 5));
    row += 2;

    // ── [4] KPI cards ───────────────────────────────────────────────────────
    _xSectionHeader(sheet, row, 'المؤشرات الرئيسية', 6);
    row++;

    final kpis = [
      ['إجمالي الفواتير',  invoicesCount.toString(),       'E8F4FD', '1A5276'],
      ['نشطة',             activeCount.toString(),         'EAF7EA', '1E8449'],
      ['مكتملة',           completedCount.toString(),      'E8F8F5', '1A7A5E'],
      ['ملغية',            canceledCount.toString(),       'FDEDEC', 'C0392B'],
      ['إجمالي المبالغ',   '${_xMoney(totalGross)} ج.م',  'EAF7EA', '1E8449'],
      ['صافي بعد الخصم',  '${_xMoney(totalNet)} ج.م',    '1E3A5F', 'FFFFFF'],
    ];

    for (int col = 0; col < kpis.length; col++) {
      _xSet(sheet, row, col,
        value: TextCellValue(_ar(kpis[col][0])),
        style: _xS(bold: true, fontSize: 10, bg: kpis[col][2], fg: kpis[col][3],
            align: HorizontalAlign.Center),
      );
    }
    row++;

    for (int col = 0; col < kpis.length; col++) {
      _xSet(sheet, row, col,
        value: TextCellValue(_ar(kpis[col][1])),
        style: _xS(bold: true, fontSize: 13, bg: kpis[col][2], fg: kpis[col][3],
            align: HorizontalAlign.Center),
      );
    }
    row += 2;

    // ── [5] Financial summary table ─────────────────────────────────────────
    _xSectionHeader(sheet, row, 'الملخص المالي', 3);
    row++;

    final finHeaders = ['البيان', 'المبلغ', 'النسبة'];
    for (int col = 0; col < finHeaders.length; col++) {
      _xSet(sheet, row, col,
        value: TextCellValue(_ar(finHeaders[col])),
        style: _xHeaderStyle(),
      );
    }
    row++;

    final discountPct = totalGross > 0
        ? '${(totalDiscount / totalGross * 100).toStringAsFixed(1)}%'
        : '0%';

    final finRows = [
      ['إجمالي قبل الخصم', '${_xMoney(totalGross)} ج.م',    '—',           'FFFFFF'],
      ['إجمالي الخصومات',  '${_xMoney(totalDiscount)} ج.م', discountPct,   'FEF9E7'],
      ['الصافي المستحق',   '${_xMoney(totalNet)} ج.م',      '—',           'EAF7EA'],
    ];

    for (final fr in finRows) {
      for (int col = 0; col < 3; col++) {
        _xSet(sheet, row, col,
          value: TextCellValue(_ar(fr[col])),
          style: _xS(
            fontSize: 11,
            bold: fr[3] == 'EAF7EA',
            bg: fr[3],
            align: col == 0 ? HorizontalAlign.Right : HorizontalAlign.Center,
          ),
        );
      }
      row++;
    }
    row++;

    // ── [6] Top 5 highest invoices ──────────────────────────────────────────
    _xSectionHeader(sheet, row, 'أعلى 5 فواتير قيمةً', 4);
    row++;

    final topHeaders = ['رقم الفاتورة', 'التاريخ', 'اسم العمل', 'الصافي'];
    for (int col = 0; col < topHeaders.length; col++) {
      _xSet(sheet, row, col,
        value: TextCellValue(_ar(topHeaders[col])),
        style: _xHeaderStyle(),
      );
    }
    row++;

    final sortedInv = [...invoices]
      ..sort((a, b) => (b.netTotal as double).compareTo(a.netTotal as double));

    int rank = 1;
    for (final inv in sortedInv.take(5)) {
      final isTop = rank == 1;
      final rowData = [
        inv.invoiceNumber.toString(),
        DateFormat('yyyy-MM-dd').format(inv.createdAt),
        inv.jobName ?? '-',
        '${_xMoney(inv.netTotal)} ج.م',
      ];
      for (int col = 0; col < rowData.length; col++) {
        _xSet(sheet, row, col,
          value: TextCellValue(_ar(rowData[col])),
          style: _xS(
            fontSize: 10,
            bold: isTop,
            bg: isTop ? 'D5F5E3' : (row % 2 == 0 ? 'F8F9FA' : 'FFFFFF'),
            fg: isTop ? '1E8449' : '000000',
            align: col == 3 ? HorizontalAlign.Center : HorizontalAlign.Right,
          ),
        );
      }
      rank++;
      row++;
    }

    // Column widths
    for (int i = 0; i < 6; i++) {
      sheet.setColumnWidth(i, i == 0 ? 26 : 18);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  SHEET 2 — تفاصيل الفواتير
  // ══════════════════════════════════════════════════════════════════════════════
  void _buildInvoiceDetailsSheet({
    required Sheet sheet,
    required String customerName,
    required String dateStr,
    required List<dynamic> invoices,
    required double totalGross,
    required double totalDiscount,
    required double totalNet,
  }) {
    int row = 0;

    // ── [1] Title ───────────────────────────────────────────────────────────
    _xSet(sheet, row, 0,
      value: TextCellValue(_ar('فواتير العميل: $customerName — $dateStr')),
      style: _xS(bold: true, fontSize: 14, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_xIdx(row, 0), _xIdx(row, 8));
    row += 2;

    // ── [2] Headers ─────────────────────────────────────────────────────────
    const headers = [
      'رقم الفاتورة', 'التاريخ', 'اسم العمل', 'جهة الإنتاج',
      'الحالة', 'الإجمالي', 'الخصم', 'الصافي', 'الأصناف',
    ];
    for (int col = 0; col < headers.length; col++) {
      _xSet(sheet, row, col,
        value: TextCellValue(_ar(headers[col])),
        style: _xHeaderStyle(),
      );
    }
    row++;

    // ── [3] Rows ─────────────────────────────────────────────────────────────
    for (int i = 0; i < invoices.length; i++) {
      final inv = invoices[i];

      final itemsSummary = inv.items.isEmpty
          ? '—'
          : inv.items.map((item) {
        final name = item.itemName ?? item.itemId.substring(0, 8);
        final returned = item.returnedQty > 0
            ? ' (مرتجع: ${item.returnedQty}/${item.qty})'
            : '';
        return '$name × ${item.qty} × ${item.days} يوم$returned';
      }).join('\n');

      final (statusLabel, statusBg, statusFg) = switch (inv.status) {
        InvoiceStatus.active    => ('نشطة',    'EAF7EA', '1E8449'),
        InvoiceStatus.completed => ('مكتملة',  'E8F8F5', '1A7A5E'),
        InvoiceStatus.canceled  => ('ملغية',   'FDEDEC', 'C0392B'),
        InvoiceStatus.draft     => ('مسودة',   'F4F6F7', '7F8C8D'),
        _                       => ('-',        'FFFFFF', '000000'),
      };

      final baseBg = i % 2 == 0 ? 'F8F9FA' : 'FFFFFF';

      final rowValues = [
        inv.invoiceNumber.toString(),
        DateFormat('yyyy-MM-dd').format(inv.createdAt),
        inv.jobName ?? '-',
        inv.production ?? '-',
        statusLabel,
        '${_xMoney(inv.totalAmount)} ج.م',
        inv.discount > 0 ? '${_xMoney(inv.discount)} ج.م' : '—',
        '${_xMoney(inv.netTotal)} ج.م',
        itemsSummary,
      ];

      for (int col = 0; col < rowValues.length; col++) {
        // عمود الحالة — لونه حسب الحالة
        final (bg, fg, bold) = col == 4
            ? (statusBg, statusFg, true)
            : (baseBg, '000000', false);

        _xSet(sheet, row, col,
          value: TextCellValue(_ar(rowValues[col])),
          style: _xS(
            fontSize: 10,
            bg: bg,
            fg: fg,
            bold: bold,
            align: col == 8 ? HorizontalAlign.Right : HorizontalAlign.Center,
            wrap: col == 8,
          ),
        );
      }
      row++;
    }

    // ── [4] Totals ───────────────────────────────────────────────────────────
    row++;
    final totals = [
      _ar('الإجماليات'), '', _ar('${invoices.length} فاتورة'), '',
      '', _ar('${_xMoney(totalGross)} ج.م'),
      _ar('${_xMoney(totalDiscount)} ج.م'),
      _ar('${_xMoney(totalNet)} ج.م'), '',
    ];
    for (int col = 0; col < totals.length; col++) {
      _xSet(sheet, row, col,
        value: TextCellValue(totals[col]),
        style: _xS(bold: true, fontSize: 11, bg: '1E3A5F', fg: 'FFFFFF',
            align: HorizontalAlign.Center),
      );
    }

    // Column widths
    sheet.setColumnWidth(0, 18);
    sheet.setColumnWidth(1, 14);
    sheet.setColumnWidth(2, 22);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 12);
    sheet.setColumnWidth(5, 16);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 16);
    sheet.setColumnWidth(8, 42);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  HELPERS  (prefix _x لتجنب conflict مع helpers المشروع التاني)
  // ══════════════════════════════════════════════════════════════════════════════

  static String _ar(String text) => '\u202B$text';

  static String _xMoney(double v) =>
      NumberFormat('#,##0.00', 'ar').format(v);

  static CellIndex _xIdx(int row, int col) =>
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

  static void _xSet(Sheet sheet, int row, int col,
      {required CellValue value, required CellStyle style}) {
    final cell = sheet.cell(_xIdx(row, col));
    cell.value = value;
    cell.cellStyle = style;
  }

  static CellStyle _xS({
    bool bold = false,
    int fontSize = 10,
    String bg = 'FFFFFF',
    String fg = '000000',
    HorizontalAlign align = HorizontalAlign.Right,
    bool wrap = false,
  }) =>
      CellStyle(
        bold: bold,
        fontSize: fontSize,
        fontFamily: getFontFamily(FontFamily.Arial),
        backgroundColorHex: ExcelColor.fromHexString('#$bg'),
        fontColorHex: ExcelColor.fromHexString('#$fg'),
        horizontalAlign: align,
        verticalAlign: VerticalAlign.Center,
        textWrapping: wrap ? TextWrapping.WrapText : TextWrapping.Clip,
      );

  static CellStyle _xHeaderStyle() => _xS(
    bold: true, fontSize: 11,
    bg: '2E86AB', fg: 'FFFFFF',
    align: HorizontalAlign.Center,
  );

  static void _xSectionHeader(
      Sheet sheet, int row, String title, int colSpan) {
    _xSet(sheet, row, 0,
      value: TextCellValue(_ar(title)),
      style: _xS(bold: true, fontSize: 12, bg: 'D6EAF8', fg: '1A5276',
          align: HorizontalAlign.Right),
    );
    if (colSpan > 1) {
      sheet.merge(_xIdx(row, 0), _xIdx(row, colSpan - 1));
    }
  }
}

