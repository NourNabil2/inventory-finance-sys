// lib/features/finance/data/repositories/finance_repository_impl.dart

import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:bungee_manage_sys/features/finance/domain/entities/financial_transaction_entity.dart';
import 'package:bungee_manage_sys/features/finance/domain/repositories/finance_repository.dart';
import 'package:dartz/dartz.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDataSource _remoteDataSource;
  FinanceRepositoryImpl(this._remoteDataSource);

  // ── getTransactions ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<FinancialTransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    PaymentMethod? method,
    TransactionCategory? category,
  }) async {
    try {
      final response = await _remoteDataSource.getTransactions(
        startDate: startDate,
        endDate:   endDate,
        type:      type?.toDbValue,
        method:    method?.toDbValue,
        category:  category?.toDbValue,
      );
      return Right(response.map(_mapToEntity).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── getFinancialSummary ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, FinancialSummaryEntity>> getFinancialSummary() async {
    try {
      final response = await _remoteDataSource.getFinancialSummary();

      final recentTransactions =
      (response['recent_transactions'] as List<dynamic>)
          .map((t) => _mapToEntity(t as Map<String, dynamic>))
          .toList();

      final summary = FinancialSummaryEntity(
        totalCashIncome: (response['cash_income'] as num?)?.toDouble() ?? 0,
        totalCashExpense: (response['cash_expense'] as num?)?.toDouble() ?? 0,
        totalBankIncome: (response['bank_income'] as num?)?.toDouble() ?? 0,
        totalBankExpense: (response['bank_expense'] as num?)?.toDouble() ?? 0,
        cashBalance: (response['cash_balance'] as num?)?.toDouble() ?? 0,
        bankBalance: (response['bank_balance'] as num?)?.toDouble() ?? 0,
        totalBalance: (response['total_balance'] as num?)?.toDouble() ?? 0,
        todayIncome: (response['today_income'] as num?)?.toDouble() ?? 0,
        todayExpense: (response['today_expense'] as num?)?.toDouble() ?? 0,
        weekIncome: (response['week_income'] as num?)?.toDouble() ?? 0,
        weekExpense: (response['week_expense'] as num?)?.toDouble() ?? 0,
        recentTransactions: recentTransactions,
      );

      return Right(summary);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── createTransaction ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, String>> createTransaction({
    required double amount,
    required TransactionType type,
    required PaymentMethod method,
    required TransactionCategory category,
    String? referenceId,
    String? notes,
    DateTime? createdAt,
  }) async {
    try {
      final id = await _remoteDataSource.createTransaction(
        amount:      amount,
        type:        type.toDbValue,
        method:      method.toDbValue,
        category:    category.toDbValue,
        referenceId: referenceId,
        notes:       notes,
        createdAt:   createdAt,
      );
      return Right(id);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── depositToWallet ───────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> depositToWallet({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  }) async {
    try {
      await _remoteDataSource.depositToWallet(
        customerId: customerId,
        amount:     amount,
        method:     method.toDbValue, // 'safe' or 'bank' only
        notes:      notes,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ── getCashBalance ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, double>> getCashBalance() async {
    try {
      return Right(await _remoteDataSource.getCashBalance());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── getBankBalance ────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, double>> getBankBalance() async {
    try {
      return Right(await _remoteDataSource.getBankBalance());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── _mapToEntity ──────────────────────────────────────────────────────────
  FinancialTransactionEntity _mapToEntity(Map<String, dynamic> json) =>
      FinancialTransactionEntity(
        id:          json['id'] as String,
        amount:      (json['amount'] as num).toDouble(),
        type:        _parseType(json['type'] as String),
        method:      _parseMethod(json['method'] as String),
        category:    _parseCategory(json['category'] as String),
        referenceId: json['reference_id'] as String?,
        customerName: json['customers']?['name'] as String?,
        createdBy:   json['created_by']   as String?,
        notes:       json['notes']        as String?,
        createdAt:   DateTime.parse(json['created_at'] as String),
      );

  TransactionType _parseType(String v) => switch (v) {
    'in'  => TransactionType.income,
    'out' => TransactionType.expense,
    _     => TransactionType.expense,
  };

  PaymentMethod _parseMethod(String v) => switch (v) {
    'safe'   => PaymentMethod.cash,
    'bank'   => PaymentMethod.bank,
    'wallet' => PaymentMethod.wallet,
    _        => PaymentMethod.cash,
  };

  TransactionCategory _parseCategory(String v) => switch (v) {
    'client_payment'    => TransactionCategory.rental,
    'invoice_payment'   => TransactionCategory.rental,
    'customer_deposit'  => TransactionCategory.customerDeposit,
    'admin_expense'     => TransactionCategory.adminExpense,
    'operation_expense' => TransactionCategory.operationExpense,
    'general_expense'   => TransactionCategory.generalExpense,
    'supplier_payment'  => TransactionCategory.supplierPayment,
    _                   => TransactionCategory.generalExpense,
  };
}