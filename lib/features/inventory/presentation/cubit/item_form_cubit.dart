// lib/features/inventory/presentation/cubit/item_form_cubit.dart

import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/domain/repositories/inventory_repository.dart';

part 'item_form_state.dart';

class ItemFormCubit extends Cubit<ItemFormState> {
  final InventoryRepository _repository;

  ItemFormCubit(this._repository) : super(ItemFormInitial());

  Future<void> submitForm({
    String? id,
    required String name,
    String? model,
    required double defaultPrice,
    double priceFilm = 0,
    double priceSeries = 0,
    double priceAd = 0,
    required int totalQty,
    required int availableQty,
    required ItemStatus status,
    String? categoryId,
    String? existingImageUrl,
    File? newImageFile,
  }) async {
    emit(ItemFormLoading());

    final itemId = id ?? const Uuid().v4();

    // رفع الصورة لو في صورة جديدة
    String? imageUrl = existingImageUrl;
    if (newImageFile != null) {
      final uploadResult = await _repository.uploadImage(itemId, newImageFile);
      final didFail = uploadResult.fold((_) => true, (_) => false);
      if (didFail) {
        uploadResult.fold(
              (f) => emit(ItemFormError(f.message)),
              (_) {},
        );
        return;
      }
      imageUrl = uploadResult.fold((_) => null, (url) => url);
    }

    final item = ItemEntity(
      id:           itemId,
      name:         name.trim(),
      model:        model?.trim(),
      defaultPrice: defaultPrice,
      priceFilm:    priceFilm,
      priceSeries:  priceSeries,
      priceAd:      priceAd,
      totalQty:     totalQty,
      availableQty: availableQty,
      status:       status,
      imageUrl:     imageUrl,
      categoryId:   categoryId,
      createdAt:    DateTime.now(),
    );

    final result = await _repository.saveItem(item);
    result.fold(
          (f) => emit(ItemFormError(f.message)),
          (_) => emit(ItemFormSuccess()),
    );
  }
}