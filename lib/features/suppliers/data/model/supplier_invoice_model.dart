// lib/features/suppliers/data/models/supplier_invoice_model.dart

import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import '../../domain/entities/supplier_invoice_item_entity.dart';

class SupplierInvoiceItemModel extends SupplierInvoiceItemEntity {
  const SupplierInvoiceItemModel({
    required super.id, required super.invoiceId, required super.itemName,
    required super.qty, required super.days, required super.pricePerDay,
    super.itemDiscount = 0.0,
  });

  factory SupplierInvoiceItemModel.fromJson(Map<String, dynamic> json) =>
      SupplierInvoiceItemModel(
        id:          json['id']?.toString() ?? '',
        invoiceId:   json['invoice_id']?.toString() ?? '',
        itemName:    json['item_name']?.toString() ?? '',
        qty:         (json['qty'] as num?)?.toInt() ?? 1,
        days:        (json['days'] as num?)?.toInt() ?? 1,
        pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0,
        itemDiscount: (json['item_discount'] as num?)?.toDouble() ?? 0, // 🚨
      );

  Map<String, dynamic> toJson() => {
    'item_name':     itemName,
    'qty':           qty,
    'days':          days,
    'price_per_day': pricePerDay,
    'item_discount': itemDiscount, // 🚨 عشان يتبعت للسيرفر
  };
}

class SupplierInvoiceModel extends SupplierInvoiceEntity {
  const SupplierInvoiceModel({
    required super.id,
    required super.supplierId,
    required super.totalAmount,
    super.discount = 0.0,     // 🆕
    required super.paidAmount,
    required super.status,
    super.notes,
    super.items = const [],
    required super.createdAt,
  });

  factory SupplierInvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['supplier_invoice_items'] as List? ?? [];
    return SupplierInvoiceModel(
      id:          json['id']?.toString() ?? '',
      supplierId:  json['supplier_id']?.toString() ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      discount:    (json['discount']     as num?)?.toDouble() ?? 0,   // 🆕
      paidAmount:  (json['paid_amount']  as num?)?.toDouble() ?? 0,
      status:      _mapStatus(json['status']?.toString() ?? 'unpaid'),
      notes:       json['notes']?.toString(),
      items:       rawItems
          .map((i) => SupplierInvoiceItemModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      createdAt:   json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static SupplierInvoiceStatus _mapStatus(String s) => switch (s) {
    'paid'      => SupplierInvoiceStatus.paid,
    'partial'   => SupplierInvoiceStatus.partial,
    'cancelled' => SupplierInvoiceStatus.cancelled,   // 🆕
    _           => SupplierInvoiceStatus.unpaid,
  };
}

