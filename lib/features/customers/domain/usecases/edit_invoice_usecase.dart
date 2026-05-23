// lib/features/customers/domain/usecases/edit_invoice_usecase.dart

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
    // لا نرفض الـ draft — الـ cubit بيبعت newStatus لتحويلها لـ active
    if (params.originalInvoice.status == InvoiceStatus.canceled) {
      return const Left(ValidationFailure('لا يمكن تعديل فاتورة ملغاة'));
    }

    // التحقق من أن الأيام ما اتنقصتش (فقط للأصناف الموجودة)
    for (final entry in params.modifiedItems.entries) {
      final newDays = entry.value['days'] as int?;
      if (newDays == null) continue;

      final originalItem = params.originalInvoice.items.firstWhere(
            (item) => item.id == entry.key,
        orElse: () => throw ArgumentError('Item ${entry.key} not found'),
      );

      if (newDays < originalItem.days) {
        return Left(ValidationFailure(
          'لا يمكن تقليل الأيام للصنف ${originalItem.itemName}. '
              'الأصلي: ${originalItem.days}، المطلوب: $newDays',
        ));
      }
    }

    return await _repository.editInvoice(
      invoiceId:       params.invoiceId,
      newItems:        params.newItems,
      existingUpdates: params.modifiedItems,
      newDiscount:     params.newDiscount,
      currentItems:    params.originalInvoice.items,
      deletedItemIds:  params.deletedItemIds,
      newStatus:       params.newStatus,
      jobName:         params.jobName,
      production:      params.production,
    );
  }
}

class EditInvoiceParams extends Equatable {
  final String invoiceId;
  final InvoiceEntity originalInvoice;
  final List<InvoiceItemEntity> newItems;
  final Map<String, Map<String, dynamic>> modifiedItems;
  final List<String>? deletedItemIds;
  final double? newDiscount;
  final String? newStatus;
  final String? jobName;
  final String? production;

  const EditInvoiceParams({
    required this.invoiceId,
    required this.originalInvoice,
    required this.newItems,
    required this.modifiedItems,
    this.deletedItemIds,
    this.newDiscount,
    this.newStatus,
    this.jobName,
    this.production,
  });

  @override
  List<Object?> get props => [
    invoiceId, originalInvoice, newItems, modifiedItems,
    deletedItemIds, newDiscount, newStatus, jobName, production,
  ];
}