// lib/features/inventory/presentation/cubit/inventory_cubit.dart

import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

part 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  final InventoryRepository _repository;

  String _currentQuery    = '';
  ItemStatus? _currentStatus;
  String? _currentCategoryId;   // ← جديد

  InventoryCubit(this._repository) : super(InventoryInitial());

  Future<void> fetchItems() async {
    emit(InventoryLoading());

    // جيب الـ items والـ categories مع بعض
    final itemsResult      = await _repository.getItems();
    final categoriesResult = await _repository.getCategories();

    itemsResult.fold(
          (f) => emit(InventoryError(f.message)),
          (items) {
        final categories = categoriesResult.fold((_) => <ItemCategoryEntity>[], (c) => c);
        emit(InventoryLoaded(
          items:      items,
          filtered:   items,
          categories: categories,
        ));
      },
    );
  }

  Future<void> deleteItem(String id) async {
    final result = await _repository.deleteItem(id);
    result.fold(
          (f) => emit(InventoryError(f.message)),
          (_) {
        final s = state;
        if (s is InventoryLoaded) {
          final updated = s.items.where((i) => i.id != id).toList();
          emit(InventoryLoaded(
            items:      updated,
            filtered:   _applyFilter(updated),
            categories: s.categories,
          ));
        }
      },
    );
  }

  void search(String query) {
    _currentQuery = query;
    _applyAndEmit();
  }

  void filterByStatus(ItemStatus? status) {
    _currentStatus = status;
    _applyAndEmit();
  }

  void filterByCategory(String? categoryId) {    // ← جديد
    _currentCategoryId = categoryId;
    _applyAndEmit();
  }

  void clearFilters() {
    _currentQuery      = '';
    _currentStatus     = null;
    _currentCategoryId = null;
    _applyAndEmit();
  }

  void _applyAndEmit() {
    final s = state;
    if (s is! InventoryLoaded) return;
    emit(InventoryLoaded(
      items:      s.items,
      filtered:   _applyFilter(s.items),
      categories: s.categories,
    ));
  }

  List<ItemEntity> _applyFilter(List<ItemEntity> items) {
    return items.where((item) {
      final matchesQuery = _currentQuery.isEmpty ||
          item.name.toLowerCase().contains(_currentQuery.toLowerCase()) ||
          (item.model?.toLowerCase().contains(_currentQuery.toLowerCase()) ?? false);

      final matchesStatus = _currentStatus == null || item.status == _currentStatus;

      final matchesCategory = _currentCategoryId == null ||
          item.categoryId == _currentCategoryId;

      return matchesQuery && matchesStatus && matchesCategory;
    }).toList();
  }

  // ── Export Inventory to Excel ─────────────────────────────────────────

  Future<bool> exportInventoryToExcel() async {
    final s = state;
    if (s is! InventoryLoaded) return false;

    final listToExport = s.filtered;
    if (listToExport.isEmpty) return false;

    try {
      var excel = Excel.createExcel();
      String sheetName = 'جرد المخزن';
      Sheet sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);
      sheet.isRTL = true;

      // ── تنسيقات الخلايا ──
      CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
      CellStyle dataStyle = CellStyle(horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
      CellStyle boldDataStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);

      // ── عرض الأعمدة ──
      sheet.setColumnWidth(0, 5);  // م
      sheet.setColumnWidth(1, 30); // اسم الصنف
      sheet.setColumnWidth(2, 20); // الموديل
      sheet.setColumnWidth(3, 20); // الفئة
      sheet.setColumnWidth(4, 15); // السعر
      sheet.setColumnWidth(5, 15); // المتوفر
      sheet.setColumnWidth(6, 15); // الإجمالي
      sheet.setColumnWidth(7, 15); // الحالة

      // ── العناوين ──
      sheet.appendRow([TextCellValue('تقرير شامل بجرد المخزن')]);
      sheet.cell(CellIndex.indexByString("A1")).cellStyle = CellStyle(bold: true, fontSize: 14);
      sheet.appendRow([TextCellValue('تاريخ التقرير: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')]);
      sheet.appendRow([TextCellValue('')]);

      List<CellValue> headers = [
        TextCellValue('م'),
        TextCellValue('اسم الصنف'),
        TextCellValue('الموديل'),
        TextCellValue('الفئة'),
        TextCellValue('سعر التأجير (يوم)'),
        TextCellValue('الكمية المتوفرة'),
        TextCellValue('الكمية الإجمالية'),
        TextCellValue('الحالة'),
      ];
      sheet.appendRow(headers);
      for (int i = 0; i < headers.length; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 3)).cellStyle = headerStyle;
      }

      // ── متغيرات الإجماليات ──
      int sumAvailable = 0;
      int sumTotal = 0;

      int currentRow = 4;
      for (int i = 0; i < listToExport.length; i++) {
        final item = listToExport[i];

        // ترجمة حالة الصنف
        String statusTxt = 'متوفر';
        if (item.status == ItemStatus.rented) statusTxt = 'مؤجر';
        else if (item.status == ItemStatus.maintenance) statusTxt = 'صيانة';
        else if (item.status == ItemStatus.reserved) statusTxt = 'محجوز';

        sheet.appendRow([
          IntCellValue(i + 1),
          TextCellValue(item.name),
          TextCellValue(item.model ?? '-'),
          TextCellValue(item.category?.name ?? '-'),
          DoubleCellValue(item.defaultPrice),
          IntCellValue(item.availableQty),
          IntCellValue(item.totalQty),
          TextCellValue(statusTxt),
        ]);

        for (int j = 0; j < 8; j++) {
          sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = dataStyle;
        }

        sumAvailable += item.availableQty;
        sumTotal += item.totalQty;
        currentRow++;
      }

      // ── سطر الإجماليات النهائي ──
      sheet.appendRow([TextCellValue('')]);
      currentRow++;

      sheet.appendRow([
        TextCellValue(''),
        TextCellValue('إجمالي كميات المخزن'),
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue(''),
        IntCellValue(sumAvailable),
        IntCellValue(sumTotal),
        TextCellValue(''),
      ]);

      for (int j = 0; j < 8; j++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: j, rowIndex: currentRow)).cellStyle = boldDataStyle;
      }

      // ── حفظ وتصدير ──
      var fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName = 'Inventory_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }

      return true;
    } catch (e) {
      if (!isClosed) {
        emit(InventoryError('حدث خطأ أثناء تصدير الملف: $e'));
      }
      return false;
    }
  }
}