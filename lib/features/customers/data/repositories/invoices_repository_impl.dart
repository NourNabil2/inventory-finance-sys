// lib/features/customers/data/repositories/invoices_repository_impl.dart

import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/customers/data/datasources/invoices_remote_datasource.dart';
import 'package:bungee_manage_sys/features/customers/data/models/invoice_model.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/invoices_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

class InvoicesRepositoryImpl implements InvoicesRepository {
  final InvoicesRemoteDataSource _ds;
  InvoicesRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getCustomerInvoices(
      String customerId) async {
    try {
      final raw = await _ds.getCustomerInvoices(customerId);
      return Right(raw.map(InvoiceModel.fromJson).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, InvoiceEntity>> getInvoiceDetails(
      String invoiceId) async {
    try {
      final raw = await _ds.getInvoiceDetails(invoiceId);
      return Right(InvoiceModel.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, InvoicePaymentSummary>> getPaymentSummary(
      String invoiceId) async {
    try {
      final raw = await _ds.getInvoicePaymentSummary(invoiceId);
      return Right(InvoicePaymentSummary.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createInvoiceWithPayment({
    required InvoiceEntity invoice,
    required List<InvoiceItemEntity> items,
    required double amountPaid,
    required String method,
  }) async {
    try {
      final invoiceId = invoice.id.isEmpty ? const Uuid().v4() : invoice.id;
      final invoiceMap = {
        'id': invoiceId,
        'customer_id': invoice.customerId,
        'total_amount': invoice.totalAmount,
        'discount': invoice.discount,
        'net_total': invoice.netTotal,
        'status': 'active',
        'invoice_number': invoice.invoiceNumber,
        // 🚨 تم إضافة الحقول الجديدة هنا عشان تتبعت للسيرفر 🚨
        if (invoice.jobName != null) 'job_name': invoice.jobName,
        if (invoice.production != null) 'production': invoice.production,
      };

      final itemsList = items.map((i) => {
        'item_id': i.itemId,
        'qty': i.qty ?? 1,
        'days': i.days ?? 1,
        'price_per_day': i.pricePerDay ?? 0.0,
        'item_discount': i.itemDiscount ?? 0.0,
        'is_sub_rented': i.isSubRented ?? false,
        'status': 'out',
        if (i.supplierId != null) 'supplier_id': i.supplierId,
        if (i.supplierCost != null) 'supplier_cost': i.supplierCost,
      }).toList();

      final id = await _ds.createInvoiceWithPayment(
        invoiceData: invoiceMap,
        itemsData: itemsList,
        amountPaid: amountPaid,
        method: method,
      );
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── recordPaymentAndGetSummary — returns fresh summary ───────────────────

  @override
  Future<Either<Failure, InvoicePaymentSummary>> recordPaymentAndGetSummary({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    try {
      final raw = await _ds.recordPaymentAndGetSummary(
        invoiceId: invoiceId,
        amount: amount,
        method: method,
      );
      return Right(InvoicePaymentSummary.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── legacy recordPayment wrapper ─────────────────────────────────────────

  @override
  Future<Either<Failure, void>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    final result = await recordPaymentAndGetSummary(
      invoiceId: invoiceId,
      amount: amount,
      method: method,
    );
    return result.fold(Left.new, (_) => const Right(null));
  }

  @override
  Future<Either<Failure, void>> editInvoice({
    required String invoiceId,
    required List<InvoiceItemEntity> newItems,
    required Map<String, Map<String, dynamic>> existingUpdates,
    double? newDiscount,
    required List<InvoiceItemEntity> currentItems,
    List<String>? deletedItemIds,
    String? jobName,
    String? production,
  }) async {
    try {
      final newItemsJson = newItems.map((i) => {
        'item_id':       i.itemId,
        'qty':           i.qty ?? 1,
        'days':          i.days ?? 1,
        'price_per_day': i.pricePerDay ?? 0.0,
        'item_discount': i.itemDiscount ?? 0.0,
        'is_sub_rented': i.isSubRented ?? false,
        if (i.supplierId != null)   'supplier_id':   i.supplierId,
        if (i.supplierCost != null) 'supplier_cost': i.supplierCost,
      }).toList();

      final existingJson = existingUpdates.entries.map((e) => {
        'id':           e.key,
        'new_days':     e.value['days']         as int,
        'qty':          e.value['qty']          as int,
        'price_per_day':e.value['pricePerDay']  as double,
        'item_discount':e.value['flatDiscount'] as double,
      }).toList();

      await _ds.editInvoice(
        invoiceId:       invoiceId,
        newItems:        newItemsJson,
        existingUpdates: existingJson,
        newDiscount:     newDiscount,
        jobName:         jobName,
        production:      production,
        deletedItemIds:  deletedItemIds,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateStatus(
      String invoiceId, InvoiceStatus status, String customerId) async {
    try {
      final s = switch (status) {
        InvoiceStatus.active => 'active',
        InvoiceStatus.completed => 'completed',
        InvoiceStatus.canceled => 'canceled',
        InvoiceStatus.draft => 'draft',
      };
      await _ds.updateInvoiceStatus(invoiceId, s);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── returnSingleItem — supports partial qty ──────────────────────────────

  @override
  Future<Either<Failure, void>> returnSingleItem(
      String invoiceItemId, {int? qty}) async {
    try {
      await _ds.returnSingleItem(invoiceItemId, qty: qty);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> returnItems(
      String invoiceId, List<String> itemIds, String customerId) async {
    try {
      await _ds.returnItems(invoiceId, itemIds);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<InvoiceEntity>>> getCustomerInvoicesForExport({
    required String customerId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final raw = await _ds.getCustomerInvoicesForExport(
        customerId: customerId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(raw.map(InvoiceModel.fromJson).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}