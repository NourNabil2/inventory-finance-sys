import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/core/usecases/usecase.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/invoices_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class EditInvoiceUseCase implements UseCase<void, EditInvoiceParams> {
  final InvoicesRepository _repository;
  EditInvoiceUseCase(this._repository);

  @override
  Future<Either<Failure, void>> call(EditInvoiceParams params) async {
    if (params.originalInvoice.status != InvoiceStatus.active) {
      return Left(ValidationFailure(
        'Only active invoices can be edited. Current status: ${params.originalInvoice.status}',
      ));
    }

    // Validate days only increase
    for (final entry in params.modifiedItems.entries) {
      final newDays = entry.value['days'] as int?;
      if (newDays == null) continue;

      final originalItem = params.originalInvoice.items.firstWhere(
            (item) => item.id == entry.key,
        orElse: () => throw ArgumentError('Item ${entry.key} not found'),
      );

      if (newDays < originalItem.days) {
        return Left(ValidationFailure(
          'Cannot decrease days for item ${originalItem.itemName}. '
              'Original: ${originalItem.days}, Attempted: $newDays',
        ));
      }
    }

    final additionalDebt = _calculateAdditionalDebt(params);

    if (additionalDebt < 0) {
      return Left(ValidationFailure(
        'Additional debt cannot be negative.',
      ));
    }

    return await _repository.editInvoice(
      invoiceId:       params.invoiceId,
      newItems:        params.newItems,
      existingUpdates: params.modifiedItems,
      additionalDebt:  additionalDebt,
      newDiscount:     params.newDiscount,
      currentItems:    params.originalInvoice.items,
    );
  }

  double _calculateAdditionalDebt(EditInvoiceParams params) {
    final original = params.originalInvoice;

    final oldSubtotal = original.items.fold<double>(
      0, (s, i) => s + i.lineTotalAfterDiscount,
    );
    final oldNetTotal = oldSubtotal - original.discount;

    double newSubtotal = 0;
    for (final item in original.items) {
      final mod          = params.modifiedItems[item.id];
      final days         = (mod?['days']         as int?)    ?? item.days;
      final qty          = (mod?['qty']          as int?)    ?? item.qty;
      final pricePerDay  = (mod?['pricePerDay']  as double?) ?? item.pricePerDay;
      final flatDiscount = (mod?['flatDiscount'] as double?) ?? item.itemDiscount;
      newSubtotal += (days * qty * pricePerDay - flatDiscount).clamp(0, double.infinity);
    }

    for (final newItem in params.newItems) {
      newSubtotal += newItem.lineTotalAfterDiscount;
    }

    final newDiscount = params.newDiscount ?? original.discount;
    final newNetTotal = newSubtotal - newDiscount;

    return newNetTotal - oldNetTotal;
  }
}

class EditInvoiceParams extends Equatable {
  final String invoiceId;
  final InvoiceEntity originalInvoice;
  final List<InvoiceItemEntity> newItems;
  final Map<String, Map<String, dynamic>> modifiedItems; // 👈
  final double? newDiscount;

  const EditInvoiceParams({
    required this.invoiceId,
    required this.originalInvoice,
    required this.newItems,
    required this.modifiedItems,
    this.newDiscount,
  });

  @override
  List<Object?> get props =>
      [invoiceId, originalInvoice, newItems, modifiedItems, newDiscount];
}