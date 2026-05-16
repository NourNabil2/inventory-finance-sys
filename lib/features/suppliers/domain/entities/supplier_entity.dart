// lib/features/suppliers/domain/entities/supplier_entity.dart

import 'package:equatable/equatable.dart';

class SupplierEntity extends Equatable {
  final String    id;
  final String    name;
  final String?   phone;
  final DateTime  createdAt;

  /// Money WE owe the supplier (from purchase invoices). مديونية له.
  final double balance;

  /// Money the SUPPLIER owes US (from rental/service invoices). مديونية عليه.
  final double serviceDebt;

  /// Kept for backwards compatibility with old clearing flow.
  final String? linkedCustomerId;

  const SupplierEntity({
    required this.id,
    required this.name,
    this.phone,
    required this.balance,
    this.serviceDebt = 0.0,
    required this.createdAt,
    this.linkedCustomerId,
  });

  // ── Derived ──────────────────────────────────────────────

  bool get hasLinkedCustomer => linkedCustomerId != null;

  /// Positive  → we owe them more than they owe us.
  /// Negative  → they owe us more than we owe them.
  /// Zero      → perfectly settled.
  double get netPosition => balance - serviceDebt;

  bool get isSettled => netPosition == 0;

  // 🚨 هنا المتغيرات اللي كانت عاملة المشكلة 🚨
  /// Maximum amount that can be cleared in one go.
  double get maxClearable => balance < serviceDebt ? balance : serviceDebt;

  bool get canClear => maxClearable > 0;

  // ── Copy ─────────────────────────────────────────────────

  SupplierEntity copyWith({
    String?   id,
    String?   name,
    String?   phone,
    double?   balance,
    double?   serviceDebt,
    DateTime? createdAt,
    String?   linkedCustomerId,
    bool      clearLinkedCustomer = false,
  }) {
    return SupplierEntity(
      id:               id              ?? this.id,
      name:             name            ?? this.name,
      phone:            phone           ?? this.phone,
      balance:          balance         ?? this.balance,
      serviceDebt:      serviceDebt     ?? this.serviceDebt,
      createdAt:        createdAt       ?? this.createdAt,
      linkedCustomerId: clearLinkedCustomer
          ? null
          : linkedCustomerId ?? this.linkedCustomerId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    balance,
    serviceDebt,
    createdAt,
    linkedCustomerId,
  ];
}