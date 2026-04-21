// lib/features/customers/data/models/customer_model.dart

import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';

class CustomerModel extends CustomerEntity {
  const CustomerModel({
    required super.id,
    required super.name,
    super.phone,
    required super.totalPaid,
    required super.totalDebt,
    super.walletBalance = 0,
    required super.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
    id:            json['id'] as String,
    name:          json['name'] as String,
    phone:         json['phone'] as String?,
    totalPaid:     (json['total_paid'] as num?)?.toDouble() ?? 0,
    totalDebt:     (json['total_debt'] as num?)?.toDouble() ?? 0,
    walletBalance: (json['wallet_balance'] as num?)?.toDouble() ?? 0,
    createdAt:     DateTime.parse(json['created_at'] as String),
  );

  factory CustomerModel.fromEntity(CustomerEntity e) => CustomerModel(
    id:            e.id,
    name:          e.name,
    phone:         e.phone,
    totalPaid:     e.totalPaid,
    totalDebt:     e.totalDebt,
    walletBalance: e.walletBalance,
    createdAt:     e.createdAt,
  );

  Map<String, dynamic> toJson({bool includeId = true}) => {
    if (includeId && id.isNotEmpty) 'id': id,
    'name':           name,
    'phone':          phone,
    'total_paid':     totalPaid,
    'total_debt':     totalDebt,
    'wallet_balance': walletBalance,
  };
}