
// ═══════════════════════════════════════════════════════════════════════
// lib/features/customers/domain/entities/invoice_payment_summary.dart
// ═══════════════════════════════════════════════════════════════════════
import 'package:equatable/equatable.dart';

class InvoicePaymentSummary extends Equatable {
  final double totalDue;
  final double totalPaid;
  final double remaining;
  final bool isFullyPaid;

  const InvoicePaymentSummary({
    required this.totalDue,
    required this.totalPaid,
    required this.remaining,
    required this.isFullyPaid,
  });

  factory InvoicePaymentSummary.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentSummary(
      totalDue: (json['total_due'] as num?)?.toDouble() ?? 0.0,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      remaining: (json['remaining'] as num?)?.toDouble() ?? 0.0,
      isFullyPaid: json['is_fully_paid'] as bool? ?? false,
    );
  }

  double get paymentPercent =>
      totalDue == 0 ? 0 : (totalPaid / totalDue * 100).clamp(0, 100);

  @override
  List<Object?> get props => [totalDue, totalPaid, remaining, isFullyPaid];
}