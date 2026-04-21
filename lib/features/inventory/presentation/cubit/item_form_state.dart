// lib/features/inventory/presentation/cubit/item_form_state.dart

part of 'item_form_cubit.dart';

sealed class ItemFormState extends Equatable {
  const ItemFormState();
  @override
  List<Object?> get props => [];
}

final class ItemFormInitial extends ItemFormState {}
final class ItemFormLoading extends ItemFormState {}
final class ItemFormSuccess extends ItemFormState {}

final class ItemFormError extends ItemFormState {
  final String message;
  const ItemFormError(this.message);
  @override
  List<Object?> get props => [message];
}