// lib/features/all_invoices/data/models/all_invoice_model.dart

import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';

class AllInvoiceModel extends AllInvoiceEntity {
  const AllInvoiceModel({
    required super.id,
    required super.customerId,
    required super.customerName,
    super.customerPhone,
    super.invoiceNumber,
    required super.totalAmount,
    super.discount = 0,
    required super.status,
    required super.createdAt,
    super.items = const [],
    super.totalPaid = 0,
    super.remaining = 0,
  });

  factory AllInvoiceModel.fromJson(Map<String, dynamic> json) {
    final customerData = json['customers'] as Map<String, dynamic>?;

    final totalAmount = (json['total_amount'] as num?)?.toDouble() ?? 0.0;
    final discount    = (json['discount']      as num?)?.toDouble() ?? 0.0;

    // totalPaid and remaining come from the datasource's pre-computed enrichment
    // keys (_total_paid, _remaining). netTotal is a getter on the entity
    // (totalAmount - discount) so we do NOT pass it to the constructor.
    final totalPaid = (json['_total_paid'] as num?)?.toDouble() ?? 0.0;

    // Prefer the server-enriched value; fall back to computing it locally
    // so the tile always shows the correct figure even if the key is missing.
    final netTotal  = (totalAmount - discount).clamp(0.0, double.infinity);
    final remaining = (json['_remaining'] as num?)?.toDouble()
        ?? (netTotal - totalPaid).clamp(0.0, double.infinity);

    return AllInvoiceModel(
      id:            json['id']?.toString() ?? '',
      customerId:    json['customer_id']?.toString() ?? '',
      customerName:  customerData?['name']?.toString() ?? '—',
      customerPhone: customerData?['phone']?.toString(),
      invoiceNumber: json['invoice_number']?.toString(),
      totalAmount:   totalAmount,
      discount:      discount,
      totalPaid:     totalPaid,
      remaining:     remaining,
      status:        _mapStatus(json['status']?.toString() ?? 'draft'),
      createdAt:     json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  static InvoiceStatus _mapStatus(String s) => switch (s) {
    'active'    => InvoiceStatus.active,
    'completed' => InvoiceStatus.completed,
    'canceled'  => InvoiceStatus.canceled,
    _           => InvoiceStatus.draft,
  };
}