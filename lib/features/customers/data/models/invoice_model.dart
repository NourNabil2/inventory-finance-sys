// lib/features/customers/data/models/invoice_model.dart

import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'invoice_item_model.dart';

class InvoiceModel extends InvoiceEntity {
  const InvoiceModel({
    required super.id,
    required super.customerId,
    super.createdBy,
    required super.totalAmount,
    super.discount = 0,
    required super.status,
    required super.createdAt,
    required super.invoiceNumber,
    super.items = const [],
    super.jobName,
    super.production,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['invoice_items'] as List? ?? [];

    return InvoiceModel(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id']?.toString() ?? '',
      createdBy: json['created_by']?.toString(),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      status: _mapStatus(json['status']?.toString() ?? 'draft'),
      invoiceNumber: json['invoice_number'] ?? json['id'].toString().substring(0, 8).toUpperCase(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      items: (rawItems
          .map((i) => InvoiceItemModel.fromJson(i as Map<String, dynamic>))
          .toList())..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      jobName: json['job_name']?.toString(),
      production: json['production']?.toString(),
    );
  }
  factory InvoiceModel.fromEntity(InvoiceEntity entity) => InvoiceModel(
    id: entity.id,
    customerId: entity.customerId,
    createdBy: entity.createdBy,
    totalAmount: entity.totalAmount,
    discount: entity.discount,
    status: entity.status,
    invoiceNumber: entity.invoiceNumber,
    createdAt: entity.createdAt,
    items: entity.items,
    jobName: entity.jobName,
    production: entity.production,
  );

  Map<String, dynamic> toJson() => {
    'customer_id': customerId,
    'created_by': createdBy,
    'total_amount': totalAmount,
    'discount': discount,
    'status': _statusToString(status),
    'created_at': createdAt.toIso8601String(),
    if (jobName != null) 'job_name': jobName,
    if (production != null) 'production': production,
  };

  static InvoiceStatus _mapStatus(String s) => switch (s) {
    'active' => InvoiceStatus.active,
    'completed' => InvoiceStatus.completed,
    'canceled' => InvoiceStatus.canceled,
    _ => InvoiceStatus.draft,
  };

  static String _statusToString(InvoiceStatus s) => switch (s) {
    InvoiceStatus.active => 'active',
    InvoiceStatus.completed => 'completed',
    InvoiceStatus.canceled => 'canceled',
    InvoiceStatus.draft => 'draft',
  };
}