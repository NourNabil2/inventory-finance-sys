// lib/features/suppliers/presentation/cubit/suppliers_cubit.dart

import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:uuid/uuid.dart';

part 'suppliers_state.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  final SuppliersRepository _repository;

  SuppliersCubit(this._repository) : super(const SuppliersState());

  // ── Fetch list ────────────────────────────────────────────────────────

  Future<void> fetchSuppliers() async {
    emit(state.copyWith(status: SuppliersStatus.loading, clearError: true));
    final result = await _repository.getSuppliers();
    result.fold(
          (f) => emit(state.copyWith(
        status: SuppliersStatus.failure,
        errorMessage: f.message,
      )),
          (list) => emit(state.copyWith(
        status:    SuppliersStatus.success,
        suppliers: list,
        filtered:  _filter(list, state.searchQuery),
      )),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────

  void search(String query) {
    emit(state.copyWith(
      searchQuery: query,
      filtered:    _filter(state.suppliers, query),
    ));
  }

  // ── Select supplier ───────────────────────────────────────────────────

  Future<void> selectSupplier(SupplierEntity supplier) async {
    emit(state.copyWith(
      selectedSupplier:     supplier,
      clearInvoices:        true,
      clearSelectedInvoice: true,
    ));
    await fetchSupplierInvoices(supplier.id);
  }

  void clearSelection() {
    emit(state.copyWith(
      clearSelectedSupplier: true,
      clearSelectedInvoice:  true,
      clearInvoices:         true,
    ));
  }

  // ── Fetch invoices for selected supplier ──────────────────────────────

  Future<void> fetchSupplierInvoices(String supplierId) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.getSupplierInvoices(supplierId);
    result.fold(
          (f) => emit(state.copyWith(
        status:       SuppliersStatus.failure,
        errorMessage: f.message,
      )),
          (list) => emit(state.copyWith(
        status:   SuppliersStatus.success,
        invoices: list,
      )),
    );
  }

  // ── Select invoice ────────────────────────────────────────────────────

  Future<void> selectInvoice(String invoiceId) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.getInvoiceDetails(invoiceId);
    result.fold(
          (f) => emit(state.copyWith(
        status:       SuppliersStatus.failure,
        errorMessage: f.message,
      )),
          (invoice) => emit(state.copyWith(
        status:          SuppliersStatus.success,
        selectedInvoice: invoice,
      )),
    );
  }

  void clearSelectedInvoice() {
    emit(state.copyWith(clearSelectedInvoice: true));
  }

  // ── Save supplier (create / update) ──────────────────────────────────

  Future<void> saveSupplier(SupplierEntity supplier) async {
    emit(state.copyWith(formStatus: SupplierFormStatus.submitting));
    final result = await _repository.saveSupplier(supplier);
    result.fold(
          (f) => emit(state.copyWith(
        formStatus:   SupplierFormStatus.error,
        errorMessage: f.message,
      )),
          (_) async {
        emit(state.copyWith(formStatus: SupplierFormStatus.submitted));
        await fetchSuppliers();
      },
    );
  }

  // ── Create supplier invoice ───────────────────────────────────────────

  Future<void> createInvoice({
    required String supplierId,
    required List<SupplierInvoiceItemEntity> items,
    String? notes,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.createSupplierInvoice(
      supplierId: supplierId,
      items:      items,
      notes:      notes,
    );
    result.fold(
          (f) => emit(state.copyWith(
        status:       SuppliersStatus.failure,
        errorMessage: f.message,
      )),
          (_) async {
        await fetchSupplierInvoices(supplierId);
        // Refresh supplier list so balance updates
        await fetchSuppliers();
      },
    );
  }

  // ── Record payment ────────────────────────────────────────────────────

  Future<void> recordPayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.recordPayment(
      invoiceId: invoiceId,
      amount:    amount,
      method:    method,
    );
    result.fold(
          (f) => emit(state.copyWith(
        status:       SuppliersStatus.failure,
        errorMessage: f.message,
      )),
          (_) async {
        // Refresh invoice detail + list + supplier balances
        await selectInvoice(invoiceId);
        await fetchSupplierInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  List<SupplierEntity> _filter(List<SupplierEntity> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  // ── Export All Suppliers to Excel ───────────────────────────────────────

  Future<bool> exportSuppliersToExcel() async {
    final listToExport = state.filtered;
    if (listToExport.isEmpty) return false;

    try {
      var excel = Excel.createExcel();
      String sheetName = 'بيانات الموردين';
      Sheet sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);
      sheet.isRTL = true;

      // ── تنسيقات الخلايا ──
      CellStyle headerStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      CellStyle dataStyle = CellStyle(
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );
      CellStyle boldDataStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // ── عرض الأعمدة ──
      sheet.setColumnWidth(0, 5);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 15);
      sheet.setColumnWidth(3, 15);
      sheet.setColumnWidth(4, 20);

      // ── العناوين ──
      sheet.appendRow([TextCellValue('تقرير شامل بحسابات الموردين')]);
      sheet.cell(CellIndex.indexByString("A1")).cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.appendRow([TextCellValue('تاريخ التقرير: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}')]);
      sheet.appendRow([TextCellValue('')]);

      List<CellValue> headers = [
        TextCellValue('م'),
        TextCellValue('اسم المورد'),
        TextCellValue('رقم الهاتف'),
        TextCellValue('تاريخ التسجيل'),
        TextCellValue('المديونية المستحقة (علينا)'),
      ];
      sheet.appendRow(headers);
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = headerStyle;
      }

      // ── متغيرات الإجماليات ──
      double sumDebt = 0;

      int currentRow = 4;
      for (int i = 0; i < listToExport.length; i++) {
        final s = listToExport[i];

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(s.name),
          TextCellValue(s.phone ?? '-'),
          TextCellValue(DateFormat('yyyy-MM-dd').format(s.createdAt)),
          DoubleCellValue(s.balance),
        ]);

        for (int j = 0; j < 5; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = dataStyle;
        }

        sumDebt += s.balance;
        currentRow++;
      }

      // ── سطر الإجماليات النهائي ──
      sheet.appendRow([TextCellValue('')]);
      currentRow++;

      sheet.appendRow([
        TextCellValue(''),
        TextCellValue('إجمالي المديونيات المستحقة للموردين'),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(sumDebt),
      ]);

      for (int j = 0; j < 5; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = boldDataStyle;
      }

      // ── حفظ وتصدير ──
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName = 'Suppliers_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

      // 🚨 نرجع True لو كل حاجة تمام 🚨
      return true;

    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: SuppliersStatus.failure,
          errorMessage: 'حدث خطأ أثناء تصدير الملف: $e',
        ));
      }
      // 🚨 نرجع False لو حصل إيرور 🚨
      return false;
    }
  }
}