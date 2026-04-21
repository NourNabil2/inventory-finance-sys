// lib/features/inventory/data/models/item_model.dart

import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';

class ItemCategoryModel extends ItemCategoryEntity {
  const ItemCategoryModel({required super.id, required super.name});

  factory ItemCategoryModel.fromJson(Map<String, dynamic> json) =>
      ItemCategoryModel(
        id:   json['id'] as String,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class ItemModel extends ItemEntity {
  const ItemModel({
    required super.id,
    required super.name,
    super.model,
    required super.defaultPrice,
    required super.totalQty,
    required super.availableQty,
    required super.status,
    super.imageUrl,
    super.categoryId,
    super.category,
    required super.createdAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    // category من الـ join (nullable)
    final catJson = json['item_categories'] as Map<String, dynamic>?;

    return ItemModel(
      id:           json['id'] as String,
      name:         json['name'] as String,
      model:        json['model'] as String?,
      defaultPrice: (json['default_price'] as num).toDouble(),
      totalQty:     (json['total_qty'] as num?)?.toInt() ?? 0,
      availableQty: (json['available_qty'] as num?)?.toInt() ?? 0,
      status:       _mapStatus(json['status'] as String? ?? 'available'),
      imageUrl:     json['image_url'] as String?,
      categoryId:   json['category_id'] as String?,
      category:     catJson != null ? ItemCategoryModel.fromJson(catJson) : null,
      createdAt:    DateTime.parse(json['created_at'] as String),
    );
  }

  factory ItemModel.fromEntity(ItemEntity e) => ItemModel(
    id:           e.id,
    name:         e.name,
    model:        e.model,
    defaultPrice: e.defaultPrice,
    totalQty:     e.totalQty,
    availableQty: e.availableQty,
    status:       e.status,
    imageUrl:     e.imageUrl,
    categoryId:   e.categoryId,
    createdAt:    e.createdAt,
  );

  Map<String, dynamic> toJson({bool includeId = true}) => {
    if (includeId && id.isNotEmpty) 'id': id,
    'name':          name,
    'model':         model,
    'default_price': defaultPrice,
    'total_qty':     totalQty,
    'available_qty': availableQty,
    'status':        _statusToString(status),
    'image_url':     imageUrl,
    'category_id':   categoryId,
  };

  static ItemStatus _mapStatus(String s) => switch (s) {
    'rented'      => ItemStatus.rented,
    'maintenance' => ItemStatus.maintenance,
    'reserved'    => ItemStatus.reserved,
    _             => ItemStatus.available,
  };

  static String _statusToString(ItemStatus s) => switch (s) {
    ItemStatus.rented      => 'rented',
    ItemStatus.maintenance => 'maintenance',
    ItemStatus.reserved    => 'reserved',
    ItemStatus.available   => 'available',
  };
}