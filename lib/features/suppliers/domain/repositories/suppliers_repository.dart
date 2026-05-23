// lib/features/suppliers/domain/repositories/suppliers_repository.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/clearing_result.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_payment_summary.dart';
import 'package:dartz/dartz.dart';

abstract class SuppliersRepository {
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers();
  Future<Either<Failure, void>> saveSupplier(SupplierEntity supplier);

  Future<Either<Failure, List<SupplierInvoiceEntity>>> getSupplierInvoices(String supplierId);
  Future<Either<Failure, SupplierInvoiceEntity>> getInvoiceDetails(String invoiceId);
  Future<Either<Failure, String>> createSupplierInvoice({
    required String supplierId,
    required List<SupplierInvoiceItemEntity> items,
    double discount,      // 🆕
    String? notes,
  });
  Future<Either<Failure, SupplierPaymentSummary>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  });

  // 🆕
  Future<Either<Failure, void>> cancelSupplierInvoice({
    required String invoiceId,
    String? reason,
  });

  // 🆕
  Future<Either<Failure, void>> editSupplierInvoice({
    required String invoiceId,
    required double discount,
    String? notes,
    required List<String> deletedItemIds,
    required List<Map<String, dynamic>> existingUpdates,
    required List<Map<String, dynamic>> newItems,
  });

  Future<Either<Failure, List<ServiceInvoiceEntity>>> getSupplierServiceInvoices(String supplierId);
  Future<Either<Failure, String>> createFullServiceInvoiceForSupplier({
    required String supplierId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  });
  Future<Either<Failure, String>> createServiceInvoiceForSupplier({
    required String supplierId,
    required double totalAmount,
    String? notes,
  });
  Future<Either<Failure, void>> recordServicePayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  });

  // 🆕
  Future<Either<Failure, void>> cancelServiceInvoice({
    required String invoiceId,
    required String supplierId,
    String? reason,
  });

  // 🆕
  Future<Either<Failure, void>> editServiceInvoice({
    required String invoiceId,
    required String supplierId,
    required double discount,
    String? notes,
    required List<String> deletedItemIds,
    required List<Map<String, dynamic>> existingUpdates,
    required List<Map<String, dynamic>> newItems,
  });

  Future<Either<Failure, ClearingResult>> executeSupplierClearing({
    required String supplierId,
    required double amount,
    String? notes,
    String? createdBy,
  });
  Future<Either<Failure, void>> updateLinkedCustomer({
    required String supplierId,
    required String? customerId,
  });
  Future<Either<Failure, ClearingResult>> executeClearing({
    required String supplierId,
    required String customerId,
    required double amount,
    String? notes,
    String? createdBy,
  });
  Future<Either<Failure, ClearingResult>> executeFlexibleClearing({
    required String supplierId,
    required String clearingType,
    double offsetAmount,
    double cashAmount,
    String cashMethod,
    String? notes,
    String? createdBy,
  });
}