import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/customers/data/datasources/customers_remote_datasource.dart';
import 'package:bungee_manage_sys/features/customers/data/models/customer_model.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/customers_repository.dart';
import 'package:dartz/dartz.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource _dataSource;

  CustomersRepositoryImpl(this._dataSource);

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers() async {
    try {
      final raw = await _dataSource.getCustomers();
      return Right(raw.map(CustomerModel.fromJson).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Failure catch (f) {
      return Left(f);
    }
  }

  @override
  Future<Either<Failure, void>> saveCustomer(CustomerEntity customer) async {
    try {
      await _dataSource.saveCustomer(
        CustomerModel.fromEntity(customer).toJson(),
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Failure catch (f) {
      return Left(f);
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await _dataSource.deleteCustomer(id);
      return const Right(null);
    } on CustomerHasInvoicesException catch (e) {
      return Left(ServerFailure(e.message));
    } on CustomerHasChecksException catch (e) {
      return Left(ServerFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return Left(ServerFailure('حدث خطأ غير متوقع'));
    }
  }

  @override
  Future<Either<Failure, bool>> customerHasInvoices(String customerId) async {
    try {
      final hasInvoices = await _dataSource.customerHasInvoices(customerId);
      return Right(hasInvoices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Failure catch (f) {
      return Left(f);
    }
  }
}