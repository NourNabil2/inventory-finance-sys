// lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart

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

      // ── 1. 🚨 التعديل: إجمالي الإيرادات المعتمدة فقط (معزول عن دفعات الـ Drafts الوهمية) 🚨
      final transactionsRes = await _supabase
          .from('valid_financial_transactions') // 👈 قراءة من الـ View المعزول ماليًا
          .select('amount')
          .eq('type', 'in');

      // ── 2. حساب الفواتير المعتمدة ماليًا (نشطة + مكتملة) وعزل المسودات
      final activeInvoicesRes = await _supabase
          .from('invoices')
          .select('id, total_amount, discount, status')
          .inFilter('status', ['active', 'completed']);

      // ── 3. ديون وأرصدة العملاء الحقيقية المزامنة مع المحرك المالي
      final customersRes = await _supabase
          .from('customers')
          .select('total_paid, total_debt');

      // ── 4. أحدث 5 فواتير معتمدة ونشطة (عزل المسودات)
      final recentInvoicesRes = await _supabase
          .from('invoices')
          .select('id, invoice_number, total_amount, discount, status, created_at, customers(name), suppliers(name)')
          .neq('status', 'draft')
          .order('created_at', ascending: false)
          .limit(5);

      // ── 5. 🚨 التعديل: الإيرادات الشهرية الحقيقية (السنة الحالية) من الـ View 🚨
      final monthlyRes = await _supabase
          .from('valid_financial_transactions') // 👈 قراءة من الـ View المعزول ماليًا
          .select('amount, created_at')
          .eq('type', 'in')
          .gte('created_at', yearStart);

      // ── 6. 🚨 التعديل: إيرادات الشهر الماضي الحقيقية من الـ View 🚨
      final previousMonthRes = await _supabase
          .from('valid_financial_transactions') // 👈 قراءة من الـ View المعزول ماليًا
          .select('amount')
          .eq('type', 'in')
          .gte('created_at', prevMonthStart)
          .lt('created_at', prevMonthEnd);

      // ── 7. ديون الموردين (الفواتير غير المدفوعة بالكامل)
      final supplierDebtsRes = await _supabase
          .from('supplier_invoices')
          .select('total_amount, discount, paid_amount')
          .neq('status', 'paid');

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