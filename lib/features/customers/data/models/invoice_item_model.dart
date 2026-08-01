// lib/features/customers/data/models/invoice_item_model.dart
// PATCH — add returnedQty to fromJson

import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';

class InvoiceItemModel extends InvoiceItemEntity {
  const InvoiceItemModel({
    required super.id,
    required super.invoiceId,
    required super.itemId,
    super.itemName,
    required super.qty,
    required super.days,
    required super.pricePerDay,
    super.itemDiscount = 0,
    super.isSubRented = false,
    super.supplierId,
    super.supplierCost = 0,
    super.status = InvoiceItemStatus.out,
    super.returnedQty = 0,
    super.sortOrder = 0,
  });

  factory InvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final itemData = json['items'] as Map<String, dynamic>?;
    final name = itemData?['name']?.toString();

    final rawStatus = json['status']?.toString() ?? 'out';
    final returnedQty = (json['returned_qty'] as num?)?.toInt() ?? 0;
    final totalQty = (json['qty'] as num?)?.toInt() ?? 1;

    // Derive status from returned_qty for accuracy
    final status = returnedQty >= totalQty
        ? InvoiceItemStatus.returned
        : InvoiceItemStatus.out;

    return InvoiceItemModel(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoice_id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      itemName: name ?? json['item_name']?.toString(),
      qty: totalQty,
      days: (json['days'] as num?)?.toInt() ?? 1,
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      itemDiscount: (json['item_discount'] as num?)?.toDouble() ?? 0.0,
      isSubRented: json['is_sub_rented'] as bool? ?? false,
      supplierId: json['supplier_id']?.toString(),
      supplierCost: (json['supplier_cost'] as num?)?.toDouble() ?? 0.0,
      status: status,
      returnedQty: returnedQty,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  factory InvoiceItemModel.fromEntity(InvoiceItemEntity entity) =>
      InvoiceItemModel(
        id: entity.id,
        invoiceId: entity.invoiceId,
        itemId: entity.itemId,
        itemName: entity.itemName,
        qty: entity.qty,
        days: entity.days,
        pricePerDay: entity.pricePerDay,
        itemDiscount: entity.itemDiscount,
        isSubRented: entity.isSubRented,
        supplierId: entity.supplierId,
        supplierCost: entity.supplierCost,
        status: entity.status,
        returnedQty: entity.returnedQty,
        sortOrder: entity.sortOrder,
      );

  Map<String, dynamic> toJson() => {
    'invoice_id': invoiceId,
    'item_id': itemId,
    'qty': qty,
    'days': days,
    'price_per_day': pricePerDay,
    'item_discount': itemDiscount,
    'is_sub_rented': isSubRented,
    'supplier_id': supplierId,
    'supplier_cost': supplierCost,
    'status': status == InvoiceItemStatus.returned ? 'returned' : 'out',
    'returned_qty': returnedQty,
    'sort_order': sortOrder,
  };

  static InvoiceItemStatus _mapStatus(String s) =>
      s == 'returned' ? InvoiceItemStatus.returned : InvoiceItemStatus.out;
}