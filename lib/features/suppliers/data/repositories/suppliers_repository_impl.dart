// lib/features/suppliers/data/repositories/suppliers_repository_impl.dart

import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/clearing_result.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_payment_summary.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:dartz/dartz.dart';

import '../../domain/entities/supplier_invoice_item_entity.dart';
import '../model/service_invoice_model.dart';
import '../model/supplier_invoice_model.dart';
import '../model/supplier_model.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  final SuppliersRemoteDataSource _ds;
  SuppliersRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers() async {
    try {
      return Right((await _ds.getSuppliers()).map(SupplierModel.fromJson).toList());
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, void>> saveSupplier(SupplierEntity supplier) async {
    try {
      await _ds.saveSupplier(SupplierModel.fromEntity(supplier).toJson());
      return const Right(null);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, List<SupplierInvoiceEntity>>> getSupplierInvoices(String supplierId) async {
    try {
      return Right((await _ds.getSupplierInvoices(supplierId)).map(SupplierInvoiceModel.fromJson).toList());
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, SupplierInvoiceEntity>> getInvoiceDetails(String invoiceId) async {
    try {
      return Right(SupplierInvoiceModel.fromJson(await _ds.getInvoiceDetails(invoiceId)));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, String>> createSupplierInvoice({
    required String supplierId,
    required List<SupplierInvoiceItemEntity> items,
    double discount = 0,    // 🆕
    String? notes,
  }) async {
    try {
      final invoiceData = {
        'supplier_id': supplierId,
        'discount':    discount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      // 🚨 FIX #1: تمرير itemDiscount من Entity إلى Model
      final itemsData = items
          .map((i) => SupplierInvoiceItemModel(
        id: '', invoiceId: '', itemName: i.itemName,
        qty: i.qty, days: i.days, pricePerDay: i.pricePerDay,
        itemDiscount: i.itemDiscount,
      ).toJson())
          .toList();
      return Right(await _ds.createSupplierInvoice(invoiceData: invoiceData, itemsData: itemsData));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, SupplierPaymentSummary>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    try {
      return Right(SupplierPaymentSummary.fromJson(
          await _ds.recordPayment(invoiceId: invoiceId, amount: amount, method: method)));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  // ── 🆕 إلغاء فاتورة ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> cancelSupplierInvoice({
    required String invoiceId,
    String? reason,
  }) async {
    try {
      await _ds.cancelSupplierInvoice(invoiceId: invoiceId, reason: reason);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── 🆕 تعديل فاتورة ────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> editSupplierInvoice({
    required String invoiceId,
    required double discount,
    String? notes,
    required List<String> deletedItemIds,
    required List<Map<String, dynamic>> existingUpdates,
    required List<Map<String, dynamic>> newItems,
  }) async {
    try {
      await _ds.editSupplierInvoice(
        invoiceId: invoiceId,
        discount: discount,
        notes: notes,
        deletedItemIds: deletedItemIds,
        existingUpdates: existingUpdates,
        newItems: newItems,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Service invoices ─────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceInvoiceEntity>>> getSupplierServiceInvoices(String supplierId) async {
    try {
      return Right((await _ds.getSupplierServiceInvoices(supplierId)).map(ServiceInvoiceModel.fromJson).toList());
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, String>> createFullServiceInvoiceForSupplier({
    required String supplierId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    try {
      return Right(await _ds.createFullServiceInvoiceForSupplier(
          supplierId: supplierId, invoiceData: invoiceData, itemsData: itemsData));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, String>> createServiceInvoiceForSupplier({
    required String supplierId,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      return Right(await _ds.createServiceInvoiceForSupplier(
          supplierId: supplierId, totalAmount: totalAmount, notes: notes));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, void>> recordServicePayment({
    required String invoiceId,
    required String supplierId,
    required double amount,
    required String method,
  }) async {
    try {
      await _ds.recordServicePayment(
          invoiceId: invoiceId, supplierId: supplierId, amount: amount, method: method);
      return const Right(null);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, ClearingResult>> executeSupplierClearing({
    required String supplierId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    try {
      return Right(ClearingResult.fromJson(await _ds.executeSupplierClearing(
          supplierId: supplierId, amount: amount, notes: notes, createdBy: createdBy)));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, void>> updateLinkedCustomer({
    required String supplierId,
    required String? customerId,
  }) async {
    try {
      await _ds.updateLinkedCustomer(supplierId: supplierId, customerId: customerId);
      return const Right(null);
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, ClearingResult>> executeClearing({
    required String supplierId,
    required String customerId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    try {
      return Right(ClearingResult.fromJson(await _ds.executeClearing(
          supplierId: supplierId, customerId: customerId,
          amount: amount, notes: notes, createdBy: createdBy)));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }

  @override
  Future<Either<Failure, ClearingResult>> executeFlexibleClearing({
    required String supplierId,
    required String clearingType,
    double offsetAmount = 0,
    double cashAmount   = 0,
    String cashMethod   = 'safe',
    String? notes,
    String? createdBy,
  }) async {
    try {
      return Right(ClearingResult.fromJson(await _ds.executeFlexibleClearing(
        supplierId: supplierId, clearingType: clearingType,
        offsetAmount: offsetAmount, cashAmount: cashAmount,
        cashMethod: cashMethod, notes: notes, createdBy: createdBy,
      )));
    } on ServerException catch (e) { return Left(ServerFailure(e.message)); }
  }
}
