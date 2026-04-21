// lib/features/customers/domain/usecases/return_invoice_item_usecase.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/core/usecases/usecase.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/invoices_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

/// ============================================================================
/// RETURN INVOICE ITEM USE CASE
/// ============================================================================
/// 
/// Encapsulates the business logic for returning a single invoice item.
/// This use case handles:
/// - Validating the item can be returned
/// - Updating invoice item status to 'returned'
/// - Incrementing inventory quantity atomically
///
/// [Business Rules]:
/// - Only items with status 'out' can be returned
/// - Invoice must be in 'active' status
/// - Returns the item to inventory (available_qty += qty)
class ReturnInvoiceItemUseCase
    implements UseCase<void, ReturnInvoiceItemParams> {
  final InvoicesRepository _repository;

  ReturnInvoiceItemUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(ReturnInvoiceItemParams params) {
    // ========================================================================
    // DOMAIN VALIDATION
    // ========================================================================
    
    // Validate invoice is active
    if (params.invoice.status != InvoiceStatus.active) {
      return Future.value(
        Left(ValidationFailure(
          'Only active invoices can have items returned. Current status: ${params.invoice.status}'
        )),
      );
    }

    // Validate item belongs to this invoice
    final item = params.invoice.items.firstWhere(
      (i) => i.id == params.invoiceItemId,
      orElse: () => throw ArgumentError('Item not found in invoice'),
    );

    // Validate item is currently out
    if (item.status != InvoiceItemStatus.out) {
      return Future.value(
        Left(ValidationFailure(
          'Item is already returned or not available for return'
        )),
      );
    }

    // Call repository
    return _repository.returnSingleItem(params.invoiceItemId);
  }
}

/// ============================================================================
/// RETURN INVOICE ITEM PARAMETERS
/// ============================================================================
class ReturnInvoiceItemParams extends Equatable {
  final String invoiceItemId;
  final InvoiceEntity invoice;

  const ReturnInvoiceItemParams({
    required this.invoiceItemId,
    required this.invoice,
  });

  @override
  List<Object?> get props => [invoiceItemId, invoice];
}

/// ============================================================================
/// BATCH RETURN ITEMS USE CASE
/// ============================================================================
/// 
/// Returns multiple items at once for efficiency
class BatchReturnItemsUseCase
    implements UseCase<void, BatchReturnItemsParams> {
  final InvoicesRepository _repository;

  BatchReturnItemsUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(BatchReturnItemsParams params) async {
    // Validate invoice is active
    if (params.invoice.status != InvoiceStatus.active) {
      return Left(ValidationFailure(
        'Only active invoices can have items returned'
      ));
    }

    // Validate all items can be returned
    for (final itemId in params.itemIds) {
      final item = params.invoice.items.firstWhere(
        (i) => i.id == itemId,
        orElse: () => throw ArgumentError('Item $itemId not found in invoice'),
      );

      if (item.status != InvoiceItemStatus.out) {
        return Left(ValidationFailure(
          'Item ${item.itemName} is already returned'
        ));
      }
    }

    // Call repository for batch return
    return _repository.returnItems(
      params.invoice.id,
      params.itemIds,
      params.invoice.customerId,
    );
  }
}

/// ============================================================================
/// BATCH RETURN ITEMS PARAMETERS
/// ============================================================================
class BatchReturnItemsParams extends Equatable {
  final List<String> itemIds;
  final InvoiceEntity invoice;

  const BatchReturnItemsParams({
    required this.itemIds,
    required this.invoice,
  });

  @override
  List<Object?> get props => [itemIds, invoice];
}
