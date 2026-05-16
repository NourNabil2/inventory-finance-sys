// lib/features/suppliers/domain/entities/clearing_result.dart

import 'package:equatable/equatable.dart';

enum ClearingType { offset, cashToSupplier, cashFromSupplier, mixed }

class ClearingResult extends Equatable {
  final double clearedAmount;
  final double offsetAmount;
  final double cashAmount;
  final ClearingType clearingType;
  final double supplierNewBalance;
  final double supplierNewDebt;
  final String supplierName;

  // legacy
  final double? customerNewDebt;
  final String? customerName;

  const ClearingResult({
    required this.clearedAmount,
    required this.offsetAmount,
    required this.cashAmount,
    required this.clearingType,
    required this.supplierNewBalance,
    required this.supplierNewDebt,
    required this.supplierName,
    this.customerNewDebt,
    this.customerName,
  });

  factory ClearingResult.fromJson(Map<String, dynamic> json) {
    ClearingType ct;
    switch (json['clearing_type']?.toString() ?? 'offset') {
      case 'cash_to_supplier':   ct = ClearingType.cashToSupplier;   break;
      case 'cash_from_supplier': ct = ClearingType.cashFromSupplier; break;
      case 'mixed':              ct = ClearingType.mixed;             break;
      default:                   ct = ClearingType.offset;
    }
    return ClearingResult(
      clearedAmount:      (json['cleared_amount']        as num?)?.toDouble() ?? 0,
      offsetAmount:       (json['offset_amount']         as num?)?.toDouble() ?? 0,
      cashAmount:         (json['cash_amount']           as num?)?.toDouble() ?? 0,
      clearingType:       ct,
      supplierNewBalance: (json['supplier_new_balance']  as num?)?.toDouble() ?? 0,
      supplierNewDebt:    (json['supplier_new_debt']     as num?)?.toDouble() ?? 0,
      supplierName:        json['supplier_name']?.toString() ?? '',
      customerNewDebt:    (json['customer_new_debt']     as num?)?.toDouble(),
      customerName:        json['customer_name']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
    clearedAmount, offsetAmount, cashAmount, clearingType,
    supplierNewBalance, supplierNewDebt, supplierName,
    customerNewDebt, customerName,
  ];
}