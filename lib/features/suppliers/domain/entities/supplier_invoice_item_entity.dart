import 'package:equatable/equatable.dart';

class SupplierInvoiceItemEntity extends Equatable {
  final String id;
  final String invoiceId;
  final String itemName;
  final int qty;
  final int days;
  final double pricePerDay;
  final double itemDiscount; // 🚨 الإضافة هنا

  const SupplierInvoiceItemEntity({
    required this.id, required this.invoiceId, required this.itemName,
    required this.qty, required this.days, required this.pricePerDay,
    this.itemDiscount = 0.0, // 🚨 الإضافة هنا
  });

  // حساب الإجمالي ناقص الخصم
  double get lineTotal => (qty * days * pricePerDay) - itemDiscount;

  @override
  List<Object?> get props => [id, invoiceId, itemName, qty, days, pricePerDay, itemDiscount];
}