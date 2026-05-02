// lib/features/all_invoices/presentation/cubit/all_invoices_state.dart

part of 'all_invoices_cubit.dart';

abstract class AllInvoicesState extends Equatable {
  const AllInvoicesState();

  @override
  List<Object?> get props => [];
}

class AllInvoicesInitial extends AllInvoicesState {}

class AllInvoicesLoading extends AllInvoicesState {}

/// Loading more pages while keeping the current list visible
class AllInvoicesPaginating extends AllInvoicesState {
  final List<AllInvoiceEntity> currentInvoices;
  final int currentPage;
  final int totalCount;
  final InvoiceFilterParams filters;

  const AllInvoicesPaginating({
    required this.currentInvoices,
    required this.currentPage,
    required this.totalCount,
    required this.filters,
  });

  @override
  List<Object?> get props =>
      [currentInvoices, currentPage, totalCount, filters];
}

class AllInvoicesLoaded extends AllInvoicesState {
  final List<AllInvoiceEntity> invoices;
  final int totalCount;
  final int currentPage;
  final int pageSize;
  final InvoiceFilterParams filters;

  const AllInvoicesLoaded({
    required this.invoices,
    required this.totalCount,
    required this.currentPage,
    required this.pageSize,
    required this.filters,
  });

  bool get hasNextPage => (currentPage * pageSize) < totalCount;
  bool get hasPreviousPage => currentPage > 1;
  int get totalPages => totalCount == 0 ? 1 : (totalCount / pageSize).ceil();

  AllInvoicesLoaded copyWith({
    List<AllInvoiceEntity>? invoices,
    int? totalCount,
    int? currentPage,
    int? pageSize,
    InvoiceFilterParams? filters,
  }) {
    return AllInvoicesLoaded(
      invoices:    invoices ?? this.invoices,
      totalCount:  totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      pageSize:    pageSize ?? this.pageSize,
      filters:     filters ?? this.filters,
    );
  }

  @override
  List<Object?> get props =>
      [invoices, totalCount, currentPage, pageSize, filters];
}

class AllInvoicesError extends AllInvoicesState {
  final String message;

  const AllInvoicesError(this.message);

  @override
  List<Object?> get props => [message];
}
