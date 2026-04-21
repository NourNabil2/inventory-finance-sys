// lib/features/customers/presentation/cubit/customers_cubit.dart
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customers_repository.dart';

part 'customers_state.dart';

class CustomersCubit extends Cubit<CustomersState> {
  final CustomersRepository _repository;

  CustomersCubit(this._repository) : super(const CustomersState());

  // ── Fetch ─────────────────────────────────────────────────────────────

  Future<void> fetchCustomers() async {
    emit(state.copyWith(status: CustomersStatus.loading, clearError: true));
    final result = await _repository.getCustomers();

    // 🚨 الحماية هنا: لو الكيوبت اتقفل (المستخدم طلع من الشاشة)، وقف التنفيذ
    if (isClosed) return;

    result.fold(
          (f) => emit(state.copyWith(
        status: CustomersStatus.failure,
        errorMessage: f.message,
      )),
          (list) => emit(state.copyWith(
        status: CustomersStatus.success,
        customers: list,
        filtered: _filter(list, state.searchQuery),
      )),
    );
  }

  // ── Search ────────────────────────────────────────────────────────────

  void search(String query) {
    emit(state.copyWith(
      searchQuery: query,
      filtered: _filter(state.customers, query),
    ));
  }

  // ── Select ────────────────────────────────────────────────────────────

  void selectCustomer(CustomerEntity customer) {
    emit(state.copyWith(
      selectedCustomer: customer,
      isFormOpen: false,
    ));
  }

  void clearSelection() {
    emit(state.copyWith(clearSelected: true, isFormOpen: false));
  }

  // ── Form open/close ───────────────────────────────────────────────────

  void openCreateForm() {
    emit(state.copyWith(
      isFormOpen: true,
      isEditMode: false,
      formStatus: CustomerFormStatus.idle,
      clearSelected: true,
    ));
  }

  void openEditForm(CustomerEntity customer) {
    emit(state.copyWith(
      isFormOpen: true,
      isEditMode: true,
      selectedCustomer: customer,
      formStatus: CustomerFormStatus.idle,
    ));
  }

  void closeForm() {
    emit(state.copyWith(
      isFormOpen: false,
      formStatus: CustomerFormStatus.idle,
    ));
  }

  // ── Save (create or update) ───────────────────────────────────────────

  Future<void> saveCustomer(CustomerEntity customer) async {
    emit(state.copyWith(formStatus: CustomerFormStatus.submitting));
    final result = await _repository.saveCustomer(customer);

    if (isClosed) return; // 🚨 حماية

    result.fold(
          (f) => emit(state.copyWith(
        formStatus: CustomerFormStatus.error,
        errorMessage: f.message,
      )),
          (_) async {
        emit(state.copyWith(
          formStatus: CustomerFormStatus.submitted,
          isFormOpen: false,
        ));
        await fetchCustomers();
      },
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────

  Future<void> deleteCustomer(String id) async {
    emit(state.copyWith(status: CustomersStatus.loading));
    final result = await _repository.deleteCustomer(id);

    if (isClosed) return; // 🚨 حماية

    await result.fold<Future<void>>(
          (f) async {
        String msg = f.message;
        if (msg == 'customer.has_invoices') {
          msg = 'customer.cannot_delete_has_invoices'.tr();
        } else if (msg == 'customer.has_checks') {
          msg = 'customer.cannot_delete_has_checks'.tr();
        }
        emit(state.copyWith(
          status: CustomersStatus.failure,
          errorMessage: msg,
        ));
      },
          (_) async {
        final updated = state.customers.where((c) => c.id != id).toList();
        emit(state.copyWith(
          status: CustomersStatus.success,
          customers: updated,
          filtered: _filter(updated, state.searchQuery),
          clearSelected: true,
          isFormOpen: false,
        ));
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  List<CustomerEntity> _filter(List<CustomerEntity> list, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((c) {
      return c.name.toLowerCase().contains(q) ||
          (c.phone?.toLowerCase().contains(q) ?? false);
    }).toList();
  }


  // ── Export All Customers to Excel ───────────────────────────────────────

  Future<void> exportCustomersToExcel() async {
    final listToExport = state.filtered;
    if (listToExport.isEmpty) return;

    try {
      var excel = Excel.createExcel();
      String sheetName = 'بيانات العملاء';
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
      sheet.setColumnWidth(0, 5);  // م
      sheet.setColumnWidth(1, 30); // اسم العميل
      sheet.setColumnWidth(2, 15); // الهاتف
      sheet.setColumnWidth(3, 15); // تاريخ التسجيل
      sheet.setColumnWidth(4, 15); // إجمالي الفواتير
      sheet.setColumnWidth(5, 15); // المدفوع
      sheet.setColumnWidth(6, 15); // المديونية
      sheet.setColumnWidth(7, 15); // رصيد المحفظة

      // ── العناوين ──
      sheet.appendRow([TextCellValue('تقرير شامل بحسابات العملاء')]);
      sheet.cell(CellIndex.indexByString("A1")).cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.appendRow([TextCellValue('تاريخ التقرير: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}')]);
      sheet.appendRow([TextCellValue('')]);

      List<CellValue> headers = [
        TextCellValue('م'),
        TextCellValue('اسم العميل'),
        TextCellValue('رقم الهاتف'),
        TextCellValue('تاريخ التسجيل'),
        TextCellValue('إجمالي الفواتير'),
        TextCellValue('المدفوع'),
        TextCellValue('المديونية'),
        TextCellValue('المحفظة'),
      ];
      sheet.appendRow(headers);
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = headerStyle;
      }

      // ── متغيرات الإجماليات ──
      double sumInvoiced = 0;
      double sumPaid = 0;
      double sumDebt = 0;
      double sumWallet = 0;

      int currentRow = 4;
      for (int i = 0; i < listToExport.length; i++) {
        final c = listToExport[i];

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(c.name),
          TextCellValue(c.phone ?? '-'),
          TextCellValue(DateFormat('yyyy-MM-dd').format(c.createdAt)),
          DoubleCellValue(c.totalInvoiced),
          DoubleCellValue(c.totalPaid),
          DoubleCellValue(c.totalDebt),
          DoubleCellValue(c.walletBalance),
        ]);

        for (int j = 0; j < 8; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = dataStyle;
        }

        sumInvoiced += c.totalInvoiced;
        sumPaid += c.totalPaid;
        sumDebt += c.totalDebt;
        sumWallet += c.walletBalance;

        currentRow++;
      }

      // ── سطر الإجماليات النهائي ──
      sheet.appendRow([TextCellValue('')]);
      currentRow++;

      sheet.appendRow([
        TextCellValue(''),
        TextCellValue('الإجماليات الكلية للمديونيات بالسوق'),
        TextCellValue(''),
        TextCellValue(''),
        DoubleCellValue(sumInvoiced),
        DoubleCellValue(sumPaid),
        DoubleCellValue(sumDebt),
        DoubleCellValue(sumWallet),
      ]);

      for (int j = 0; j < 8; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = boldDataStyle;
      }

      // ── حفظ وتصدير ──
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName = 'Customers_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

    } catch (e) {
      if (!isClosed) { // 🚨 حماية
        emit(state.copyWith(
          status: CustomersStatus.failure,
          errorMessage: 'حدث خطأ أثناء تصدير الملف: $e',
        ));
      }
    }
  }
}