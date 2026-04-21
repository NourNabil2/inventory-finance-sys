// lib/features/inventory/data/datasources/inventory_remote_datasource.dart
import 'dart:io';
import 'package:bungee_manage_sys/core/api/base_api_services.dart';
import 'package:bungee_manage_sys/core/api/endpoints.dart';
import 'package:bungee_manage_sys/core/errors/error_handler.dart';
import 'package:bungee_manage_sys/core/api/model/http_method.dart';

abstract class InventoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> getItems();
  Future<List<Map<String, dynamic>>> getCategories();
  Future<void> deleteItem(String id);
  Future<void> saveItem(Map<String, dynamic> itemMap);
  Future<String> uploadImage(String? itemId, File imageFile);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final BaseApiServices _api;

  InventoryRemoteDataSourceImpl(this._api);

  @override
  Future<List<Map<String, dynamic>>> getItems() async {
    try {
      final response = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.items,
        columns: '*, item_categories(id, name)',
        orderBy: 'created_at',
        ascending: false,
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final response = await _api.request(
        method: HttpMethod.get,
        url: Endpoints.itemCategories,
        orderBy: 'name',
        ascending: true,
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> deleteItem(String id) async {
    try {
      await _api.request(
        method: HttpMethod.delete,
        url: Endpoints.items,
        queryParams: {'id': id},
      );
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<void> saveItem(Map<String, dynamic> itemMap) async {
    try {
      if (itemMap['id'] != null) {
        await _api.upsert(
          url: Endpoints.items,
          body: itemMap,
        );
      } else {
        await _api.request(
          method: HttpMethod.post,
          url: Endpoints.items,
          body: itemMap,
        );
      }
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }

  @override
  Future<String> uploadImage(String? itemId, File imageFile) async {
    try {
      final ext = imageFile.path.split('.').last.toLowerCase();
      final name = (itemId?.isNotEmpty == true
          ? itemId!
          : '${DateTime.now().millisecondsSinceEpoch}')
          .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '_');

      return await _api.uploadFile(
        bucket: Endpoints.itemImagesBucket,
        path: '${Endpoints.itemImagesPath}/$name.$ext',
        file: imageFile,
      );
    } catch (e, st) {
      throw ErrorHandler.handleException(e, st);
    }
  }
}