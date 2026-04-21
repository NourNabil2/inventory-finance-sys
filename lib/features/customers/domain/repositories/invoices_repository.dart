// lib/features/customers/domain/repositories/invoices_repository.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:dartz/dartz.dart';

/// Repository interface for invoice operations
abstract class InvoicesRepository {
  /// Get all invoices for a specific customer
  Future<Either<Failure, List<InvoiceEntity>>> getCustomerInvoices(
    String customerId,
  );

  /// Get detailed invoice with all items
  Future<Either<Failure, InvoiceEntity>> getInvoiceDetails(
    String invoiceId,
  );

  Future<Either<Failure, InvoicePaymentSummary>> getPaymentSummary(String invoiceId);

  /// ==========================================================================
  /// CREATE INVOICE WITH PAYMENT
  /// ==========================================================================
  /// Creates a new invoice with items and handles payment
  /// 
  /// [invoice] - The invoice entity to create
  /// [items] - List of invoice items
  /// [amountPaid] - Amount received from customer (0 if no payment)
  Future<Either<Failure, String>> createInvoiceWithPayment({
    required InvoiceEntity invoice,
    required List<InvoiceItemEntity> items,
    required double amountPaid,
    required String method,
  });

  /// ==========================================================================
  /// RECORD PAYMENT
  /// ==========================================================================
  /// Records an additional payment for an existing invoice
  Future<Either<Failure, void>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  });

  /// ==========================================================================
  /// EDIT INVOICE
  /// ==========================================================================
  /// Edits an existing invoice following business rules
  /// 
  /// [newItems] - New items to add
  /// [existingUpdates] - Map of item IDs to new day counts
  /// [additionalDebt] - Pre-calculated additional cost
  /// [newDiscount] - Optional new discount value
  Future<Either<Failure, void>> editInvoice({
    required String invoiceId,
    required List<InvoiceItemEntity> newItems,
    required num additionalDebt,
    required Map<String, Map<String, dynamic>> existingUpdates,
    double? newDiscount,
    required List<InvoiceItemEntity> currentItems,
  });
  /// Update invoice status
  Future<Either<Failure, void>> updateStatus(
    String invoiceId,
    InvoiceStatus status,
    String customerId,
  );

  /// ==========================================================================
  /// RETURN SINGLE ITEM
  /// ==========================================================================
  /// Returns a single invoice item to inventory
  Future<Either<Failure, void>> returnSingleItem(
      String invoiceItemId, {int? qty});

  /// Return multiple items
  Future<Either<Failure, void>> returnItems(
    String invoiceId,
    List<String> itemIds,
    String customerId,
  );

  Future<Either<Failure, InvoicePaymentSummary>> recordPaymentAndGetSummary({
    required String invoiceId,
    required double amount,
    required String method,
  });

  Future<Either<Failure, List<InvoiceEntity>>> getCustomerInvoicesForExport({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  });





}
