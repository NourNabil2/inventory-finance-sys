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

  // ── Supplier CRUD ─────────────────────────────────────────

  @override
  Future<Either<Failure, List<SupplierEntity>>> getSuppliers() async {
    try {
      final raw = await _ds.getSuppliers();
      return Right(raw.map(SupplierModel.fromJson).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> saveSupplier(SupplierEntity supplier) async {
    try {
      await _ds.saveSupplier(SupplierModel.fromEntity(supplier).toJson());
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Purchase invoices ─────────────────────────────────────

  @override
  Future<Either<Failure, List<SupplierInvoiceEntity>>> getSupplierInvoices(
      String supplierId) async {
    try {
      final raw = await _ds.getSupplierInvoices(supplierId);
      return Right(raw.map(SupplierInvoiceModel.fromJson).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, SupplierInvoiceEntity>> getInvoiceDetails(
      String invoiceId) async {
    try {
      final raw = await _ds.getInvoiceDetails(invoiceId);
      return Right(SupplierInvoiceModel.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createSupplierInvoice({
    required String supplierId,
    required List<SupplierInvoiceItemEntity> items,
    String? notes,
  }) async {
    try {
      final invoiceData = {
        'supplier_id': supplierId,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      };
      final itemsData = items
          .map((i) => SupplierInvoiceItemModel(
        id: '',
        invoiceId: '',
        itemName: i.itemName,
        qty: i.qty,
        days: i.days,
        pricePerDay: i.pricePerDay,
      ).toJson())
          .toList();
      final id = await _ds.createSupplierInvoice(
          invoiceData: invoiceData, itemsData: itemsData);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, SupplierPaymentSummary>> recordPayment({
    required String invoiceId,
    required double amount,
    required String method,
  }) async {
    try {
      final raw = await _ds.recordPayment(
          invoiceId: invoiceId, amount: amount, method: method);
      return Right(SupplierPaymentSummary.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Service invoices ──────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceInvoiceEntity>>> getSupplierServiceInvoices(
      String supplierId) async {
    try {
      final raw = await _ds.getSupplierServiceInvoices(supplierId);
      return Right(raw.map(ServiceInvoiceModel.fromJson).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createFullServiceInvoiceForSupplier({
    required String supplierId,
    required Map<String, dynamic> invoiceData,
    required List<Map<String, dynamic>> itemsData,
  }) async {
    try {
      final id = await _ds.createFullServiceInvoiceForSupplier(
        supplierId:  supplierId,
        invoiceData: invoiceData,
        itemsData:   itemsData,
      );
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> createServiceInvoiceForSupplier({
    required String supplierId,
    required double totalAmount,
    String? notes,
  }) async {
    try {
      final id = await _ds.createServiceInvoiceForSupplier(
          supplierId: supplierId, totalAmount: totalAmount, notes: notes);
      return Right(id);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
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
        invoiceId:  invoiceId,
        supplierId: supplierId,
        amount:     amount,
        method:     method,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Unified supplier clearing ─────────────────────────────

  @override
  Future<Either<Failure, ClearingResult>> executeSupplierClearing({
    required String supplierId,
    required double amount,
    String? notes,
    String? createdBy,
  }) async {
    try {
      final raw = await _ds.executeSupplierClearing(
          supplierId: supplierId,
          amount:     amount,
          notes:      notes,
          createdBy:  createdBy);
      return Right(ClearingResult.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Legacy cross-customer clearing ────────────────────────

  @override
  Future<Either<Failure, void>> updateLinkedCustomer({
    required String supplierId,
    required String? customerId,
  }) async {
    try {
      await _ds.updateLinkedCustomer(
          supplierId: supplierId, customerId: customerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
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
      final raw = await _ds.executeClearing(
          supplierId: supplierId,
          customerId: customerId,
          amount:     amount,
          notes:      notes,
          createdBy:  createdBy);
      return Right(ClearingResult.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
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
      final raw = await _ds.executeFlexibleClearing(
        supplierId:   supplierId,
        clearingType: clearingType,
        offsetAmount: offsetAmount,
        cashAmount:   cashAmount,
        cashMethod:   cashMethod,
        notes:        notes,
        createdBy:    createdBy,
      );
      return Right(ClearingResult.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}