// lib/features/customers/domain/repositories/customers_repository.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:dartz/dartz.dart';

/// Repository interface for customer operations
abstract class CustomersRepository {
  /// Get all customers
  Future<Either<Failure, List<CustomerEntity>>> getCustomers();

  /// Save (create or update) a customer
  Future<Either<Failure, void>> saveCustomer(CustomerEntity customer);

  /// Delete a customer (only if no invoices)
  Future<Either<Failure, void>> deleteCustomer(String id);

  /// Check if customer has invoices
  Future<Either<Failure, bool>> customerHasInvoices(String customerId);
}
