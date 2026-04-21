// lib/features/finance/data/datasources/finance_remote_datasource.dart

import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class FinanceRemoteDataSource {
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate, DateTime? endDate, String? type, String? method, String? category,
  });
  Future<Map<String, dynamic>> getFinancialSummary();
  Future<String> createTransaction({
    required double amount, required String type, required String method, required String category,
    String? referenceId, String? customerId, String? notes, // 👈 ضفنا customerId هنا
  });
  Future<void> depositToWallet({
    required String customerId, required double amount, required String method, String? notes,
  });
  Future<double> getCashBalance();
  Future<double> getBankBalance();
}

class FinanceRemoteDataSourceImpl implements FinanceRemoteDataSource {
  final SupabaseClient _supabase;
  FinanceRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<Map<String, dynamic>>> getTransactions({
    DateTime? startDate, DateTime? endDate, String? type, String? method, String? category,
  }) async {
    try {
      var query = _supabase.from('financial_transactions').select('*, customers(name)');
      if (startDate != null) query = query.gte('created_at', startDate.toIso8601String());
      if (endDate   != null) query = query.lte('created_at', endDate.toIso8601String());
      if (type      != null) query = query.eq('type', type);
      if (method    != null) query = query.eq('method', method);
      if (category  != null) query = query.eq('category', category);
      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      final transactions = await _supabase
          .from('financial_transactions')
          .select('amount, type, method, created_at')
          .order('created_at', ascending: false)
          .limit(1000);

      double cashIncome = 0, cashExpense = 0;
      double bankIncome = 0, bankExpense = 0;
      double todayIncome = 0, todayExpense = 0;
      double weekIncome = 0, weekExpense = 0;

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final startOfWeek = startOfToday.subtract(const Duration(days: 7));

      for (final t in transactions) {
        final amount = (t['amount'] as num?)?.toDouble() ?? 0;
        final type = t['type'] as String?;
        final method = t['method'] as String?;
        final createdAt = DateTime.tryParse(t['created_at'] as String? ?? '');

        if (type == 'in') {
          if (method == 'safe') cashIncome += amount;
          else if (method == 'bank') bankIncome += amount;
        } else if (type == 'out') {
          if (method == 'safe') cashExpense += amount;
          else if (method == 'bank') bankExpense += amount;
        }

        if (createdAt != null) {
          if (!createdAt.isBefore(startOfToday)) {
            if (type == 'in') todayIncome += amount;
            else if (type == 'out') todayExpense += amount;
          }
          if (!createdAt.isBefore(startOfWeek)) {
            if (type == 'in') weekIncome += amount;
            else if (type == 'out') weekExpense += amount;
          }
        }
      }

      // 🚨 التعديل هنا: جلب اسم العميل مع آخر الحركات 🚨
      final recent = await _supabase
          .from('financial_transactions')
          .select('*, customers(name)')
          .order('created_at', ascending: false)
          .limit(20);

      return {
        'cash_income': cashIncome, 'cash_expense': cashExpense,
        'bank_income': bankIncome, 'bank_expense': bankExpense,
        'cash_balance': cashIncome - cashExpense, 'bank_balance': bankIncome - bankExpense,
        'total_balance': (cashIncome - cashExpense) + (bankIncome - bankExpense),
        'today_income': todayIncome, 'today_expense': todayExpense,
        'week_income': weekIncome, 'week_expense': weekExpense,
        'recent_transactions': recent,
      };
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<String> createTransaction({
    required double amount, required String type, required String method, required String category,
    String? referenceId, String? customerId, String? notes,
  }) async {
    try {
      final response = await _supabase.from('financial_transactions').insert({
        'amount': amount, 'type': type, 'method': method, 'category': category,
        'reference_id': referenceId, 'customer_id': customerId, // 👈 إرسال الـ ID للداتابيز
        'created_by': _supabase.auth.currentUser?.id, 'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      }).select('id').single();
      return response['id'] as String;
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> depositToWallet({
    required String customerId, required double amount, required String method, String? notes,
  }) async {
    try {
      await _supabase.rpc('deposit_to_customer_wallet', params: {
        'p_customer_id': customerId, 'p_amount': amount, 'p_method': method, 'p_notes': notes,
      });
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<double> getCashBalance() async {
    try {
      final income  = await _supabase.from('financial_transactions').select('amount').eq('type', 'in').eq('method', 'safe');
      final expense = await _supabase.from('financial_transactions').select('amount').eq('type', 'out').eq('method', 'safe');
      return income.fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0)) - expense.fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
    } catch (e, st) { throw ErrorHandler.handleException(e, st); }
  }

  @override
  Future<double> getBankBalance() async {
    try {
      final income  = await _supabase.from('financial_transactions').select('amount').eq('type', 'in').eq('method', 'bank');
      final expense = await _supabase.from('financial_transactions').select('amount').eq('type', 'out').eq('method', 'bank');
      return income.fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0)) - expense.fold<double>(0, (s, t) => s + ((t['amount'] as num?)?.toDouble() ?? 0));
    } catch (e, st) { throw ErrorHandler.handleException(e, st); }
  }
}