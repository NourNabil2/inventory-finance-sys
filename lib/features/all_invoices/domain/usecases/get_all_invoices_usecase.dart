// lib/features/all_invoices/domain/usecases/get_all_invoices_usecase.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/core/usecases/usecase.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/repositories/all_invoices_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class GetAllInvoicesUseCase
    implements UseCase<PaginatedInvoices, GetAllInvoicesParams> {
  final AllInvoicesRepository _repository;

  GetAllInvoicesUseCase(this._repository);

  @override
  Future<Either<Failure, PaginatedInvoices>> call(
      GetAllInvoicesParams params) async {
    // Basic validation
    if (params.filters.startDate != null &&
        params.filters.endDate != null &&
        params.filters.startDate!.isAfter(params.filters.endDate!)) {
      return Left(
          ValidationFailure('Start date must be before or equal to end date'));
    }

    if (params.page < 1) {
      return Left(ValidationFailure('Page number must be at least 1'));
    }

    return _repository.getAllInvoices(
      filters: params.filters,
      page: params.page,
      pageSize: params.pageSize,
    );
  }
}

class GetAllInvoicesParams extends Equatable {
  final InvoiceFilterParams filters;
  final int page;
  final int pageSize;

  const GetAllInvoicesParams({
    required this.filters,
    required this.page,
    this.pageSize = 10,
  });

  @override
  List<Object?> get props => [filters, page, pageSize];
}
