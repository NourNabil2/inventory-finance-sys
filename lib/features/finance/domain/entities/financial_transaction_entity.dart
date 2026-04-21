// lib/features/finance/domain/entities/financial_transaction_entity.dart

import 'package:equatable/equatable.dart';

// ── DB value extensions ───────────────────────────────────────────────────────

extension TransactionTypeX on TransactionType {
  String get toDbValue => switch (this) {
    TransactionType.income  => 'in',
    TransactionType.expense => 'out',
  };
}

extension PaymentMethodX on PaymentMethod {
  String get toDbValue => switch (this) {
    PaymentMethod.cash   => 'safe',
    PaymentMethod.bank   => 'bank',
    PaymentMethod.wallet => 'wallet',
  };
}

extension TransactionCategoryX on TransactionCategory {
  String get toDbValue => switch (this) {
    TransactionCategory.rental           => 'client_payment',
    TransactionCategory.customerDeposit  => 'customer_deposit',
    TransactionCategory.adminExpense     => 'admin_expense',
    TransactionCategory.operationExpense => 'operation_expense',
    TransactionCategory.generalExpense   => 'operation_expense',
    TransactionCategory.supplierPayment  => 'supplier_payment',
  };
}

// ── Enums ─────────────────────────────────────────────────────────────────────

enum TransactionType { income, expense }

enum PaymentMethod { cash, bank, wallet }

enum TransactionCategory {
  rental,
  customerDeposit,
  adminExpense,
  operationExpense,
  generalExpense,
  supplierPayment,
}

// ── Entity ────────────────────────────────────────────────────────────────────

class FinancialTransactionEntity extends Equatable {
  final String id;
  final double amount;
  final TransactionType type;
  final PaymentMethod method;
  final TransactionCategory category;
  final String? referenceId;
  final String? createdBy;
  final String? notes;
  final DateTime createdAt;
  final String? customerName;

  const FinancialTransactionEntity(
       {
    required this.id,
    required this.amount,
    required this.type,
    required this.method,
    required this.category,
    this.referenceId,
    this.createdBy,
    this.notes,
    this.customerName,
    required this.createdAt,
  });

  bool get isIncome  => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isCash    => method == PaymentMethod.cash;
  bool get isBank    => method == PaymentMethod.bank;
  bool get isWallet  => method == PaymentMethod.wallet;

  double get signedAmount => isIncome ? amount : -amount;

  String get categoryDisplayName => switch (category) {
    TransactionCategory.rental           => 'إيراد تأجير',
    TransactionCategory.customerDeposit  => 'إيداع رصيد عميل',
    TransactionCategory.adminExpense     => 'مصروفات إدارية',
    TransactionCategory.operationExpense => 'مصروفات تشغيلية',
    TransactionCategory.generalExpense   => 'مصروفات عمومية',
    TransactionCategory.supplierPayment  => 'دفع لمورد',
  };

  String get methodDisplayName => switch (method) {
    PaymentMethod.cash   => 'كاش',
    PaymentMethod.bank   => 'بنك',
    PaymentMethod.wallet => 'رصيد العميل',
  };

  String get typeDisplayName => switch (type) {
    TransactionType.income  => 'وارد',
    TransactionType.expense => 'منصرف',
  };

  FinancialTransactionEntity copyWith({
    String? id,
    double? amount,
    TransactionType? type,
    PaymentMethod? method,
    TransactionCategory? category,
    String? referenceId,
    String? createdBy,
    String? notes,
    DateTime? createdAt,
  }) =>
      FinancialTransactionEntity(
        id:          id          ?? this.id,
        amount:      amount      ?? this.amount,
        type:        type        ?? this.type,
        method:      method      ?? this.method,
        category:    category    ?? this.category,
        referenceId: referenceId ?? this.referenceId,
        createdBy:   createdBy   ?? this.createdBy,
        notes:       notes       ?? this.notes,
        createdAt:   createdAt   ?? this.createdAt,
      );

  @override
  List<Object?> get props =>
      [id, amount, type, method, category, referenceId, createdBy, notes, createdAt];
}

// ── Summary entity ────────────────────────────────────────────────────────────

class FinancialSummaryEntity {
  final double totalCashIncome;
  final double totalCashExpense;
  final double totalBankIncome;
  final double totalBankExpense;
  final double cashBalance;
  final double bankBalance;
  final double totalBalance;

  final double todayIncome;
  final double todayExpense;
  final double weekIncome;
  final double weekExpense;

  final List<FinancialTransactionEntity> recentTransactions;

  FinancialSummaryEntity({
    required this.totalCashIncome,
    required this.totalCashExpense,
    required this.totalBankIncome,
    required this.totalBankExpense,
    required this.cashBalance,
    required this.bankBalance,
    required this.totalBalance,
    required this.todayIncome,
    required this.todayExpense,
    required this.weekIncome,
    required this.weekExpense,
    required this.recentTransactions,
  });
}