// lib/features/suppliers/domain/entities/supplier_invoice_item_entity.dart

import 'package:equatable/equatable.dart';

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

  // حساب إجمالي السطر أوتوماتيكياً
  double get lineTotal => qty * days * pricePerDay;

  @override
  List<Object?> get props => [id, invoiceId, itemName, qty, days, pricePerDay];
}