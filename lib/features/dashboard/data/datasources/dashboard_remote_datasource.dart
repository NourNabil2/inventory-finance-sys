import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DashboardRemoteDataSource {
  Future<Map<String, dynamic>> getDashboardData();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  final SupabaseClient _supabase;

  DashboardRemoteDataSourceImpl(this._supabase);

  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final now = DateTime.now();
      final yearStart = DateTime(now.year, 1, 1).toIso8601String();

      final firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
      final lastDayOfPreviousMonth = firstDayOfCurrentMonth.subtract(const Duration(days: 1));
      final firstDayOfPreviousMonth = DateTime(lastDayOfPreviousMonth.year, lastDayOfPreviousMonth.month, 1);

      final prevMonthStart = firstDayOfPreviousMonth.toIso8601String();
      final prevMonthEnd = lastDayOfPreviousMonth.add(const Duration(days: 1)).toIso8601String();

      // ── 1. إجمالي الإيرادات (كل المدفوعات الواردة) ───────────
      final transactionsRes = await _supabase
          .from('financial_transactions')
          .select('amount')
          .eq('type', 'in');

      // ── 2. الفواتير النشطة (تأجيرات نشطة + مبالغ معلقة) ──────
      final activeInvoicesRes = await _supabase
          .from('invoices')
          .select('id, total_amount, discount')
          .eq('status', 'active');

      // ── 3. ديون وأرصدة العملاء ───────────────────────────────
      final customersRes = await _supabase
          .from('customers')
          .select('total_paid, total_debt');

      // ── 4. أحدث 5 فواتير (البديل للكاميرات) 🚨 ────────────────
      final recentInvoicesRes = await _supabase
          .from('invoices')
          .select('id, invoice_number, total_amount, discount, status, created_at, customers(name)')
          .order('created_at', ascending: false) // الترتيب من الأحدث للأقدم
          .limit(5);

      // ── 5. الإيرادات الشهرية (السنة الحالية) ─────────────────
      final monthlyRes = await _supabase
          .from('financial_transactions')
          .select('amount, created_at')
          .eq('type', 'in')
          .gte('created_at', yearStart);

      // ── 6. إيرادات الشهر الماضي (لحساب نسبة النمو) ────────────
      final previousMonthRes = await _supabase
          .from('financial_transactions')
          .select('amount')
          .eq('type', 'in')
          .gte('created_at', prevMonthStart)
          .lt('created_at', prevMonthEnd);

      // ── 7. ديون الموردين (الفواتير غير المدفوعة بالكامل) ────
      final supplierDebtsRes = await _supabase
          .from('supplier_invoices')
          .select('total_amount, paid_amount')
          .neq('status', 'paid'); // كل الفواتير اللي مش مدفوعة بالكامل

      // ── تجميع الإيرادات الشهرية يدوياً ───────────────────────
      final monthlyRevenues = _aggregateMonthly(
        List<Map<String, dynamic>>.from(monthlyRes),
      );

      final previousMonthRevenue = _calculatePreviousMonthRevenue(
        List<Map<String, dynamic>>.from(previousMonthRes),
      );

      return {
        'transactions': List<Map<String, dynamic>>.from(transactionsRes),
        'activeInvoices': List<Map<String, dynamic>>.from(activeInvoicesRes),
        'customers': List<Map<String, dynamic>>.from(customersRes),
        'recentInvoices': List<Map<String, dynamic>>.from(recentInvoicesRes),
        'supplierDebts': List<Map<String, dynamic>>.from(supplierDebtsRes),
        'monthlyRevenues': monthlyRevenues,
        'previousMonthRevenue': previousMonthRevenue,
      };
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  double _calculatePreviousMonthRevenue(List<Map<String, dynamic>> transactions) {
    return transactions.fold<double>(
      0,
          (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0),
    );
  }

  List<Map<String, dynamic>> _aggregateMonthly(List<Map<String, dynamic>> transactions) {
    final Map<int, double> monthly = {};
    for (final t in transactions) {
      final dateStr = t['created_at'] as String?;
      if (dateStr == null) continue;
      final month = DateTime.parse(dateStr).month;
      monthly[month] = (monthly[month] ?? 0) + ((t['amount'] as num?)?.toDouble() ?? 0);
    }
    return monthly.entries.map((e) => {'month': e.key, 'total': e.value}).toList();
  }
}