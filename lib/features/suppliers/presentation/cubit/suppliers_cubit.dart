// lib/features/suppliers/presentation/cubit/suppliers_cubit.dart

import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/clearing_result.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

part 'suppliers_state.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  final SuppliersRepository _repository;

  SuppliersCubit(this._repository) : super(const SuppliersState());

  // ── Fetch list ────────────────────────────────────────────

  Future<void> fetchSuppliers() async {
    emit(state.copyWith(status: SuppliersStatus.loading, clearError: true));
    final result = await _repository.getSuppliers();
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (list) => emit(state.copyWith(
        status: SuppliersStatus.success,
        suppliers: list,
        filtered: _filter(list, state.searchQuery),
      )),
    );
  }

  void search(String query) {
    emit(state.copyWith(
      searchQuery: query,
      filtered: _filter(state.suppliers, query),
    ));
  }

  Future<void> selectSupplier(SupplierEntity supplier) async {
    emit(state.copyWith(
      selectedSupplier: supplier,
      clearInvoices: true,
      clearServiceInvoices: true,
      clearSelectedInvoice: true,
      clearSelectedServiceInvoice: true,
      activeTab: SupplierLedgerTab.purchases,
    ));
    await Future.wait([
      fetchSupplierInvoices(supplier.id),
      fetchSupplierServiceInvoices(supplier.id),
    ]);
  }

  void clearSelection() {
    emit(state.copyWith(
      clearSelectedSupplier: true,
      clearSelectedInvoice: true,
      clearSelectedServiceInvoice: true,
      clearInvoices: true,
      clearServiceInvoices: true,
    ));
  }

  void switchTab(SupplierLedgerTab tab) => emit(state.copyWith(activeTab: tab));

  // ── Purchase invoices ─────────────────────────────────────

  Future<void> fetchSupplierInvoices(String supplierId) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.getSupplierInvoices(supplierId);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (list) => emit(state.copyWith(status: SuppliersStatus.success, invoices: list)),
    );
  }

  Future<void> selectInvoice(String invoiceId) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.getInvoiceDetails(invoiceId);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (invoice) => emit(state.copyWith(status: SuppliersStatus.success, selectedInvoice: invoice)),
    );
  }

  void clearSelectedInvoice() => emit(state.copyWith(clearSelectedInvoice: true));

  // ── Supplier CRUD ─────────────────────────────────────────

  Future<void> saveSupplier(SupplierEntity supplier) async {
    emit(state.copyWith(formStatus: SupplierFormStatus.submitting));
    final result = await _repository.saveSupplier(supplier);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(formStatus: SupplierFormStatus.error, errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(formStatus: SupplierFormStatus.submitted));
        await fetchSuppliers();
      },
    );
  }

  Future<void> createInvoice({
    required String supplierId,
    required List<SupplierInvoiceItemEntity> items,
    double discount = 0,
    String? notes,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.createSupplierInvoice(
        supplierId: supplierId, items: items, discount: discount, notes: notes);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (_) async {
        await fetchSupplierInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  Future<void> recordPayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.recordPayment(
        invoiceId: invoiceId, amount: amount, method: method);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (_) async {
        await selectInvoice(invoiceId);
        await fetchSupplierInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  // ── 🆕 إلغاء فاتورة المورد ──────────────────────────────────────

  Future<void> cancelInvoice({
    required String invoiceId,
    required String supplierId,
    String? reason,
  }) async {
    emit(state.copyWith(invoiceCancelStatus: InvoiceCancelStatus.loading, clearError: true));
    final result = await _repository.cancelSupplierInvoice(
      invoiceId: invoiceId,
      reason: reason,
    );
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(invoiceCancelStatus: InvoiceCancelStatus.failure, errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(invoiceCancelStatus: InvoiceCancelStatus.success));
        await fetchSupplierInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  // ── 🆕 تعديل فاتورة المورد (شامل البنود) ──────────────────────────────────────

  Future<void> editInvoice({
    required String invoiceId,
    required String supplierId,
    required double discount,
    String? notes,
    required List<String> deletedItemIds,
    required List<Map<String, dynamic>> existingUpdates,
    required List<Map<String, dynamic>> newItems,
  }) async {
    emit(state.copyWith(invoiceEditStatus: InvoiceEditStatus.loading, clearError: true));

    final result = await _repository.editSupplierInvoice(
      invoiceId: invoiceId,
      discount: discount,
      notes: notes,
      deletedItemIds: deletedItemIds,
      existingUpdates: existingUpdates,
      newItems: newItems,
    );

    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(invoiceEditStatus: InvoiceEditStatus.failure, errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(invoiceEditStatus: InvoiceEditStatus.success));
        await fetchSupplierInvoices(supplierId);
        await fetchSuppliers(); // تحديث الأرصدة
      },
    );
  }

  // ── Service invoices ──────────────────────────────────────

  Future<void> fetchSupplierServiceInvoices(String supplierId) async {
    emit(state.copyWith(serviceInvoicesStatus: ServiceInvoicesStatus.loading));
    final result = await _repository.getSupplierServiceInvoices(supplierId);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(
          serviceInvoicesStatus: ServiceInvoicesStatus.failure,
          errorMessage: f.message)),
          (list) => emit(state.copyWith(
          serviceInvoicesStatus: ServiceInvoicesStatus.success,
          serviceInvoices: list)),
    );
  }

  Future<void> createFullServiceInvoiceForSupplier({
    required String supplierId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading, clearError: true));
    final result = await _repository.createFullServiceInvoiceForSupplier(
        supplierId: supplierId, invoiceData: invoiceData, itemsData: itemsData);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(status: SuppliersStatus.success));
        await fetchSupplierServiceInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  Future<void> createServiceInvoiceForSupplier({
    required String supplierId,
    required double totalAmount,
    String? notes,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.createServiceInvoiceForSupplier(
        supplierId: supplierId, totalAmount: totalAmount, notes: notes);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (_) async {
        await fetchSupplierServiceInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  void selectServiceInvoice(ServiceInvoiceEntity invoice) =>
      emit(state.copyWith(selectedServiceInvoice: invoice));

  void clearSelectedServiceInvoice() =>
      emit(state.copyWith(clearSelectedServiceInvoice: true));

  Future<void> recordServicePayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  }) async {
    emit(state.copyWith(status: SuppliersStatus.loading));
    final result = await _repository.recordServicePayment(
        invoiceId: invoiceId, supplierId: supplierId, amount: amount, method: method);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: f.message)),
          (_) async {
        await fetchSupplierServiceInvoices(supplierId);
        await fetchSuppliers();
      },
    );
  }

  // ── 🆕 إلغاء فاتورة خدمات ─────────────────────────────────────────────────

  Future<void> cancelServiceInvoice({
    required String invoiceId,
    required String supplierId,
    String? reason,
  }) async {
    emit(state.copyWith(
        serviceInvoiceCancelStatus: ServiceInvoiceCancelStatus.loading,
        clearError: true));
    final result = await _repository.cancelServiceInvoice(
        invoiceId: invoiceId, supplierId: supplierId, reason: reason);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(
          serviceInvoiceCancelStatus: ServiceInvoiceCancelStatus.failure,
          errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(
            serviceInvoiceCancelStatus: ServiceInvoiceCancelStatus.success));
        await fetchSupplierServiceInvoices(supplierId);
        await fetchSuppliers();
        await Future.delayed(const Duration(milliseconds: 400));
        if (!isClosed) {
          emit(state.copyWith(
              serviceInvoiceCancelStatus: ServiceInvoiceCancelStatus.idle));
        }
      },
    );
  }

  // ── 🆕 تعديل فاتورة خدمات ─────────────────────────────────────────────────

  Future<void> editServiceInvoice({
    required String invoiceId,
    required String supplierId,
    required double discount,
    String? notes,
    required List<String> deletedItemIds,
    required List<Map<String, dynamic>> existingUpdates,
    required List<Map<String, dynamic>> newItems,
  }) async {
    emit(state.copyWith(
        serviceInvoiceEditStatus: ServiceInvoiceEditStatus.loading,
        clearError: true));
    final result = await _repository.editServiceInvoice(
      invoiceId:       invoiceId,
      supplierId:      supplierId,
      discount:        discount,
      notes:           notes,
      deletedItemIds:  deletedItemIds,
      existingUpdates: existingUpdates,
      newItems:        newItems,
    );
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(
          serviceInvoiceEditStatus: ServiceInvoiceEditStatus.failure,
          errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(
            serviceInvoiceEditStatus: ServiceInvoiceEditStatus.success));
        await fetchSupplierServiceInvoices(supplierId);
        await fetchSuppliers();
        await Future.delayed(const Duration(milliseconds: 400));
        if (!isClosed) {
          emit(state.copyWith(
              serviceInvoiceEditStatus: ServiceInvoiceEditStatus.idle));
        }
      },
    );
  }

  // ── Clearing ──────────────────────────────────────────────

  Future<void> executeSupplierClearing({
    required String supplierId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    emit(state.copyWith(clearingStatus: ClearingStatus.loading, clearClearingResult: true, clearError: true));
    final result = await _repository.executeSupplierClearing(
        supplierId: supplierId, amount: amount, notes: notes, createdBy: createdBy);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(clearingStatus: ClearingStatus.failure, errorMessage: f.message)),
          (cr) async {
        emit(state.copyWith(clearingStatus: ClearingStatus.success, lastClearingResult: cr));
        await fetchSuppliers();
        if (state.selectedSupplier?.id == supplierId) {
          final fresh = state.suppliers.firstWhere(
                  (s) => s.id == supplierId, orElse: () => state.selectedSupplier!);
          if (!isClosed) emit(state.copyWith(selectedSupplier: fresh));
        }
      },
    );
  }

  void resetClearingStatus() =>
      emit(state.copyWith(clearingStatus: ClearingStatus.idle, clearClearingResult: true));

  Future<void> linkCustomerToSupplier({
    required String supplierId,
    required String? customerId,
  }) async {
    emit(state.copyWith(linkCustomerStatus: LinkCustomerStatus.loading, clearError: true));
    final result = await _repository.updateLinkedCustomer(supplierId: supplierId, customerId: customerId);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(linkCustomerStatus: LinkCustomerStatus.failure, errorMessage: f.message)),
          (_) async {
        emit(state.copyWith(linkCustomerStatus: LinkCustomerStatus.success));
        await fetchSuppliers();
        // Update selected supplier locally if possible
        if (state.selectedSupplier?.id == supplierId) {
          final fresh = state.suppliers.firstWhere(
                (s) => s.id == supplierId,
            orElse: () => state.selectedSupplier!,
          );
          if (!isClosed) emit(state.copyWith(selectedSupplier: fresh));
        }
        await Future.delayed(const Duration(milliseconds: 500));
        if (!isClosed) emit(state.copyWith(linkCustomerStatus: LinkCustomerStatus.idle));
      },
    );
  }

  Future<void> executeClearing({
    required String supplierId,
    required String customerId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    emit(state.copyWith(clearingStatus: ClearingStatus.loading, clearClearingResult: true, clearError: true));
    final result = await _repository.executeClearing(
        supplierId: supplierId, customerId: customerId,
        amount: amount, notes: notes, createdBy: createdBy);
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(clearingStatus: ClearingStatus.failure, errorMessage: f.message)),
          (cr) async {
        emit(state.copyWith(clearingStatus: ClearingStatus.success, lastClearingResult: cr));
        await fetchSuppliers();
      },
    );
  }

  Future<void> executeFlexibleClearing({
    required String supplierId,
    required String clearingType,
    double offsetAmount = 0,
    double cashAmount   = 0,
    String cashMethod   = 'safe',
    String? notes,
    String? createdBy,
  }) async {
    emit(state.copyWith(clearingStatus: ClearingStatus.loading, clearClearingResult: true, clearError: true));
    final result = await _repository.executeFlexibleClearing(
      supplierId: supplierId, clearingType: clearingType,
      offsetAmount: offsetAmount, cashAmount: cashAmount,
      cashMethod: cashMethod, notes: notes, createdBy: createdBy,
    );
    if (isClosed) return;
    result.fold(
          (f) => emit(state.copyWith(clearingStatus: ClearingStatus.failure, errorMessage: f.message)),
          (cr) async {
        emit(state.copyWith(clearingStatus: ClearingStatus.success, lastClearingResult: cr));
        await fetchSuppliers();
        if (state.selectedSupplier?.id == supplierId) {
          final fresh = state.suppliers.firstWhere(
                  (s) => s.id == supplierId, orElse: () => state.selectedSupplier!);
          if (!isClosed) emit(state.copyWith(selectedSupplier: fresh));
        }
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────

  List<SupplierEntity> _filter(List<SupplierEntity> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((s) => s.name.toLowerCase().contains(q)).toList();
  }

  // ── Export ────────────────────────────────────────────────

  Future<bool> exportSuppliersToExcel() async {
    final listToExport = state.filtered;
    if (listToExport.isEmpty) return false;
    try {
      var excel = Excel.createExcel();
      const String sheetName = 'بيانات الموردين';
      Sheet sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);
      sheet.isRTL = true;

      final headerStyle   = CellStyle(bold: true,  horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
      final dataStyle     = CellStyle(bold: false, horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
      final boldDataStyle = CellStyle(bold: true,  horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);

      sheet.setColumnWidth(0, 5);
      sheet.setColumnWidth(1, 30);
      sheet.setColumnWidth(2, 15);
      sheet.setColumnWidth(3, 15);
      sheet.setColumnWidth(4, 22);
      sheet.setColumnWidth(5, 22);
      sheet.setColumnWidth(6, 20);

      sheet.appendRow([TextCellValue('تقرير شامل بحسابات الموردين')]);
      sheet.cell(CellIndex.indexByString('A1')).cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.appendRow([TextCellValue('تاريخ التقرير: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}')]);
      sheet.appendRow([TextCellValue('')]);

      final headers = <CellValue>[
        TextCellValue('م'), TextCellValue('اسم المورد'), TextCellValue('رقم الهاتف'),
        TextCellValue('تاريخ التسجيل'), TextCellValue('مديونية له (نحن ندفع)'),
        TextCellValue('مديونية عليه (يدفع لنا)'), TextCellValue('صافي المركز'),
      ];
      sheet.appendRow(headers);
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = headerStyle;
      }

      double sumBalance = 0, sumDebt = 0;
      int currentRow = 4;
      for (int i = 0; i < listToExport.length; i++) {
        final s = listToExport[i];
        sheet.appendRow([
          IntCellValue(i + 1), TextCellValue(s.name), TextCellValue(s.phone ?? '-'),
          TextCellValue(DateFormat('yyyy-MM-dd').format(s.createdAt)),
          DoubleCellValue(s.balance), DoubleCellValue(s.serviceDebt), DoubleCellValue(s.netPosition),
        ]);
        for (int j = 0; j < 7; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = dataStyle;
        }
        sumBalance += s.balance;
        sumDebt    += s.serviceDebt;
        currentRow++;
      }

      sheet.appendRow([TextCellValue('')]);
      currentRow++;
      sheet.appendRow([
        TextCellValue(''), TextCellValue('الإجماليات'), TextCellValue(''), TextCellValue(''),
        DoubleCellValue(sumBalance), DoubleCellValue(sumDebt), DoubleCellValue(sumBalance - sumDebt),
      ]);
      for (int j = 0; j < 7; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = boldDataStyle;
      }

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName = 'Suppliers_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveFile(
          name: fileName, bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx', mimeType: MimeType.microsoftExcel,
        );
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(status: SuppliersStatus.failure, errorMessage: 'حدث خطأ أثناء تصدير الملف: $e'));
      }
      return false;
    }
  }
}