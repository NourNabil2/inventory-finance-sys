// lib/features/finance/presentation/cubit/finance_state.dart

part of 'finance_cubit.dart';

abstract class FinanceState extends Equatable {
  const FinanceState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class FinanceInitial extends FinanceState {}

/// Loading state
class FinanceLoading extends FinanceState {}

/// Processing state (for operations)
class FinanceProcessing extends FinanceState {}

/// Error state
class FinanceError extends FinanceState {
  final String message;

  const FinanceError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Loaded state with financial summary
class FinanceLoaded extends FinanceState {
  final FinancialSummaryEntity summary;

  const FinanceLoaded({required this.summary});

  @override
  List<Object?> get props => [summary];
}

/// Loaded state with transactions list
class FinanceTransactionsLoaded extends FinanceState {
  final List<FinancialTransactionEntity> transactions;

  const FinanceTransactionsLoaded({required this.transactions});

  @override
  List<Object?> get props => [transactions];
}
