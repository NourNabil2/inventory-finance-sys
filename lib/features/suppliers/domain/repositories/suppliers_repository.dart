// lib/features/suppliers/domain/repositories/suppliers_repository.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_payment_summary.dart';
import 'package:dartz/dartz.dart';

abstract class SuppliersRepository {
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers();

  Future<Either<Failure, void>> saveSupplier(SupplierEntity supplier);

  Future<Either<Failure, List<SupplierInvoiceEntity>>> getSupplierInvoices(
      String supplierId);

  Future<Either<Failure, SupplierInvoiceEntity>> getInvoiceDetails(
      String invoiceId);

  Future<Either<Failure, String>> createSupplierInvoice({
    required String supplierId,
    required List<SupplierInvoiceItemEntity> items,
    String? notes,
  });

  Future<Either<Failure, SupplierPaymentSummary>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  });
}