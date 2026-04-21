// lib/features/inventory/presentation/cubit/inventory_state.dart

part of 'inventory_cubit.dart';

sealed class InventoryState extends Equatable {
  const InventoryState();
  @override
  List<Object?> get props => [];
}

final class InventoryInitial extends InventoryState {}
final class InventoryLoading extends InventoryState {}

final class InventoryLoaded extends InventoryState {
  final List<ItemEntity>         items;
  final List<ItemEntity>         filtered;
  final List<ItemCategoryEntity> categories;
  const InventoryLoaded({
    required this.items,
    required this.filtered,
    required this.categories,
  });
  @override
  List<Object?> get props => [items, filtered, categories];
}

final class InventoryError extends InventoryState {
  final String message;
  const InventoryError(this.message);
  @override
  List<Object?> get props => [message];
}