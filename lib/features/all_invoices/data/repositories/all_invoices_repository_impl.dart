// lib/features/all_invoices/data/repositories/all_invoices_repository_impl.dart

import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/all_invoices/data/datasources/all_invoices_remote_datasource.dart';
import 'package:bungee_manage_sys/features/all_invoices/data/models/all_invoice_model.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/repositories/all_invoices_repository.dart';
import 'package:dartz/dartz.dart';

class AllInvoicesRepositoryImpl implements AllInvoicesRepository {
  final AllInvoicesRemoteDataSource _dataSource;

  AllInvoicesRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, PaginatedInvoices>> getAllInvoices({
    required InvoiceFilterParams filters,
    required int page,
    int pageSize = 10,
  }) async {
    try {
      final raw = await _dataSource.getAllInvoicesPaginated(
        filters: filters,
        page: page,
        pageSize: pageSize,
      );

      final dataList = raw['data'] as List<Map<String, dynamic>>;
      final totalCount = raw['total_count'] as int;

      final invoices = dataList.map(AllInvoiceModel.fromJson).toList();

      return Right(PaginatedInvoices(
        invoices:    invoices,
        totalCount:  totalCount,
        currentPage: page,
        pageSize:    pageSize,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
