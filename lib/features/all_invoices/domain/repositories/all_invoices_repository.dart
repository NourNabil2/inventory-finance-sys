// lib/features/all_invoices/domain/repositories/all_invoices_repository.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:dartz/dartz.dart';

abstract class AllInvoicesRepository {
  /// Fetches a paginated list of all invoices with optional filters.
  ///
  /// [filters] - Filter parameters (date range, status, payment status)
  /// [page]    - 1-based page number
  /// [pageSize]- Number of items per page (default 10)
  Future<Either<Failure, PaginatedInvoices>> getAllInvoices({
    required InvoiceFilterParams filters,
    required int page,
    int pageSize = 10,
  });
}
