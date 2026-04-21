// lib/features/inventory/data/repositories/inventory_repository_impl.dart

import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:bungee_manage_sys/core/errors/failures.dart';
import 'package:bungee_manage_sys/core/errors/result_handler.dart';
import 'package:bungee_manage_sys/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:bungee_manage_sys/features/inventory/data/models/item_model.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource _ds;

  InventoryRepositoryImpl(this._ds);

  @override
  Future<Either<Failure, List<ItemEntity>>> getItems() =>
      ResultHandler.handle(() async {
        final raw = await _ds.getItems();
        return raw.map(ItemModel.fromJson).toList();
      });

  @override
  Future<Either<Failure, List<ItemCategoryEntity>>> getCategories() =>
      ResultHandler.handle(() async {
        final raw = await _ds.getCategories();
        return raw.map(ItemCategoryModel.fromJson).toList();
      });

  @override
  Future<Either<Failure, Unit>> deleteItem(String id) =>
      ResultHandler.handleVoid(() => _ds.deleteItem(id));

  @override
  Future<Either<Failure, Unit>> saveItem(ItemEntity item) =>
      ResultHandler.handleVoid(
              () => _ds.saveItem(ItemModel.fromEntity(item).toJson()));

  @override
  Future<Either<Failure, String>> uploadImage(String itemId, File file) =>
      ResultHandler.handle(() => _ds.uploadImage(itemId, file));
}