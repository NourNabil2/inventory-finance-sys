// lib/features/finance/domain/repositories/finance_repository.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/finance/domain/entities/financial_transaction_entity.dart';
import 'package:dartz/dartz.dart';

abstract class FinanceRepository {
  Future<Either<Failure, List<FinancialTransactionEntity>>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    PaymentMethod? method,
    TransactionCategory? category,
  });

  Future<Either<Failure, FinancialSummaryEntity>> getFinancialSummary();

  Future<Either<Failure, String>> createTransaction({
    required double amount,
    required TransactionType type,
    required PaymentMethod method,
    required TransactionCategory category,
    String? referenceId,
    String? notes,
    DateTime? createdAt,
  });

  /// Deposits cash into the safe/bank AND credits the customer's wallet.
  /// [method] must be cash or bank — never wallet.
  Future<Either<Failure, void>> depositToWallet({
    required String customerId,
    required double amount,
    required PaymentMethod method,
    String? notes,
  });

  Future<Either<Failure, double>> getCashBalance();
  Future<Either<Failure, double>> getBankBalance();
}