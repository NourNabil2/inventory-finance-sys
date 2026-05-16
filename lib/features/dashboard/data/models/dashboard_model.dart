// lib/features/dashboard/data/models/dashboard_model.dart

import 'package:bungee_manage_sys/features/dashboard/domain/entities/dashboard_entity.dart';

// ─── Dashboard Model ──────────────────────────────────────────────────────────

class DashboardModel extends DashboardEntity {
  const DashboardModel({
    required super.totalRevenue,
    required super.previousMonthRevenue,
    required super.activeRentals,
    required super.pendingPayments,
    required super.pendingInvoicesCount,
    required super.customerDebts,
    required super.debtorsCount,
    required super.supplierDebts,
    required super.monthlyRevenues,
    required super.totalCollectedPercent,
    required super.totalDebtPercent,
    required super.recentInvoices,
  });

  /// نبني الـ model من نتائج الـ queries
  factory DashboardModel.fromRaw({
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> activeInvoices,
    required List<Map<String, dynamic>> customers,
    required List<Map<String, dynamic>> recentInvoicesRaw,
    required List<Map<String, dynamic>> supplierDebtsRaw,
    required List<Map<String, dynamic>> monthlyRaw,
    required double previousMonthRevenue,
  }) {
    // ── إجمالي الإيرادات ─────────────────────────────────────
    final totalRevenue = transactions.fold<double>(
      0,
          (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0),
    );

    // ── التأجيرات النشطة ──────────────────────────────────────
    final activeRentals = activeInvoices.length;

    // ── المدفوعات المعلقة (مجموع الفواتير النشطة) ─────────────
    final pendingPayments = activeInvoices.fold<double>(
      0,
          (sum, inv) => sum + ((inv['total_amount'] as num?)?.toDouble() ?? 0),
    );

    // ── ديون العملاء ──────────────────────────────────────────
    final customerDebts = customers.fold<double>(
      0,
          (sum, c) => sum + ((c['total_debt'] as num?)?.toDouble() ?? 0),
    );
    final totalPaid = customers.fold<double>(
      0,
          (sum, c) => sum + ((c['total_paid'] as num?)?.toDouble() ?? 0),
    );
    final debtorsCount = customers.where(
          (c) => ((c['total_debt'] as num?)?.toDouble() ?? 0) > 0,
    ).length;

    // ── ديون الموردين (المبالغ المستحقة علينا) 🆕 ────────────
    final supplierDebts = supplierDebtsRaw.fold<double>(
      0,
          (sum, inv) {
        final totalAmount = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
        final paidAmount  = (inv['paid_amount']  as num?)?.toDouble() ?? 0.0;
        return sum + (totalAmount - paidAmount); // الرصيد المتبقي
      },
    );

    // ── نسب الديون vs المحصّل ─────────────────────────────────
    final grandTotal = totalPaid + customerDebts;
    final collectedPercent = grandTotal > 0
        ? (totalPaid / grandTotal * 100).roundToDouble()
        : 0.0;
    final debtPercent = grandTotal > 0
        ? (customerDebts / grandTotal * 100).roundToDouble()
        : 0.0;

    // ── الإيرادات الشهرية ──────────────────────────────────────
    final monthlyRevenues = List.generate(6, (i) {
      final found = monthlyRaw.where((m) => (m['month'] as num).toInt() == i + 1);
      return found.isNotEmpty
          ? (found.first['total'] as num).toDouble()
          : 0.0;
    });

    // ── أحدث الفواتير ───────────────────────────────
    final recentInvoices = recentInvoicesRaw.map((inv) {
      // حساب الصافي
      final totalAmount = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
      final discount = (inv['discount'] as num?)?.toDouble() ?? 0.0;
      final netTotal = totalAmount - discount;

      // جلب اسم العميل (لأننا عاملين Join مع جدول العملاء)
      String cName = 'غير معروف';
      if (inv['customers'] != null) {
        cName = inv['customers']['name']?.toString() ?? 'غير معروف';
      }

      // السيريال (لو فاضي بياخد أول 8 حروف من الآي دي كحماية)
      final invoiceNumber = inv['invoice_number']?.toString() ??
          inv['id'].toString().substring(0, 8).toUpperCase();

      return RecentInvoiceEntity(
        id: inv['id'].toString(),
        invoiceNumber: invoiceNumber,
        customerName: cName,
        netTotal: netTotal,
        status: inv['status']?.toString() ?? 'draft',
        createdAt: DateTime.parse(inv['created_at']),
      );
    }).toList();

    return DashboardModel(
      totalRevenue: totalRevenue,
      previousMonthRevenue: previousMonthRevenue,
      activeRentals: activeRentals,
      pendingPayments: pendingPayments,
      pendingInvoicesCount: activeRentals,
      customerDebts: customerDebts,
      debtorsCount: debtorsCount,
      supplierDebts: supplierDebts,
      monthlyRevenues: monthlyRevenues,
      totalCollectedPercent: collectedPercent,
      totalDebtPercent: debtPercent,
      recentInvoices: recentInvoices,
    );
  }
}