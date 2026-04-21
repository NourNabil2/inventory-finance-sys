// lib/features/customers/domain/usecases/create_invoice_with_payment_usecase.dart

import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/core/usecases/usecase.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/invoices_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

class CreateInvoiceWithPaymentUseCase
    implements UseCase<String, CreateInvoiceWithPaymentParams> {
  final InvoicesRepository _repository;

  CreateInvoiceWithPaymentUseCase(this._repository);

  @override
  Future<Either<Failure, String>> call(CreateInvoiceWithPaymentParams params) {
    if (params.items.isEmpty) {
      return Future.value(Left(ValidationFailure('Invoice must have at least one item')));
    }

    if (params.amountPaid > params.netTotal) {
      return Future.value(
        Left(ValidationFailure(
            'Amount paid cannot exceed net total. Paid: ${params.amountPaid}, Net: ${params.netTotal}'
        )),
      );
    }

    for (final item in params.items) {
      if (item.qty <= 0) return Future.value(Left(ValidationFailure('Item quantity must be positive: ${item.itemName}')));
      if (item.days <= 0) return Future.value(Left(ValidationFailure('Item days must be positive: ${item.itemName}')));
      if (item.pricePerDay <= 0) return Future.value(Left(ValidationFailure('Item price must be positive: ${item.itemName}')));
    }

    // 🚨 التعديل هنا: ضفنا الـ method للاستدعاء 🚨
    return _repository.createInvoiceWithPayment(
      invoice: params.invoice,
      items: params.items,
      amountPaid: params.amountPaid,
      method: params.method,
    );
  }
}

class CreateInvoiceWithPaymentParams extends Equatable {
  final InvoiceEntity invoice;
  final List<InvoiceItemEntity> items;
  final double amountPaid;
  final String method; // 🚨 التعديل هنا: ضفنا المتغير 🚨

  const CreateInvoiceWithPaymentParams({
    required this.invoice,
    required this.items,
    required this.amountPaid,
    required this.method, // 🚨 التعديل هنا 🚨
  });

  double get subtotal => items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  double get totalItemDiscounts => items.fold<double>(0, (sum, item) => sum + item.itemDiscount);
  double get netTotal => invoice.netTotal;
  double get remainingAmount => netTotal - amountPaid;

  @override
  List<Object?> get props => [invoice, items, amountPaid, method];
}

class InvoiceCalculations {
  InvoiceCalculations._();

  static double calculateItemDiscountFromPercentage({required int qty, required int days, required double pricePerDay, required double discountPercentage}) {
    final lineTotal = qty * days * pricePerDay;
    return lineTotal * (discountPercentage / 100);
  }

  static double calculateInvoiceDiscountFromPercentage({required double subtotal, required double discountPercentage}) {
    return subtotal * (discountPercentage / 100);
  }

  static double calculateLineTotal({required int qty, required int days, required double pricePerDay}) {
    return qty * days * pricePerDay;
  }

  static double calculateLineTotalAfterDiscount({required int qty, required int days, required double pricePerDay, required double itemDiscount}) {
    final lineTotal = calculateLineTotal(qty: qty, days: days, pricePerDay: pricePerDay);
    return lineTotal - itemDiscount;
  }

  static double calculateSubtotal(List<InvoiceItemEntity> items) {
    return items.fold<double>(0, (sum, item) => sum + item.lineTotal);
  }

  static double calculateNetTotal({required double subtotal, required double invoiceDiscount}) {
    return (subtotal - invoiceDiscount).clamp(0, double.infinity);
  }
}