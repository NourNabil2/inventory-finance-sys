// lib/features/inventory/domain/entities/item_entity.dart

import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:equatable/equatable.dart';



class ItemCategoryEntity extends Equatable {
  final String id;
  final String name;

  const ItemCategoryEntity({required this.id, required this.name});

  @override
  List<Object?> get props => [id, name];
}

class ItemEntity extends Equatable {
  final String id;
  final String name;
  final String? model;
  final double defaultPrice;
  final int totalQty;
  final int availableQty;
  final ItemStatus status;
  final String? imageUrl;
  final String? categoryId;
  final ItemCategoryEntity? category;
  final DateTime createdAt;

  const ItemEntity({
    required this.id,
    required this.name,
    this.model,
    required this.defaultPrice,
    required this.totalQty,
    required this.availableQty,
    required this.status,
    this.imageUrl,
    this.categoryId,
    this.category,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
    id, name, model, defaultPrice,
    totalQty, availableQty, status,
    imageUrl, categoryId, category, createdAt,
  ];
}