import 'package:equatable/equatable.dart';

class RecentInvoiceEntity {
  final String id;
  final String invoiceNumber;
  final String customerName;
  final double netTotal;
  final String status;
  final DateTime createdAt;

  RecentInvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.customerName,
    required this.netTotal,
    required this.status,
    required this.createdAt,
  });
}

class DashboardEntity extends Equatable {
  final double totalRevenue;
  final double previousMonthRevenue;
  final int activeRentals;
  final double pendingPayments;
  final int pendingInvoicesCount;
  final double customerDebts;
  final int debtorsCount;
  final List<double> monthlyRevenues;
  final double totalCollectedPercent;
  final double totalDebtPercent;
  // 🚨 التعديل هنا: غيرنا الاسم لـ recentInvoices بدل topCameras
  final List<RecentInvoiceEntity> recentInvoices;

  const DashboardEntity({
    required this.totalRevenue,
    required this.previousMonthRevenue,
    required this.activeRentals,
    required this.pendingPayments,
    required this.pendingInvoicesCount,
    required this.customerDebts,
    required this.debtorsCount,
    required this.monthlyRevenues,
    required this.totalCollectedPercent,
    required this.totalDebtPercent,
    required this.recentInvoices, // 🚨 التعديل هنا
  });

  /// Calculate revenue growth percentage from previous month
  double get revenueGrowthPercent {
    if (previousMonthRevenue == 0) return 0.0;
    return ((totalRevenue - previousMonthRevenue) / previousMonthRevenue * 100);
  }

  @override
  List<Object?> get props => [
    totalRevenue,
    previousMonthRevenue,
    activeRentals,
    pendingPayments,
    pendingInvoicesCount,
    customerDebts,
    debtorsCount,
    monthlyRevenues,
    totalCollectedPercent,
    totalDebtPercent,
    recentInvoices, // 🚨 التعديل هنا
  ];
}