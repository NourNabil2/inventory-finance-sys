// lib/features/suppliers/domain/entities/supplier_payment_summary.dart

import 'package:equatable/equatable.dart';

class SupplierPaymentSummary extends Equatable {
  final String invoiceId;
  final double paidAmount;
  final double remaining;
  final double totalAmount;
  final bool isFullyPaid;
  final String status;

  const SupplierPaymentSummary({
    required this.invoiceId,
    required this.paidAmount,
    required this.remaining,
    required this.totalAmount,
    required this.isFullyPaid,
    required this.status,
  });

  factory SupplierPaymentSummary.fromJson(Map<String, dynamic> json) {
    return SupplierPaymentSummary(
      invoiceId:  json['invoice_id']?.toString() ?? '',
      paidAmount: (json['paid_amount'] as num?)?.toDouble() ?? 0,
      remaining:  (json['remaining'] as num?)?.toDouble() ?? 0,
      totalAmount:(json['total_amount'] as num?)?.toDouble() ?? 0,
      isFullyPaid: json['is_fully_paid'] as bool? ?? false,
      status:     json['status']?.toString() ?? 'unpaid',
    );
  }

  @override
  List<Object?> get props =>
      [invoiceId, paidAmount, remaining, totalAmount, isFullyPaid, status];
}