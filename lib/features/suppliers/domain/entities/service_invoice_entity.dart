// lib/features/suppliers/domain/entities/service_invoice_entity.dart

import 'package:equatable/equatable.dart';

import 'service_invoice_item_entity.dart';

export 'service_invoice_item_entity.dart';

enum ServiceInvoiceStatus { unpaid, partial, paid, canceled }

class ServiceInvoiceEntity extends Equatable {
  final String id;
  final String invoiceNumber;
  final double totalAmount;
  final double discount;
  final double paidAmount;
  final ServiceInvoiceStatus status;
  final String? notes;
  final String? jobName;
  final String? production;
  final DateTime createdAt;
  final List<ServiceInvoiceItemEntity> items;

  const ServiceInvoiceEntity({
    required this.id,
    required this.invoiceNumber,
    required this.totalAmount,
    this.discount   = 0.0,
    this.paidAmount = 0.0,
    required this.status,
    this.notes,
    this.jobName,
    this.production,
    required this.createdAt,
    this.items = const [],
  });

  double get netTotal =>
      (totalAmount - discount).clamp(0, double.infinity);
  double get remaining =>
      (netTotal - paidAmount).clamp(0, double.infinity);
  bool get isFullyPaid => paidAmount >= netTotal;
  double get paymentPercent =>
      netTotal == 0 ? 100.0 : ((paidAmount / netTotal) * 100).clamp(0, 100);

  @override
  List<Object?> get props => [
    id, invoiceNumber, totalAmount, discount, paidAmount,
    status, notes, jobName, production, createdAt, items,
  ];
}