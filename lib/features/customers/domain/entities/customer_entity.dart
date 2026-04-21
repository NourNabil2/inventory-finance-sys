// lib/features/customers/domain/entities/customer_entity.dart

import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? phone;
  final double totalPaid;
  final double totalDebt;
  final double walletBalance;
  final DateTime createdAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.phone,
    required this.totalPaid,
    required this.totalDebt,
    this.walletBalance = 0,
    required this.createdAt,
  });

  double get totalInvoiced => totalPaid + totalDebt;

  @override
  List<Object?> get props =>
      [id, name, phone, totalPaid, totalDebt, walletBalance, createdAt];
}