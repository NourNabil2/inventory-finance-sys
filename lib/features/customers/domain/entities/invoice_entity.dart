// lib/features/customers/domain/entities/invoice_entity.dart

import 'package:equatable/equatable.dart';
import 'invoice_item_entity.dart';

enum InvoiceStatus { draft, active, completed, canceled }

class InvoiceEntity extends Equatable {
  final String id;
  final String customerId;
  final String? createdBy;
  final String invoiceNumber;
  /// Sum of lineTotalAfterDiscount for all items (before invoice-level discount)
  final double totalAmount;

  /// Invoice-level discount (flat numeric — UI converts % → flat)
  final double discount;

  final InvoiceStatus status;
  final DateTime createdAt;
  final List<InvoiceItemEntity> items;

  /// Optional free-text job name / project reference
  final String? jobName;

  /// Optional production / site / location label
  final String? production;

  const InvoiceEntity({
    required this.id,
    required this.customerId,
    this.createdBy,
    required this.totalAmount,
    this.discount = 0,
    required this.status,
    required this.createdAt,
    required this.invoiceNumber,
    this.items = const [],
    this.jobName,
    this.production,
  });

  // ── Computed ──────────────────────────────────────────────────────────

  double get netTotal => (totalAmount - discount).clamp(0, double.infinity);

  double get discountPercent =>
      totalAmount == 0 ? 0 : (discount / totalAmount) * 100;

  /// Sum of all item gross totals (before any discount)
  double get grossTotal =>
      items.fold(0.0, (s, i) => s + i.grossTotal);

  /// Sum of all item-level discounts
  double get totalItemDiscounts =>
      items.fold(0.0, (s, i) => s + i.itemDiscount);

  /// Alias (subtotal after item discounts, before invoice discount)
  double get subtotal => totalAmount;

  int get itemsOutCount =>
      items.where((i) => i.status == InvoiceItemStatus.out).length;

  int get itemsReturnedCount =>
      items.where((i) => i.status == InvoiceItemStatus.returned).length;

  bool get isActive => status == InvoiceStatus.active;
  bool get isEditable => status == InvoiceStatus.active;
  bool get isFullyReturned =>
      items.isNotEmpty && items.every((i) => i.isReturned);

  @override
  List<Object?> get props =>
      [id, customerId, totalAmount, discount, status, createdAt, items, jobName, production];
}