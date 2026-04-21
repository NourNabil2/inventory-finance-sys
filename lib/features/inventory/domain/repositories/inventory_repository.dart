// lib/features/inventory/domain/repositories/inventory_repository.dart

import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';

abstract class InventoryRepository {
  Future<Either<Failure, List<ItemEntity>>>         getItems();
  Future<Either<Failure, List<ItemCategoryEntity>>> getCategories();
  Future<Either<Failure, Unit>>                     deleteItem(String id);
  Future<Either<Failure, Unit>>                     saveItem(ItemEntity item);
  Future<Either<Failure, String>>                   uploadImage(String itemId, File file);
}