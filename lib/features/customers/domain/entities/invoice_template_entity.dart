// lib/features/customers/domain/entities/invoice_template_entity.dart
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';

class InvoiceTemplateEntity {
  final String id;
  final String name;
  final List<TemplateItemModel> items;

  InvoiceTemplateEntity({
    required this.id,
    required this.name,
    required this.items,
  });

  factory InvoiceTemplateEntity.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplateEntity(
      id: json['id'] as String,
      name: json['name'] as String,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => TemplateItemModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TemplateItemModel {
  final String itemId;
  final String itemName;
  final int qty;
  final int days;
  final double pricePerDay;
  final double itemDiscount;
  final bool isSubRented;
  final String? supplierId;
  final double supplierCost;

  ItemEntity? resolvedItem;

  TemplateItemModel({
    required this.itemId,
    required this.itemName,
    required this.qty,
    required this.days,
    required this.pricePerDay,
    required this.itemDiscount,
    required this.isSubRented,
    this.supplierId,
    required this.supplierCost,
  });

  factory TemplateItemModel.fromJson(Map<String, dynamic> json) {
    return TemplateItemModel(
      itemId: json['item_id'] as String,
      itemName: json['item_name'] as String? ?? 'Unknown Item',
      qty: json['qty'] as int? ?? 1,
      days: json['days'] as int? ?? 1,
      pricePerDay: (json['price_per_day'] as num?)?.toDouble() ?? 0.0,
      itemDiscount: (json['item_discount'] as num?)?.toDouble() ?? 0.0,
      isSubRented: json['is_sub_rented'] as bool? ?? false,
      supplierId: json['supplier_id'] as String?,
      supplierCost: (json['supplier_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'qty': qty,
      'days': days,
      'price_per_day': pricePerDay,
      'item_discount': itemDiscount,
      'is_sub_rented': isSubRented,
      'supplier_id': supplierId,
      'supplier_cost': supplierCost,
    };
  }
}
