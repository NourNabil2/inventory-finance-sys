// lib/features/suppliers/domain/entities/supplier_invoice_entity.dart

import 'package:equatable/equatable.dart';

enum SupplierInvoiceStatus { unpaid, partial, paid }

class SupplierInvoiceEntity extends Equatable {
  final String id;
  final String supplierId;
  final double totalAmount;
  final double paidAmount;
  final SupplierInvoiceStatus status;
  final String? notes;
  final List<SupplierInvoiceItemEntity> items;
  final DateTime createdAt;

  const SupplierInvoiceEntity({
    required this.id,
    required this.supplierId,
    required this.totalAmount,
    required this.paidAmount,
    required this.status,
    this.notes,
    this.items = const [],
    required this.createdAt,
  });

  double get remaining => (totalAmount - paidAmount).clamp(0, double.infinity);
  bool get isFullyPaid => paidAmount >= totalAmount;
  double get paymentPercent =>
      totalAmount == 0 ? 0 : (paidAmount / totalAmount * 100).clamp(0, 100);

  @override
  List<Object?> get props =>
      [id, supplierId, totalAmount, paidAmount, status, notes, items, createdAt];
}

class SupplierInvoiceItemEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String itemName;
  final int qty;
  final int days;
  final double pricePerDay;

  const SupplierInvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    required this.itemName,
    required this.qty,
    required this.days,
    required this.pricePerDay,
  });

  double get lineTotal => qty * days * pricePerDay;

  @override
  List<Object?> get props =>
      [id, invoiceId, itemName, qty, days, pricePerDay];
}