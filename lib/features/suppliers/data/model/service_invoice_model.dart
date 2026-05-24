// lib/features/suppliers/data/model/service_invoice_model.dart

import '../../domain/entities/service_invoice_entity.dart';

class ServiceInvoiceItemModel extends ServiceInvoiceItemEntity {
  const ServiceInvoiceItemModel({
    required super.id,
    required super.invoiceId,
    required super.itemId,
    super.itemName,
    super.itemModel,
    required super.qty,
    required super.days,
    required super.pricePerDay,
    super.itemDiscount = 0,
    super.status       = 'out',
    super.returnedQty  = 0,
  });

  factory ServiceInvoiceItemModel.fromJson(Map<String, dynamic> json) {
    final itemData = json['items'] as Map<String, dynamic>?;
    final returnedQty = (json['returned_qty'] as num?)?.toInt() ?? 0;
    final totalQty    = (json['qty']          as num?)?.toInt() ?? 1;
    final statusStr   = returnedQty >= totalQty ? 'returned' : 'out';

    return ServiceInvoiceItemModel(
      id:           json['id']?.toString()         ?? '',
      invoiceId:    json['invoice_id']?.toString() ?? '',
      itemId:       json['item_id']?.toString()    ?? '',
      itemName:     itemData?['name']?.toString(),
      itemModel:    itemData?['model']?.toString(),
      qty:          totalQty,
      days:         (json['days']          as num?)?.toInt()    ?? 1,
      pricePerDay:  (json['price_per_day'] as num?)?.toDouble() ?? 0,
      itemDiscount: (json['item_discount'] as num?)?.toDouble() ?? 0,
      status:       statusStr,
      returnedQty:  returnedQty,
    );
  }
}

class ServiceInvoiceModel extends ServiceInvoiceEntity {
  const ServiceInvoiceModel({
    required super.id,
    required super.invoiceNumber,
    required super.totalAmount,
    super.discount   = 0.0,
    super.paidAmount = 0.0,
    required super.status,
    super.notes,
    super.jobName,
    super.production,
    required super.createdAt,
    super.items = const [],
  });

  factory ServiceInvoiceModel.fromJson(Map<String, dynamic> json) {
    // ── Status ─────────────────────────────────────────────
    final statusStr = json['status']?.toString() ?? 'unpaid';
    ServiceInvoiceStatus mappedStatus;
    if (statusStr == 'paid' || statusStr == 'completed') {
      mappedStatus = ServiceInvoiceStatus.paid;
    } else if (statusStr == 'partial') {
      mappedStatus = ServiceInvoiceStatus.partial;
    } else if (statusStr == 'canceled') {
      mappedStatus = ServiceInvoiceStatus.canceled;
    } else {
      mappedStatus = ServiceInvoiceStatus.unpaid;
    }

    // ── Items ──────────────────────────────────────────────
    final rawItems = json['invoice_items'] as List? ?? [];
    final items = rawItems
        .map((i) => ServiceInvoiceItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    return ServiceInvoiceModel(
      id:            json['id']?.toString()             ?? '',
      invoiceNumber: json['invoice_number']?.toString() ?? '',
      totalAmount:   (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      discount:      (json['discount']     as num?)?.toDouble() ?? 0.0,
      paidAmount:    (json['paid_amount']  as num?)?.toDouble() ?? 0.0,
      status:        mappedStatus,
      notes:         json['notes']?.toString(),
      jobName:       json['job_name']?.toString(),
      production:    json['production']?.toString(),
      createdAt:     json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      items:         items,
    );
  }
}