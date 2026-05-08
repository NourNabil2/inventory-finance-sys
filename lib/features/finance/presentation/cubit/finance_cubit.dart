// lib/features/finance/presentation/cubit/finance_cubit.dart
//
// ✅ exportLedgerToExcel — محسّن بنفس أسلوب invoice export
//    (باقي الـ cubit زي ما هو، فقط الـ export وهلبرز بتاعته اتغيروا)

import 'dart:typed_data';
import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/finance/domain/entities/financial_transaction_entity.dart';
import 'package:bungee_manage_sys/features/finance/domain/repositories/finance_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'dart:math' as math;

part 'finance_state.dart';

class FinanceCubit extends Cubit<FinanceState> {
  final FinanceRepository _repository;

  FinanceCubit(this._repository) : super(FinanceInitial());

  // ── loadSummary ────────────────────────────────────────────────────────────
  Future<void> loadSummary() async {
    emit(FinanceLoading());
    final result = await _repository.getFinancialSummary();
    result.fold(
          (f) => emit(FinanceError(f.message)),
          (s) => emit(FinanceLoaded(summary: s)),
    );
  }

  // ── loadTransactions ───────────────────────────────────────────────────────
  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    PaymentMethod? method,
    TransactionCategory? category,
  }) async {
    emit(FinanceLoading());
    final result = await _repository.getTransactions(
      startDate: startDate,
      endDate: endDate,
      type: type,
      method: method,
      category: category,
    );
    result.fold(
          (f) => emit(FinanceError(f.message)),
          (t) => emit(FinanceTransactionsLoaded(transactions: t)),
    );
  }

  // ── createTransaction ──────────────────────────────────────────────────────
  Future<void> createTransaction({
    required double amount,
    required TransactionType type,
    required PaymentMethod method,
    required TransactionCategory category,
    String? referenceId,
    String? notes,
  }) async {
    emit(FinanceProcessing());

    if (amount <= 0) {
      emit(const FinanceError('finance.invalid_amount'));
      return;
    }

    if (type == TransactionType.expense) {
      final balanceResult = method == PaymentMethod.cash
          ? await _repository.getCashBalance()
          : await _repository.getBankBalance();
      final balance = balanceResult.fold((_) => 0.0, (b) => b);
      if (balance < amount) {
        emit(const FinanceError('finance.insufficient_balance'));
        return;
      }
    }

    final result = await _repository.createTransaction(
      amount: amount,
      type: type,
      method: method,
      category: category,
      referenceId: referenceId,
      notes: notes,
    );

    result.fold(
          (f) => emit(FinanceError(f.message)),
          (_) async => loadSummary(),
    );
  }

  Future<void> depositToWallet({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    emit(FinanceProcessing());
    if (amount <= 0) {
      emit(const FinanceError('finance.invalid_amount'));
      return;
    }
    final result = await _repository.depositToWallet(
      customerId: customerId,
      amount: amount,
      method: method,
      notes: notes,
    );
    result.fold(
          (f) => emit(FinanceError(f.message)),
          (_) async => loadSummary(),
    );
  }

  Future<void> recordWithdrawal({
    required double amount,
    required PaymentMethod method,
    required TransactionCategory category,
    String? notes,
  }) async =>
      createTransaction(
        amount: amount,
        type: TransactionType.expense,
        method: method,
        category: category,
        notes: notes,
      );

  // ══════════════════════════════════════════════════════════════════════════
  //  EXCEL EXPORT — محسّن
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> exportLedgerToExcel({
    PaymentMethod? method,
    TransactionType? type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(FinanceProcessing());

    final result = await _repository.getTransactions();

    await result.fold(
          (failure) async {
        emit(FinanceError(failure.message));
        await loadSummary();
      },
          (allTransactions) async {
        try {
          final startOfPeriod =
          DateTime(startDate.year, startDate.month, startDate.day);
          final endOfPeriod = DateTime(
              endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

          // 1. فلترة بالحساب
          final methodFiltered = method == null
              ? allTransactions
              : allTransactions.where((t) => t.method == method).toList();

          // 2. الرصيد الافتتاحي
          double openingBalance = 0;
          for (var t
          in methodFiltered.where((t) => t.createdAt.isBefore(startOfPeriod))) {
            openingBalance += t.isIncome ? t.amount : -t.amount;
          }

          // 3. معاملات الفترة
          var periodTxs = methodFiltered
              .where((t) =>
          !t.createdAt
              .isBefore(startOfPeriod) &&
              !t.createdAt.isAfter(endOfPeriod))
              .toList();

          // 4. فلترة بالنوع
          if (type != null) {
            periodTxs = periodTxs.where((t) => t.type == type).toList();
          }

          // ── إنشاء الملف ─────────────────────────────────────────────────
          final excel = Excel.createExcel();
          excel.delete('Sheet1');

          final String accName = method == null
              ? 'كل الحسابات'
              : (method == PaymentMethod.cash ? 'الخزينة' : 'البنك');
          final String typeName = type == null
              ? 'يومية'
              : (type == TransactionType.income ? 'الوارد' : 'المصروفات');

          final dateStr = startDate.isAtSameMomentAs(endDate)
              ? DateFormat('yyyy-MM-dd').format(startDate)
              : '${DateFormat('yyyy-MM-dd').format(startDate)} → ${DateFormat('yyyy-MM-dd').format(endDate)}';

          // ── Sheet 1: الملخص (دايمًا موجود) ───────────────────────────────
          excel['summary'];
          final Sheet summarySheet = excel.sheets['summary']!;
          summarySheet.isRTL = true;

          // حسابات مسبقة
          final incomes = periodTxs.where((t) => t.isIncome).toList();
          final expenses = periodTxs.where((t) => !t.isIncome).toList();
          final totalIncome = incomes.fold(0.0, (s, t) => s + t.amount);
          final totalExpense = expenses.fold(0.0, (s, t) => s + t.amount);
          final netBalance = openingBalance + totalIncome - totalExpense;

          _buildFinanceSummarySheet(
            sheet: summarySheet,
            accName: accName,
            typeName: typeName,
            dateStr: dateStr,
            openingBalance: openingBalance,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            netBalance: netBalance,
            periodTxs: periodTxs,
            incomes: incomes,
            expenses: expenses,
          );

          // ── Sheet 2: التفاصيل ─────────────────────────────────────────────
          excel['details'];
          final Sheet detailsSheet = excel.sheets['details']!;
          detailsSheet.isRTL = true;

          if (type == null) {
            // يومية: عمودين (وارد | صادر)
            _buildLedgerDetailsSheet(
              sheet: detailsSheet,
              accName: accName,
              dateStr: dateStr,
              openingBalance: openingBalance,
              incomes: incomes,
              expenses: expenses,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              netBalance: netBalance,
              showAccount: method == null,
            );
          } else {
            // وارد أو صادر فقط: شيت طولي
            _buildSingleTypeDetailsSheet(
              sheet: detailsSheet,
              typeName: typeName,
              accName: accName,
              dateStr: dateStr,
              transactions: periodTxs,
              showAccount: method == null,
            );
          }

          // ── تسمية الشيتات ─────────────────────────────────────────────────
          excel.rename('summary', 'الملخص');
          excel.rename('details', type == null ? 'اليومية' : typeName);
          excel.setDefaultSheet('الملخص');

          // ── حفظ ──────────────────────────────────────────────────────────
          final bytes = excel.encode();
          if (bytes != null) {
            final fileName =
                'تقرير_${typeName}_${accName.replaceAll(' ', '_')}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
            await FileSaver.instance.saveFile(
              name: fileName,
              bytes: Uint8List.fromList(bytes),
              ext: 'xlsx',
              mimeType: MimeType.microsoftExcel,
            );
          }

          await loadSummary();
        } catch (e) {
          emit(FinanceError('حدث خطأ أثناء تصدير الملف: $e'));
          await loadSummary();
        }
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHEET 1 — الملخص المالي
  // ══════════════════════════════════════════════════════════════════════════

  void _buildFinanceSummarySheet({
    required Sheet sheet,
    required String accName,
    required String typeName,
    required String dateStr,
    required double openingBalance,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required List<dynamic> periodTxs,
    required List<dynamic> incomes,
    required List<dynamic> expenses,
  }) {
    int row = 0;

    // ── [1] العنوان الرئيسي ──────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar('تقرير $typeName — $accName')),
      style: _fS(bold: true, fontSize: 16, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_fIdx(row, 0), _fIdx(row, 5));
    row++;

    // ── [2] الفترة ───────────────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar('الفترة: $dateStr')),
      style: _fS(bold: true, fontSize: 12, bg: '2E86AB', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_fIdx(row, 0), _fIdx(row, 5));
    row++;

    // ── [3] تاريخ الإصدار ────────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(
          _ar('تاريخ الإصدار: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}')),
      style: _fS(fontSize: 10, bg: 'EBF5FB', fg: '555555',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_fIdx(row, 0), _fIdx(row, 5));
    row += 2;

    // ── [4] KPI cards ────────────────────────────────────────────────────
    _fSectionHeader(sheet, row, 'المؤشرات الرئيسية', 6);
    row++;

    final kpis = [
      ['إجمالي الحركات', periodTxs.length.toString(),       'E8F4FD', '1A5276'],
      ['عدد الوارد',     incomes.length.toString(),          'EAF7EA', '1E8449'],
      ['عدد الصادر',     expenses.length.toString(),         'FDEDEC', 'C0392B'],
      ['رصيد افتتاحي',  '${_fMoney(openingBalance)} ج.م',  'FEF9E7', '7D6608'],
      ['إجمالي الوارد',  '${_fMoney(totalIncome)} ج.م',    'EAF7EA', '1E8449'],
      ['الرصيد الختامي', '${_fMoney(netBalance)} ج.م',     '1E3A5F', 'FFFFFF'],
    ];

    // صف العناوين
    for (int col = 0; col < kpis.length; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(_ar(kpis[col][0])),
        style: _fS(bold: true, fontSize: 10, bg: kpis[col][2], fg: kpis[col][3],
            align: HorizontalAlign.Center),
      );
    }
    row++;

    // صف القيم
    for (int col = 0; col < kpis.length; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(_ar(kpis[col][1])),
        style: _fS(bold: true, fontSize: 13, bg: kpis[col][2], fg: kpis[col][3],
            align: HorizontalAlign.Center),
      );
    }
    row += 2;

    // ── [5] الملخص المالي ───────────────────────────────────────────────
    _fSectionHeader(sheet, row, 'الملخص المالي', 3);
    row++;

    final finHeaders = ['البيان', 'المبلغ', 'الملاحظة'];
    for (int col = 0; col < finHeaders.length; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(_ar(finHeaders[col])),
        style: _fHeaderStyle(),
      );
    }
    row++;

    final netPct = openingBalance + totalIncome > 0
        ? '${((netBalance / (openingBalance + totalIncome)) * 100).toStringAsFixed(1)}%'
        : '—';

    final finRows = [
      ['الرصيد الافتتاحي', '${_fMoney(openingBalance)} ج.م', '—',           'FEF9E7'],
      ['إجمالي الوارد',    '${_fMoney(totalIncome)} ج.م',   '—',           'EAF7EA'],
      ['إجمالي الصادر',   '${_fMoney(totalExpense)} ج.م',   '—',           'FDEDEC'],
      ['الرصيد الختامي',  '${_fMoney(netBalance)} ج.م',     netPct,        netBalance >= 0 ? 'D5F5E3' : 'FADBD8'],
    ];

    for (final fr in finRows) {
      for (int col = 0; col < 3; col++) {
        _fSet(sheet, row, col,
          value: TextCellValue(_ar(fr[col])),
          style: _fS(
            fontSize: 11,
            bold: fr[3] == 'D5F5E3' || fr[3] == 'FADBD8',
            bg: fr[3],
            fg: fr[3] == 'FADBD8' ? 'C0392B' : '000000',
            align: col == 0 ? HorizontalAlign.Right : HorizontalAlign.Center,
          ),
        );
      }
      row++;
    }
    row++;

    // ── [6] أعلى 5 حركات واردة ───────────────────────────────────────────
    final sortedIncomes = [...incomes]
      ..sort((a, b) => (b.amount as double).compareTo(a.amount as double));

    if (sortedIncomes.isNotEmpty) {
      _fSectionHeader(sheet, row, 'أعلى 5 حركات واردة', 4);
      row++;

      final topIncHeaders = ['التاريخ', 'البيان', 'الحساب', 'المبلغ'];
      for (int col = 0; col < topIncHeaders.length; col++) {
        _fSet(sheet, row, col,
          value: TextCellValue(_ar(topIncHeaders[col])),
          style: _fHeaderStyle(),
        );
      }
      row++;

      int rank = 1;
      for (final t in sortedIncomes.take(5)) {
        final isTop = rank == 1;
        final rowData = [
          DateFormat('yyyy-MM-dd').format(t.createdAt),
          t.categoryDisplayName + (t.customerName?.isNotEmpty == true ? ' — ${t.customerName}' : ''),
          t.method == PaymentMethod.cash ? 'خزينة' : 'بنك',
          '${_fMoney(t.amount)} ج.م',
        ];
        for (int col = 0; col < rowData.length; col++) {
          _fSet(sheet, row, col,
            value: TextCellValue(_ar(rowData[col])),
            style: _fS(
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
      row++;
    }

    // ── [7] أعلى 5 حركات صادرة ──────────────────────────────────────────
    final sortedExpenses = [...expenses]
      ..sort((a, b) => (b.amount as double).compareTo(a.amount as double));

    if (sortedExpenses.isNotEmpty) {
      _fSectionHeader(sheet, row, 'أعلى 5 حركات صادرة', 4);
      row++;

      final topExpHeaders = ['التاريخ', 'البيان', 'الحساب', 'المبلغ'];
      for (int col = 0; col < topExpHeaders.length; col++) {
        _fSet(sheet, row, col,
          value: TextCellValue(_ar(topExpHeaders[col])),
          style: _fHeaderStyle(),
        );
      }
      row++;

      int rank = 1;
      for (final t in sortedExpenses.take(5)) {
        final isTop = rank == 1;
        final rowData = [
          DateFormat('yyyy-MM-dd').format(t.createdAt),
          t.categoryDisplayName + (t.customerName?.isNotEmpty == true ? ' — ${t.customerName}' : ''),
          t.method == PaymentMethod.cash ? 'خزينة' : 'بنك',
          '${_fMoney(t.amount)} ج.م',
        ];
        for (int col = 0; col < rowData.length; col++) {
          _fSet(sheet, row, col,
            value: TextCellValue(_ar(rowData[col])),
            style: _fS(
              fontSize: 10,
              bold: isTop,
              bg: isTop ? 'FADBD8' : (row % 2 == 0 ? 'F8F9FA' : 'FFFFFF'),
              fg: isTop ? 'C0392B' : '000000',
              align: col == 3 ? HorizontalAlign.Center : HorizontalAlign.Right,
            ),
          );
        }
        rank++;
        row++;
      }
    }

    // عرض الأعمدة
    for (int i = 0; i < 6; i++) {
      sheet.setColumnWidth(i, i == 0 ? 26 : 18);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHEET 2A — يومية (وارد | صادر)
  // ══════════════════════════════════════════════════════════════════════════

  void _buildLedgerDetailsSheet({
    required Sheet sheet,
    required String accName,
    required String dateStr,
    required double openingBalance,
    required List<dynamic> incomes,
    required List<dynamic> expenses,
    required double totalIncome,
    required double totalExpense,
    required double netBalance,
    required bool showAccount,
  }) {
    int row = 0;

    // ── العنوان ──────────────────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar('يومية — $accName ($dateStr)')),
      style: _fS(bold: true, fontSize: 14, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_fIdx(row, 0), _fIdx(row, 3));
    row += 2;

    // ── رصيد افتتاحي ────────────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar('الرصيد الافتتاحي')),
      style: _fS(bold: true, fontSize: 11, bg: 'FEF9E7', fg: '7D6608',
          align: HorizontalAlign.Right),
    );
    _fSet(sheet, row, 1,
      value: TextCellValue(_ar('${_fMoney(openingBalance)} ج.م')),
      style: _fS(bold: true, fontSize: 11, bg: 'FEF9E7', fg: '7D6608',
          align: HorizontalAlign.Center),
    );
    _fSet(sheet, row, 2, value: TextCellValue(''), style: _fS(bg: 'FEF9E7'));
    _fSet(sheet, row, 3, value: TextCellValue(''), style: _fS(bg: 'FEF9E7'));
    row++;
    row++;

    // ── رؤوس الأعمدة ────────────────────────────────────────────────────
    final headers = ['الوارد', 'قيمته', 'الصادر', 'قيمته'];
    for (int col = 0; col < headers.length; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(_ar(headers[col])),
        style: _fHeaderStyle(),
      );
    }
    row++;

    // ── صفوف البيانات ────────────────────────────────────────────────────
    final maxRows = math.max(incomes.length, expenses.length);
    for (int i = 0; i < maxRows; i++) {
      final inc = i < incomes.length ? incomes[i] : null;
      final exp = i < expenses.length ? expenses[i] : null;
      final baseBg = i % 2 == 0 ? 'F8F9FA' : 'FFFFFF';

      String incDesc = '';
      if (inc != null) {
        incDesc = inc.categoryDisplayName;
        if (showAccount) incDesc += ' [${inc.method == PaymentMethod.cash ? 'خزينة' : 'بنك'}]';
        if (inc.customerName?.isNotEmpty ?? false) incDesc += '\n${inc.customerName}';
        if (inc.notes?.isNotEmpty ?? false) incDesc += '\n${inc.notes}';
      }

      String expDesc = '';
      if (exp != null) {
        expDesc = exp.categoryDisplayName;
        if (showAccount) expDesc += ' [${exp.method == PaymentMethod.cash ? 'خزينة' : 'بنك'}]';
        if (exp.customerName?.isNotEmpty ?? false) expDesc += '\n${exp.customerName}';
        if (exp.notes?.isNotEmpty ?? false) expDesc += '\n${exp.notes}';
      }

      _fSet(sheet, row, 0,
        value: TextCellValue(_ar(incDesc)),
        style: _fS(fontSize: 10, bg: inc != null ? 'F0FAF0' : baseBg,
            fg: '1E8449', wrap: true, align: HorizontalAlign.Right),
      );
      _fSet(sheet, row, 1,
        value: TextCellValue(inc != null ? _ar('${_fMoney(inc.amount)} ج.م') : ''),
        style: _fS(fontSize: 10, bold: true, bg: inc != null ? 'F0FAF0' : baseBg,
            fg: '1E8449', align: HorizontalAlign.Center),
      );
      _fSet(sheet, row, 2,
        value: TextCellValue(_ar(expDesc)),
        style: _fS(fontSize: 10, bg: exp != null ? 'FDF2F2' : baseBg,
            fg: 'C0392B', wrap: true, align: HorizontalAlign.Right),
      );
      _fSet(sheet, row, 3,
        value: TextCellValue(exp != null ? _ar('${_fMoney(exp.amount)} ج.م') : ''),
        style: _fS(fontSize: 10, bold: true, bg: exp != null ? 'FDF2F2' : baseBg,
            fg: 'C0392B', align: HorizontalAlign.Center),
      );
      row++;
    }

    // ── الإجماليات ───────────────────────────────────────────────────────
    row++;
    final totalsData = [
      _ar('إجمالي وارد'), _ar('${_fMoney(totalIncome)} ج.م'),
      _ar('إجمالي صادر'), _ar('${_fMoney(totalExpense)} ج.م'),
    ];
    for (int col = 0; col < totalsData.length; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(totalsData[col]),
        style: _fS(bold: true, fontSize: 11, bg: '2E86AB', fg: 'FFFFFF',
            align: HorizontalAlign.Center),
      );
    }
    row++;

    // ── الرصيد الختامي ───────────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar('الرصيد الختامي')),
      style: _fS(bold: true, fontSize: 12,
          bg: netBalance >= 0 ? '1E3A5F' : 'C0392B', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    _fSet(sheet, row, 1,
      value: TextCellValue(_ar('${_fMoney(netBalance)} ج.م')),
      style: _fS(bold: true, fontSize: 12,
          bg: netBalance >= 0 ? '1E3A5F' : 'C0392B', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    _fSet(sheet, row, 2, value: TextCellValue(''),
        style: _fS(bg: netBalance >= 0 ? '1E3A5F' : 'C0392B'));
    _fSet(sheet, row, 3, value: TextCellValue(''),
        style: _fS(bg: netBalance >= 0 ? '1E3A5F' : 'C0392B'));

    // عرض الأعمدة
    sheet.setColumnWidth(0, 40);
    sheet.setColumnWidth(1, 18);
    sheet.setColumnWidth(2, 40);
    sheet.setColumnWidth(3, 18);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHEET 2B — وارد فقط / صادر فقط (شيت طولي)
  // ══════════════════════════════════════════════════════════════════════════

  void _buildSingleTypeDetailsSheet({
    required Sheet sheet,
    required String typeName,
    required String accName,
    required String dateStr,
    required List<dynamic> transactions,
    required bool showAccount,
  }) {
    int row = 0;

    // ── العنوان ──────────────────────────────────────────────────────────
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar('$typeName — $accName ($dateStr)')),
      style: _fS(bold: true, fontSize: 14, bg: '1E3A5F', fg: 'FFFFFF',
          align: HorizontalAlign.Center),
    );
    sheet.merge(_fIdx(row, 0), _fIdx(row, showAccount ? 3 : 2));
    row += 2;

    // ── الأعمدة ──────────────────────────────────────────────────────────
    final headers = showAccount
        ? ['التاريخ', 'البيان', 'الحساب', 'المبلغ']
        : ['التاريخ', 'البيان', 'المبلغ'];
    for (int col = 0; col < headers.length; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(_ar(headers[col])),
        style: _fHeaderStyle(),
      );
    }
    row++;

    // ── البيانات ─────────────────────────────────────────────────────────
    double total = 0;
    final isExpense = transactions.isNotEmpty && !transactions.first.isIncome;
    final rowBg = isExpense ? 'FDF2F2' : 'F0FAF0';
    final rowFg = isExpense ? 'C0392B' : '1E8449';

    for (int i = 0; i < transactions.length; i++) {
      final t = transactions[i];
      final baseBg = i % 2 == 0 ? rowBg : 'FFFFFF';

      String desc = t.categoryDisplayName;
      if (t.customerName?.isNotEmpty ?? false) desc += '\n${t.customerName}';
      if (t.notes?.isNotEmpty ?? false) desc += '\n${t.notes}';

      if (showAccount) {
        _fSet(sheet, row, 0,
          value: TextCellValue(_ar(DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt))),
          style: _fS(fontSize: 10, bg: baseBg, align: HorizontalAlign.Center),
        );
        _fSet(sheet, row, 1,
          value: TextCellValue(_ar(desc)),
          style: _fS(fontSize: 10, bg: baseBg, wrap: true,
              align: HorizontalAlign.Right),
        );
        _fSet(sheet, row, 2,
          value: TextCellValue(_ar(t.method == PaymentMethod.cash ? 'خزينة' : 'بنك')),
          style: _fS(fontSize: 10, bg: baseBg, align: HorizontalAlign.Center),
        );
        _fSet(sheet, row, 3,
          value: TextCellValue(_ar('${_fMoney(t.amount)} ج.م')),
          style: _fS(fontSize: 10, bold: true, bg: baseBg, fg: rowFg,
              align: HorizontalAlign.Center),
        );
      } else {
        _fSet(sheet, row, 0,
          value: TextCellValue(_ar(DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt))),
          style: _fS(fontSize: 10, bg: baseBg, align: HorizontalAlign.Center),
        );
        _fSet(sheet, row, 1,
          value: TextCellValue(_ar(desc)),
          style: _fS(fontSize: 10, bg: baseBg, wrap: true,
              align: HorizontalAlign.Right),
        );
        _fSet(sheet, row, 2,
          value: TextCellValue(_ar('${_fMoney(t.amount)} ج.م')),
          style: _fS(fontSize: 10, bold: true, bg: baseBg, fg: rowFg,
              align: HorizontalAlign.Center),
        );
      }
      total += t.amount;
      row++;
    }

    // ── الإجمالي ─────────────────────────────────────────────────────────
    row++;
    final lastCol = showAccount ? 3 : 2;
    for (int col = 0; col <= lastCol; col++) {
      _fSet(sheet, row, col,
        value: TextCellValue(
          col == 0 ? _ar('الإجمالي')
              : col == lastCol ? _ar('${_fMoney(total)} ج.م')
              : TextCellValue('').toString(),
        ),
        style: _fS(bold: true, fontSize: 11, bg: '1E3A5F', fg: 'FFFFFF',
            align: HorizontalAlign.Center),
      );
    }

    // عرض الأعمدة
    sheet.setColumnWidth(0, 20);
    sheet.setColumnWidth(1, 44);
    if (showAccount) {
      sheet.setColumnWidth(2, 14);
      sheet.setColumnWidth(3, 18);
    } else {
      sheet.setColumnWidth(2, 18);
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS  (prefix _f لتجنب conflict)
  // ══════════════════════════════════════════════════════════════════════════

  static String _ar(String text) => '\u202B$text';

  static String _fMoney(double v) =>
      NumberFormat('#,##0.00', 'ar').format(v);

  static CellIndex _fIdx(int row, int col) =>
      CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row);

  static void _fSet(Sheet sheet, int row, int col,
      {required CellValue value, required CellStyle style}) {
    final cell = sheet.cell(_fIdx(row, col));
    cell.value = value;
    cell.cellStyle = style;
  }

  static CellStyle _fS({
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

  static CellStyle _fHeaderStyle() => _fS(
    bold: true,
    fontSize: 11,
    bg: '2E86AB',
    fg: 'FFFFFF',
    align: HorizontalAlign.Center,
  );

  static void _fSectionHeader(
      Sheet sheet, int row, String title, int colSpan) {
    _fSet(sheet, row, 0,
      value: TextCellValue(_ar(title)),
      style: _fS(bold: true, fontSize: 12, bg: 'D6EAF8', fg: '1A5276',
          align: HorizontalAlign.Right),
    );
    if (colSpan > 1) {
      sheet.merge(_fIdx(row, 0), _fIdx(row, colSpan - 1));
    }
  }
}