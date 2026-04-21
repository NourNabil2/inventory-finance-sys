// lib/features/finance/presentation/cubit/finance_cubit.dart

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

  // ── loadSummary ───────────────────────────────────────────────────────────

  Future<void> loadSummary() async {
    emit(FinanceLoading());
    final result = await _repository.getFinancialSummary();
    result.fold(
          (f) => emit(FinanceError(f.message)),
          (s) => emit(FinanceLoaded(summary: s)),
    );
  }

  // ── loadTransactions ──────────────────────────────────────────────────────

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
      endDate:   endDate,
      type:      type,
      method:    method,
      category:  category,
    );
    result.fold(
          (f) => emit(FinanceError(f.message)),
          (t) => emit(FinanceTransactionsLoaded(transactions: t)),
    );
  }

  // ── createTransaction ─────────────────────────────────────────────────────

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
      amount:      amount,
      type:        type,
      method:      method,
      category:    category,
      referenceId: referenceId,
      notes:       notes,
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
      customerId: customerId, amount: amount, method: method, notes: notes,
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
        amount:   amount, type: TransactionType.expense, method: method, category: category, notes: notes,
      );

  // ── EXCEL EXPORT ──────────────────────────────────────────────────────────

  Future<void> exportLedgerToExcel({
    PaymentMethod? method, // null = كل الحسابات
    TransactionType? type, // null = يومية (وارد وصادر)
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    emit(FinanceProcessing());

    // هنسحب كل المعاملات ونفلترها محلياً لضمان الدقة
    final result = await _repository.getTransactions();

    await result.fold(
          (failure) async {
        emit(FinanceError(failure.message));
        await loadSummary();
      },
          (allTransactions) async {
        try {
          final startOfPeriod = DateTime(startDate.year, startDate.month, startDate.day);
          final endOfPeriod = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

          // 1. فلترة بالحساب (لو اختار خزينة أو بنك بس)
          final methodFilteredTxs = method == null
              ? allTransactions
              : allTransactions.where((t) => t.method == method).toList();

          // 2. حساب الرصيد الافتتاحي
          double openingBalance = 0;
          final pastTransactions = methodFilteredTxs.where((t) => t.createdAt.isBefore(startOfPeriod));
          for (var t in pastTransactions) {
            openingBalance += t.isIncome ? t.amount : -t.amount;
          }

          // 3. معاملات الفترة
          var periodTxs = methodFilteredTxs.where((t) =>
          t.createdAt.isAfter(startOfPeriod.subtract(const Duration(milliseconds: 1))) &&
              t.createdAt.isBefore(endOfPeriod.add(const Duration(milliseconds: 1)))
          ).toList();

          // 4. فلترة بنوع الحركة (وارد بس ولا صادر بس)
          if (type != null) {
            periodTxs = periodTxs.where((t) => t.type == type).toList();
          }

          // ── تجهيز الإكسيل ──
          var excel = Excel.createExcel();

          String accName = method == null ? 'كل الحسابات' : (method == PaymentMethod.cash ? 'الخزينة' : 'البنك');
          String typeName = type == null ? 'يومية' : (type == TransactionType.income ? 'الوارد' : 'المصروفات');
          String sheetName = 'تقرير $typeName ($accName)';

          Sheet sheet = excel[sheetName];
          excel.setDefaultSheet(sheetName);
          sheet.isRTL = true;

          CellStyle headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);
          CellStyle dataStyle = CellStyle(horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center, textWrapping: TextWrapping.WrapText);
          CellStyle boldDataStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center, verticalAlign: VerticalAlign.Center);

          int currentRow = 0;
          void addStyledRow(List<CellValue> values, CellStyle style) {
            sheet.appendRow(values);
            for (int i = 0; i < values.length; i++) {
              sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow)).cellStyle = style;
            }
            currentRow++;
          }

          final dateStr = startDate.isAtSameMomentAs(endDate)
              ? DateFormat('yyyy-MM-dd').format(startDate)
              : '${DateFormat('yyyy-MM-dd').format(startDate)} إلى ${DateFormat('yyyy-MM-dd').format(endDate)}';

          // عنوان التقرير
          sheet.appendRow([TextCellValue('تقرير $typeName - $accName ($dateStr)')]);
          sheet.cell(CellIndex.indexByString("A1")).cellStyle = CellStyle(bold: true, fontSize: 14);
          currentRow += 2;
          sheet.appendRow([TextCellValue('')]);

          // ── مسار 1: يومية شاملة (الشيت المقسوم نصين زي ما كان) ──
          if (type == null) {
            final incomes = periodTxs.where((t) => t.isIncome).toList();
            final expenses = periodTxs.where((t) => !t.isIncome).toList();
            double totalIncome = incomes.fold(0, (sum, t) => sum + t.amount);
            double totalExpense = expenses.fold(0, (sum, t) => sum + t.amount);
            double netBalance = openingBalance + totalIncome - totalExpense;

            sheet.setColumnWidth(0, 45); // الوارد
            sheet.setColumnWidth(1, 15); // قيمته
            sheet.setColumnWidth(2, 45); // الصادر
            sheet.setColumnWidth(3, 15); // قيمته

            addStyledRow([TextCellValue('رصيد افتتاحي'), DoubleCellValue(openingBalance), TextCellValue(''), TextCellValue('')], boldDataStyle);
            addStyledRow([TextCellValue('وارد'), TextCellValue('قيمة'), TextCellValue('صادر'), TextCellValue('القيمة')], headerStyle);

            int maxRows = math.max(incomes.length, expenses.length);
            for (int i = 0; i < maxRows; i++) {
              final inc = i < incomes.length ? incomes[i] : null;
              final exp = i < expenses.length ? expenses[i] : null;

              String incDesc = '';
              if (inc != null) {
                incDesc = inc.categoryDisplayName;
                if (method == null) incDesc += ' [${inc.method == PaymentMethod.cash ? 'خزينة' : 'بنك'}]';
                if (inc.customerName?.isNotEmpty ?? false) incDesc += '\nالعميل: ${inc.customerName}';
                if (inc.notes?.isNotEmpty ?? false) incDesc += '\nملاحظات: ${inc.notes}';
              }

              String expDesc = '';
              if (exp != null) {
                expDesc = exp.categoryDisplayName;
                if (method == null) expDesc += ' [${exp.method == PaymentMethod.cash ? 'خزينة' : 'بنك'}]';
                if (exp.customerName?.isNotEmpty ?? false) expDesc += '\nالعميل: ${exp.customerName}';
                if (exp.notes?.isNotEmpty ?? false) expDesc += '\nملاحظات: ${exp.notes}';
              }

              addStyledRow([
                TextCellValue(incDesc), inc != null ? DoubleCellValue(inc.amount) : TextCellValue(''),
                TextCellValue(expDesc), exp != null ? DoubleCellValue(exp.amount) : TextCellValue('')
              ], dataStyle);
            }

            addStyledRow([TextCellValue('إجمالي وارد'), DoubleCellValue(totalIncome), TextCellValue('إجمالي صادر'), DoubleCellValue(totalExpense)], boldDataStyle);
            addStyledRow([TextCellValue('صافي الرصيد (الختامي)'), DoubleCellValue(netBalance), TextCellValue(''), TextCellValue('')], boldDataStyle);
          }

          // ── مسار 2: تقرير وارد فقط أو صادر فقط (شيت طولي مفصل) ──
          else {
            sheet.setColumnWidth(0, 20); // التاريخ
            sheet.setColumnWidth(1, 45); // البيان
            sheet.setColumnWidth(2, 15); // الحساب
            sheet.setColumnWidth(3, 15); // القيمة

            addStyledRow([TextCellValue('التاريخ'), TextCellValue('البيان'), TextCellValue('الحساب'), TextCellValue('القيمة')], headerStyle);

            double totalAmount = 0;
            for (var t in periodTxs) {
              String desc = t.categoryDisplayName;
              if (t.customerName?.isNotEmpty ?? false) desc += '\nالعميل: ${t.customerName}';
              if (t.notes?.isNotEmpty ?? false) desc += '\nملاحظات: ${t.notes}';

              String acc = t.method == PaymentMethod.cash ? 'خزينة' : 'بنك';

              addStyledRow([
                TextCellValue(DateFormat('yyyy-MM-dd HH:mm').format(t.createdAt)),
                TextCellValue(desc),
                TextCellValue(acc),
                DoubleCellValue(t.amount),
              ], dataStyle);

              totalAmount += t.amount;
            }

            addStyledRow([TextCellValue('الإجمالي'), TextCellValue(''), TextCellValue(''), DoubleCellValue(totalAmount)], boldDataStyle);
          }

          // ── حفظ وتصدير الملف ──
          var fileBytes = excel.encode();
          if (fileBytes != null) {
            String accSuffix = method == null ? 'All' : method.name;
            String typeSuffix = type == null ? 'Ledger' : type.name;
            final fileName = 'Report_${accSuffix}_${typeSuffix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';

            await FileSaver.instance.saveFile(
              name: fileName,
              bytes: Uint8List.fromList(fileBytes),
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
}