// lib/features/suppliers/domain/entities/service_invoice_item_entity.dart

import 'package:equatable/equatable.dart';

/// A single line item on a Supplier Service Invoice.
/// These are rows from the `invoice_items` table joined with `items`.
class ServiceInvoiceItemEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String itemId;
  final String? itemName;
  final String? itemModel;
  final int qty;
  final int days;
  final double pricePerDay;
  final double itemDiscount;
  final String status;     // 'out' | 'returned'
  final int returnedQty;

  const ServiceInvoiceItemEntity({
    required this.id,
    required this.invoiceId,
    required this.itemId,
    this.itemName,
    this.itemModel,
    required this.qty,
    required this.days,
    required this.pricePerDay,
    this.itemDiscount = 0,
    this.status       = 'out',
    this.returnedQty  = 0,
  });

  double get grossTotal             => qty * days * pricePerDay;
  double get lineTotalAfterDiscount =>
      (grossTotal - itemDiscount).clamp(0, double.infinity);
  double get lineTotal              => lineTotalAfterDiscount;

  int  get remainingQty     => (qty - returnedQty).clamp(0, qty);
  bool get isFullyReturned  => returnedQty >= qty;

  @override
  List<Object?> get props => [
    id, invoiceId, itemId, itemName, itemModel,
    qty, days, pricePerDay, itemDiscount,
    status, returnedQty,
  ];
}