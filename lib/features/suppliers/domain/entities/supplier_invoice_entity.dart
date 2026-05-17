// lib/features/suppliers/domain/entities/supplier_invoice_entity.dart

import 'package:equatable/equatable.dart';

import 'supplier_invoice_item_entity.dart';

export 'supplier_invoice_item_entity.dart';

enum SupplierInvoiceStatus { unpaid, partial, paid, cancelled }

class SupplierInvoiceEntity extends Equatable {
  final String id;
  final String supplierId;
  final double totalAmount;
  final double discount;      // 🆕
  final double paidAmount;
  final SupplierInvoiceStatus status;
  final String? notes;
  final List<SupplierInvoiceItemEntity> items;
  final DateTime createdAt;

  const SupplierInvoiceEntity({
    required this.id,
    required this.supplierId,
    required this.totalAmount,
    this.discount    = 0.0,   // 🆕
    required this.paidAmount,
    required this.status,
    this.notes,
    this.items = const [],
    required this.createdAt,
  });

  double get netAmount  => (totalAmount - discount).clamp(0, double.infinity);
  double get remaining  => (netAmount - paidAmount).clamp(0, double.infinity);
  bool   get isFullyPaid    => paidAmount >= netAmount;
  bool   get isCancelled    => status == SupplierInvoiceStatus.cancelled;
  double get paymentPercent =>
      netAmount == 0 ? 0 : (paidAmount / netAmount * 100).clamp(0, 100);

  @override
  List<Object?> get props =>
      [id, supplierId, totalAmount, discount, paidAmount, status, notes, items, createdAt];
}