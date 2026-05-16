// lib/features/suppliers/data/models/supplier_model.dart

import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';

class SupplierModel extends SupplierEntity {
  const SupplierModel({
    required super.id,
    required super.name,
    super.phone,
    required super.balance,
    super.serviceDebt = 0,
    required super.createdAt,
    super.linkedCustomerId,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
    id:               json['id'] as String,
    name:             json['name'] as String,
    phone:            json['phone'] as String?,
    balance:          (json['balance'] as num?)?.toDouble() ?? 0,
    serviceDebt:      (json['service_debt'] as num?)?.toDouble() ?? 0,
    createdAt:        DateTime.parse(json['created_at'] as String),
    linkedCustomerId: json['linked_customer_id'] as String?,
  );

  factory SupplierModel.fromEntity(SupplierEntity e) => SupplierModel(
    id:               e.id,
    name:             e.name,
    phone:            e.phone,
    balance:          e.balance,
    serviceDebt:      e.serviceDebt,
    createdAt:        e.createdAt,
    linkedCustomerId: e.linkedCustomerId,
  );

  Map<String, dynamic> toJson({bool includeId = true}) => {
    if (includeId && id.isNotEmpty) 'id': id,
    'name':    name,
    'phone':   phone,
    'balance': balance,
  };
}