// lib/features/suppliers/domain/entities/supplier_entity.dart

import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final double balance;
  final DateTime createdAt;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.phone,
    required this.balance,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone, balance, createdAt];
}