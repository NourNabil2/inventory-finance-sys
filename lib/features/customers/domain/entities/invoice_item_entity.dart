// ─────────────────────────────────────────────────────────────────────────────
// lib/features/customers/domain/entities/invoice_item_entity.dart
// ADD: returnedQty field + computed remainingQty
// ─────────────────────────────────────────────────────────────────────────────

import 'package:equatable/equatable.dart';

enum InvoiceItemStatus { out, returned }

class InvoiceItemEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String itemId;
  final String? itemName;
  final int qty;
  final int days;
  final double pricePerDay;
  final double itemDiscount;
  final bool isSubRented;
  final String? supplierId;
  final double? supplierCost;
  final InvoiceItemStatus status;

  /// How many units have been returned so far (supports partial returns)
  final int returnedQty;
  final int sortOrder;

  const InvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    required this.itemId,
    this.itemName,
    required this.qty,
    required this.days,
    required this.pricePerDay,
    this.itemDiscount = 0,
    this.isSubRented = false,
    this.supplierId,
    this.supplierCost,
    this.status = InvoiceItemStatus.out,
    this.returnedQty = 0,
    this.sortOrder = 0,
  });

  // ── Computed ──────────────────────────────────────────────────────────────

  double get grossTotal => qty * days * pricePerDay;
  double get itemDiscountPercent =>
      grossTotal == 0 ? 0 : (itemDiscount / grossTotal) * 100;
  double get lineTotalAfterDiscount =>
      (grossTotal - itemDiscount).clamp(0, double.infinity);
  double get lineTotal => lineTotalAfterDiscount;

  /// How many units can still be returned
  int get remainingQty => (qty - returnedQty).clamp(0, qty);

  /// True only when ALL qty is returned
  bool get isFullyReturned => returnedQty >= qty;

  /// True when at least some qty returned but not all
  bool get isPartiallyReturned => returnedQty > 0 && returnedQty < qty;

  bool get isReturned => isFullyReturned;
  bool get isOut => returnedQty < qty;

  @override
  List<Object?> get props => [
    id, invoiceId, itemId, itemName,
    qty, days, pricePerDay, itemDiscount,
    isSubRented,
    supplierId,
    supplierCost,
    status,
    returnedQty,
    sortOrder,
  ];
}
