// lib/features/suppliers/data/repositories/suppliers_repository_impl.dart

import 'package:bungee_manage_sys/core/errors/exceptions.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_payment_summary.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:dartz/dartz.dart';

import '../model/supplier_invoice_model.dart';
import '../model/supplier_model.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  final SuppliersRemoteDataSource _ds;
  SuppliersRepositoryImpl(this._ds);

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
        id:          '',
        invoiceId:   '',
        itemName:    i.itemName,
        qty:         i.qty,
        days:        i.days,
        pricePerDay: i.pricePerDay,
      ).toJson())
          .toList();

      final id = await _ds.createSupplierInvoice(
        invoiceData: invoiceData,
        itemsData:   itemsData,
      );
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
        invoiceId: invoiceId,
        amount:    amount,
        method:    method,
      );
      return Right(SupplierPaymentSummary.fromJson(raw));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}