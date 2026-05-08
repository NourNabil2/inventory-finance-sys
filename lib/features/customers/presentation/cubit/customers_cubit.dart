// lib/features/customers/presentation/cubit/customers_cubit.dart
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<void> exportCustomersToExcel({DateTime? startDate, DateTime? endDate}) async {
    try {
      // 1. جلب البيانات
      final supabase = Supabase.instance.client;
      final response = await supabase.rpc(
        'get_customers_period_report',
        params: {
          'p_start_date': startDate?.toIso8601String(),
          'p_end_date': endDate?.toIso8601String(),
        },
      );

      final List<dynamic> rawData = response as List<dynamic>;

      if (rawData.isEmpty) {
        if (!isClosed) {
          emit(state.copyWith(
            status: CustomersStatus.failure,
            errorMessage: 'لا يوجد حركات مالية أو فواتير للعملاء في هذه الفترة للتصدير',
          ));
        }
        return;
      }

      // ── تجهيز نص الفترة ──────────────────────────────────────────────────
      String dateStr = 'كل الوقت';
      if (startDate != null && endDate != null) {
        final sameDay = startDate.year == endDate.year &&
            startDate.month == endDate.month &&
            startDate.day == endDate.day;
        dateStr = sameDay
            ? DateFormat('yyyy-MM-dd').format(startDate)
            : '${DateFormat('yyyy-MM-dd').format(startDate)} إلى ${DateFormat('yyyy-MM-dd').format(endDate)}';
      }

      // ── إنشاء الملف ──────────────────────────────────────────────────────
      final excel = Excel.createExcel();
      excel.delete('Sheet1');

      // ════════════════════════════════════════════════════════════════════════
      //  SHEET 1 — الملخص
      // ════════════════════════════════════════════════════════════════════════
      excel['summary'];
      final Sheet summary = excel.sheets['summary']!;
      summary.isRTL = true;

      // ── حساب الإجماليات مسبقاً للملخص ──────────────────────────────────
      double sumInvoiced = 0, sumPaid = 0, sumPeriodDebt = 0,
          sumTotalDebt = 0, sumWallet = 0;
      int debtorsCount = 0;

      for (final row in rawData) {
        final r = row as Map<String, dynamic>;
        sumInvoiced  += (r['period_invoiced']    as num).toDouble();
        sumPaid      += (r['period_paid']         as num).toDouble();
        sumPeriodDebt+= (r['period_debt']         as num).toDouble();
        sumTotalDebt += (r['current_total_debt']  as num).toDouble();
        sumWallet    += (r['wallet_balance']      as num).toDouble();
        if ((r['current_total_debt'] as num).toDouble() > 0) debtorsCount++;
      }

      _buildSummarySheet(
        sheet: summary,
        dateStr: dateStr,
        totalCustomers: rawData.length,
        debtorsCount: debtorsCount,
        sumInvoiced: sumInvoiced,
        sumPaid: sumPaid,
        sumPeriodDebt: sumPeriodDebt,
        sumTotalDebt: sumTotalDebt,
        sumWallet: sumWallet,
        rawData: rawData,
      );

      // ════════════════════════════════════════════════════════════════════════
      //  SHEET 2 — التفاصيل
      // ════════════════════════════════════════════════════════════════════════
      excel['details'];
      final Sheet details = excel.sheets['details']!;
      details.isRTL = true;

      _buildDetailsSheet(
        sheet: details,
        dateStr: dateStr,
        rawData: rawData,
        sumInvoiced: sumInvoiced,
        sumPaid: sumPaid,
        sumPeriodDebt: sumPeriodDebt,
        sumTotalDebt: sumTotalDebt,
        sumWallet: sumWallet,
      );

      // تسمية الشيتات بالعربي
      excel.rename('summary', 'الملخص التنفيذي');
      excel.rename('details', 'تفاصيل العملاء');
      excel.setDefaultSheet('الملخص التنفيذي');

      // ── حفظ وتصدير ───────────────────────────────────────────────────────
      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final fileName =
            'تقرير_حسابات_العملاء_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
        await FileSaver.instance.saveFile(
          name: fileName,
          bytes: Uint8List.fromList(fileBytes),
          ext: 'xlsx',
          mimeType: MimeType.microsoftExcel,
        );
      }
    } catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
          status: CustomersStatus.failure,
          errorMessage: 'حدث خطأ أثناء تصدير الملف: $e',
        ));
      }
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  SHEET 1 BUILDER — الملخص التنفيذي
  // ══════════════════════════════════════════════════════════════════════════════
  void _buildSummarySheet({
    required Sheet sheet,
    required String dateStr,
    required int totalCustomers,
    required int debtorsCount,
    required double sumInvoiced,
    required double sumPaid,
    required double sumPeriodDebt,
    required double sumTotalDebt,
    required double sumWallet,
    required List<dynamic> rawData,
  }) {
    int row = 0;

    // ── [1] Main title ──────────────────────────────────────────────────────
    _setCell(sheet, row, 0,
      value: _ar('تقرير حسابات وحركات العملاء'),
      style: _s(bold: true, fontSize: 16, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_idx(row, 0), _idx(row, 5));
    row++;

    // ── [2] Sub-title (period) ──────────────────────────────────────────────
    _setCell(sheet, row, 0,
      value: _ar('الفترة: $dateStr'),
      style: _s(bold: true, fontSize: 12, bg: '2E86AB', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_idx(row, 0), _idx(row, 5));
    row++;

    // ── [3] Issue date ──────────────────────────────────────────────────────
    _setCell(sheet, row, 0,
      value: _ar('تاريخ إصدار التقرير: ${DateFormat('yyyy-MM-dd  HH:mm').format(DateTime.now())}'),
      style: _s(fontSize: 10, bg: 'EBF5FB', fg: '555555',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_idx(row, 0), _idx(row, 5));
    row += 2;

    // ── [4] KPI cards row ───────────────────────────────────────────────────
    _sectionHeader(sheet, row, 'المؤشرات الرئيسية', 6);
    row++;

    final kpis = [
      ['إجمالي العملاء',   totalCustomers.toString(),              'E8F4FD', '1A5276'],
      ['العملاء المدينون',  debtorsCount.toString(),               'FEF9E7', '7D6608'],
      ['فواتير الفترة',    '${_money(sumInvoiced)} ج.م',          'EAF7EA', '1E8449'],
      ['مدفوعات الفترة',   '${_money(sumPaid)} ج.م',              'EAF7EA', '1E8449'],
      ['صافي مديونية الفترة', '${_money(sumPeriodDebt)} ج.م',    'FDEDEC', 'C0392B'],
      ['إجمالي المديونية', '${_money(sumTotalDebt)} ج.م',         'FDEDEC', 'C0392B'],
    ];

    // Label row
    for (int col = 0; col < kpis.length; col++) {
      _setCell(sheet, row, col,
        value: _ar(kpis[col][0]),
        style: _s(bold: true, fontSize: 10, bg: kpis[col][2], fg: kpis[col][3],
            align: HorizontalAlign.Center),
      );
    }
    row++;

    // Value row
    for (int col = 0; col < kpis.length; col++) {
      _setCell(sheet, row, col,
        value: _ar(kpis[col][1]),
        style: _s(bold: true, fontSize: 13, bg: kpis[col][2], fg: kpis[col][3],
            align: HorizontalAlign.Center),
      );
    }
    row += 2;

    // ── [5] Top 5 debtors ───────────────────────────────────────────────────
    _sectionHeader(sheet, row, 'أعلى 5 عملاء مديونية', 4);
    row++;

    final topDebtHeaders = ['#', 'اسم العميل', 'رقم الهاتف', 'المديونية الكلية'];
    for (int col = 0; col < topDebtHeaders.length; col++) {
      _setCell(sheet, row, col,
        value: _ar(topDebtHeaders[col]),
        style: _headerStyle(),
      );
    }
    row++;

    final sorted = [...rawData]..sort((a, b) =>
        ((b as Map)['current_total_debt'] as num)
            .compareTo(((a as Map)['current_total_debt'] as num)));

    int rank = 1;
    for (final item in sorted.take(5)) {
      final r = item as Map<String, dynamic>;
      final debt = (r['current_total_debt'] as num).toDouble();
      final rowData = [
        rank.toString(),
        r['customer_name']?.toString() ?? '-',
        r['customer_phone']?.toString() ?? '-',
        '${_money(debt)} ج.م',
      ];
      for (int col = 0; col < rowData.length; col++) {
        _setCell(sheet, row, col,
          value: _ar(rowData[col]),
          style: _s(
            fontSize: 10,
            bg: rank == 1 ? 'FDEDEC' : (row % 2 == 0 ? 'F8F9FA' : 'FFFFFF'),
            fg: rank == 1 ? 'C0392B' : '000000',
            bold: rank == 1,
            align: col == 0 ? HorizontalAlign.Center : HorizontalAlign.Right,
          ),
        );
      }
      rank++;
      row++;
    }
    row++;

    // ── [6] Top 5 payers ────────────────────────────────────────────────────
    _sectionHeader(sheet, row, 'أعلى 5 عملاء دفعاً في الفترة', 4);
    row++;

    final topPayHeaders = ['#', 'اسم العميل', 'رقم الهاتف', 'إجمالي المدفوعات'];
    for (int col = 0; col < topPayHeaders.length; col++) {
      _setCell(sheet, row, col,
        value: _ar(topPayHeaders[col]),
        style: _headerStyle(),
      );
    }
    row++;

    final sortedPay = [...rawData]..sort((a, b) =>
        ((b as Map)['period_paid'] as num)
            .compareTo(((a as Map)['period_paid'] as num)));

    rank = 1;
    for (final item in sortedPay.take(5)) {
      final r = item as Map<String, dynamic>;
      final paid = (r['period_paid'] as num).toDouble();
      final rowData = [
        rank.toString(),
        r['customer_name']?.toString() ?? '-',
        r['customer_phone']?.toString() ?? '-',
        '${_money(paid)} ج.م',
      ];
      for (int col = 0; col < rowData.length; col++) {
        _setCell(sheet, row, col,
          value: _ar(rowData[col]),
          style: _s(
            fontSize: 10,
            bg: rank == 1 ? 'EAF7EA' : (row % 2 == 0 ? 'F8F9FA' : 'FFFFFF'),
            fg: rank == 1 ? '1E8449' : '000000',
            bold: rank == 1,
            align: col == 0 ? HorizontalAlign.Center : HorizontalAlign.Right,
          ),
        );
      }
      rank++;
      row++;
    }

    // Column widths
    for (int i = 0; i < 6; i++) {
      sheet.setColumnWidth(i, i == 1 ? 28 : 20);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  SHEET 2 BUILDER — تفاصيل العملاء
  // ══════════════════════════════════════════════════════════════════════════════
  void _buildDetailsSheet({
    required Sheet sheet,
    required String dateStr,
    required List<dynamic> rawData,
    required double sumInvoiced,
    required double sumPaid,
    required double sumPeriodDebt,
    required double sumTotalDebt,
    required double sumWallet,
  }) {
    int row = 0;

    // ── [1] Title ───────────────────────────────────────────────────────────
    _setCell(sheet, row, 0,
      value: _ar('تفاصيل حسابات العملاء — $dateStr'),
      style: _s(bold: true, fontSize: 14, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_idx(row, 0), _idx(row, 7));
    row += 2;

    // ── [2] Column headers ──────────────────────────────────────────────────
    const headers = [
      'م', 'اسم العميل', 'رقم الهاتف',
      'فواتير الفترة', 'مدفوعات الفترة',
      'صافي مديونية الفترة', 'المديونية الكلية المستحقة', 'رصيد المحفظة',
    ];

    for (int col = 0; col < headers.length; col++) {
      _setCell(sheet, row, col,
        value: _ar(headers[col]),
        style: _headerStyle(),
      );
    }
    row++;

    // ── [3] Data rows ────────────────────────────────────────────────────────
    for (int i = 0; i < rawData.length; i++) {
      final r = rawData[i] as Map<String, dynamic>;

      final invoiced   = (r['period_invoiced']   as num).toDouble();
      final paid       = (r['period_paid']        as num).toDouble();
      final periodDebt = (r['period_debt']        as num).toDouble();
      final totalDebt  = (r['current_total_debt'] as num).toDouble();
      final wallet     = (r['wallet_balance']     as num).toDouble();

      final isDebtor = totalDebt > 0;
      final baseBg   = isDebtor ? 'FFF5F5' : (i % 2 == 0 ? 'F8F9FA' : 'FFFFFF');

      final rowData = [
        (i + 1).toString(),
        r['customer_name']?.toString()  ?? '-',
        r['customer_phone']?.toString() ?? '-',
        '${_money(invoiced)} ج.م',
        '${_money(paid)} ج.م',
        '${_money(periodDebt)} ج.م',
        '${_money(totalDebt)} ج.م',
        '${_money(wallet)} ج.م',
      ];

      for (int col = 0; col < rowData.length; col++) {
        // عمود المديونية الكلية — لونه مختلف لو في دين
        String cellBg = baseBg;
        String cellFg = '000000';
        bool cellBold = false;

        if (col == 6 && totalDebt > 0) {
          cellBg   = 'FDEDEC';
          cellFg   = 'C0392B';
          cellBold = true;
        } else if (col == 5 && periodDebt > 0) {
          cellBg   = 'FEF9E7';
          cellFg   = '7D6608';
          cellBold = true;
        } else if (col == 7 && wallet > 0) {
          cellBg   = 'EAF7EA';
          cellFg   = '1E8449';
        }

        _setCell(sheet, row, col,
          value: _ar(rowData[col]),
          style: _s(
            fontSize: 10,
            bg: cellBg,
            fg: cellFg,
            bold: cellBold,
            align: col <= 2 ? HorizontalAlign.Center : HorizontalAlign.Right,
            wrap: col == 1,
          ),
        );
      }
      row++;
    }

    // ── [4] Totals row ───────────────────────────────────────────────────────
    row++; // فراغ
    final totalsData = [
      '', 'الإجماليات الكلية', '',
      '${_money(sumInvoiced)} ج.م',
      '${_money(sumPaid)} ج.م',
      '${_money(sumPeriodDebt)} ج.م',
      '${_money(sumTotalDebt)} ج.م',
      '${_money(sumWallet)} ج.م',
    ];
    for (int col = 0; col < totalsData.length; col++) {
      _setCell(sheet, row, col,
        value: _ar(totalsData[col]),
        style: _s(
          bold: true, fontSize: 11,
          bg: '1E3A5F', fg: 'FFFFFF',
          align: col <= 2 ? HorizontalAlign.Center : HorizontalAlign.Right,
        ),
      );
    }

    // Column widths
    sheet.setColumnWidth(0, 5);
    sheet.setColumnWidth(1, 28);
    sheet.setColumnWidth(2, 16);
    sheet.setColumnWidth(3, 18);
    sheet.setColumnWidth(4, 18);
    sheet.setColumnWidth(5, 20);
    sheet.setColumnWidth(6, 22);
    sheet.setColumnWidth(7, 18);
  }

  // ══════════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════════

  /// RTL embedding mark — يخلي Excel يعرض العربي صح
  static String _ar(String text) => '\u202B$text';

  /// مبلغ بفاصلة آلاف
  static String _money(double v) =>
      NumberFormat('#,##0.00', 'ar').format(v);

  static CellIndex _idx(int row, int col) =>
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

  // التعديل هنا: قمنا بتغيير نوع value من CellValue إلى String
  // لكي نتمكن من تغليفها بـ TextCellValue داخل الدالة تلقائياً
  static void _setCell(
      Sheet sheet,
      int row,
      int col, {
        required String value, // <--- التعديل هنا
        required CellStyle style,
      }) {
    final cell = sheet.cell(_idx(row, col));
    cell.value = TextCellValue(value); // <--- والتعديل هنا
    cell.cellStyle = style;
  }

  static CellStyle _s({
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

  static CellStyle _headerStyle() => _s(
    bold: true,
    fontSize: 11,
    bg: '2E86AB',
    fg: 'FFFFFF',
    align: HorizontalAlign.Center,
  );

  static void _sectionHeader(Sheet sheet, int row, String title, int colSpan) {
    _setCell(
      sheet, row, 0,
      value: _ar(title),
      style: _s(bold: true, fontSize: 12, bg: 'D6EAF8', fg: '1A5276',
          align: HorizontalAlign.Right),
    );
    if (colSpan > 1) {
      sheet.merge(_idx(row, 0), _idx(row, colSpan - 1));
    }
  }
}