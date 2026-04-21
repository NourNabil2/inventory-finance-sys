// lib/features/inventory/presentation/widgets/item_form_dialog.dart

import 'dart:io';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/core/widgets/app_dialog_shell.dart';
import 'package:bungee_manage_sys/core/widgets/app_dropdown.dart';
import 'package:bungee_manage_sys/core/widgets/app_image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bungee_manage_sys/core/di/injection_container.dart' as di;
import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/app_text_feild.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/item_form_cubit.dart';

// ─── Show Helper ──────────────────────────────────────────────────────────────

void showItemFormDialog(BuildContext context, {ItemEntity? initialItem}) {
  final inventoryCubit = context.read<InventoryCubit>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider<InventoryCubit>.value(value: inventoryCubit),
        BlocProvider<ItemFormCubit>(create: (_) => di.sl<ItemFormCubit>()),
      ],
      child: ItemFormDialog(initialItem: initialItem),
    ),
  );
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

class ItemFormDialog extends StatefulWidget {
  final ItemEntity? initialItem;

  const ItemFormDialog({super.key, this.initialItem});

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _modelCtrl    = TextEditingController();
  final _priceCtrl    = TextEditingController();
  final _totalQtyCtrl = TextEditingController();
  final _availQtyCtrl = TextEditingController();

  late ItemStatus _selectedStatus;
  String? _selectedCategoryId;
  File? _pickedImage;

  final _v = AppSizeVertical.instance;
  final _h = AppSizeHorizontal.instance;

  bool get _isEdit => widget.initialItem != null;

  @override
  void initState() {
    super.initState();
    final item = widget.initialItem;
    if (item != null) {
      _nameCtrl.text      = item.name;
      _modelCtrl.text     = item.model ?? '';
      _priceCtrl.text     = item.defaultPrice.toStringAsFixed(0);
      _totalQtyCtrl.text  = '${item.totalQty}';
      _availQtyCtrl.text  = '${item.availableQty}';
      _selectedStatus     = item.status;
      _selectedCategoryId = item.categoryId;
    } else {
      _selectedStatus = ItemStatus.available;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _modelCtrl.dispose();
    _priceCtrl.dispose();
    _totalQtyCtrl.dispose();
    _availQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _pickedImage = File(picked.path));
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;
    context.read<ItemFormCubit>().submitForm(
      id:               widget.initialItem?.id,
      name:             _nameCtrl.text,
      model:            _modelCtrl.text.isEmpty ? null : _modelCtrl.text,
      defaultPrice:     double.parse(_priceCtrl.text),
      totalQty:         int.parse(_totalQtyCtrl.text),
      availableQty:     int.parse(_availQtyCtrl.text),
      status:           _selectedStatus,
      categoryId:       _selectedCategoryId,
      existingImageUrl: widget.initialItem?.imageUrl,
      newImageFile:     _pickedImage,
    );
  }

  // ── Status label helper ───────────────────────────────────
  String _statusLabel(ItemStatus s) => switch (s) {
    ItemStatus.available   => 'inventory.status_available',
    ItemStatus.rented      => 'inventory.status_rented',
    ItemStatus.maintenance => 'inventory.status_maintenance',
    ItemStatus.reserved    => 'inventory.status_reserved',
  };

  @override
  Widget build(BuildContext context) {
    final categories = switch (context.watch<InventoryCubit>().state) {
      InventoryLoaded(:final categories) => categories,
      _ => <ItemCategoryEntity>[],
    };

    // safety check — لو الـ id مش في الـ list نرجع null
    final safeCategoryId = categories.any((c) => c.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;

    return BlocConsumer<ItemFormCubit, ItemFormState>(
      listener: (context, state) {
        if (state is ItemFormSuccess) {
          Navigator.of(context).pop();
          context.showSuccess('inventory.item_saved'.tr());
          context.read<InventoryCubit>().fetchItems();
        }
        if (state is ItemFormError) {
          context.showError(state.message);
        }
      },
      builder: (context, state) {
        final isLoading = state is ItemFormLoading;

        return AppDialogShell(
          title: (_isEdit
              ? 'inventory.edit_item_title'
              : 'inventory.add_item_title')
              .tr(),
          saveLabel: 'inventory.save'.tr(),
          isLoading: isLoading,
          onClose: isLoading ? null : () => Navigator.of(context).pop(),
          onSave: () => _submit(context),
          content: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Image ────────────────────────────────
                AppImagePicker(
                  pickedImage: _pickedImage,
                  existingUrl: widget.initialItem?.imageUrl,
                  onTap: isLoading ? null : _pickImage,
                ),

                SizedBox(height: _v.s16),

                // ── Name ─────────────────────────────────
                AppTextFieldFactory.email(
                  controller: _nameCtrl,
                  title: 'inventory.field_name'.tr(),
                  hintText: 'inventory.field_name_hint'.tr(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'inventory.validation_name_required'.tr()
                      : null,
                ),

                SizedBox(height: _v.s12),

                // ── Model ─────────────────────────────────
                AppTextField(
                  controller: _modelCtrl,
                  title: 'inventory.field_model'.tr(),
                  hintText: 'inventory.field_model_hint'.tr(),
                ),

                SizedBox(height: _v.s12),

                // ── Category ──────────────────────────────
                AppDropdown<String?>(
                  title: 'inventory.field_category'.tr(),
                  value: safeCategoryId,
                  onChanged: (id) =>
                      setState(() => _selectedCategoryId = id),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('inventory.no_category'.tr()),
                    ),
                    ...categories.map(
                          (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: _v.s12),

                // ── Price ─────────────────────────────────
                AppTextFieldFactory.number(
                  controller: _priceCtrl,
                  title: 'inventory.field_price'.tr(),
                  hintText: 'inventory.field_price_hint'.tr(),
                  allowDecimal: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'inventory.validation_price_required'.tr();
                    }
                    if (double.tryParse(v) == null) {
                      return 'inventory.validation_price_invalid'.tr();
                    }
                    return null;
                  },
                ),

                SizedBox(height: _v.s12),

                // ── Qty Row ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: AppTextFieldFactory.number(
                        controller: _totalQtyCtrl,
                        title: 'inventory.field_total_qty'.tr(),
                        hintText: 'inventory.field_total_qty_hint'.tr(),
                        validator: (v) =>
                        int.tryParse(v ?? '') == null
                            ? 'inventory.validation_qty_invalid'.tr()
                            : null,
                      ),
                    ),
                    SizedBox(width: _h.s12),
                    Expanded(
                      child: AppTextFieldFactory.number(
                        controller: _availQtyCtrl,
                        title: 'inventory.field_available_qty'.tr(),
                        hintText: 'inventory.field_available_qty_hint'.tr(),
                        validator: (v) {
                          final avail = int.tryParse(v ?? '');
                          final total = int.tryParse(_totalQtyCtrl.text);
                          if (avail == null) {
                            return 'inventory.validation_qty_invalid'.tr();
                          }
                          if (total != null && avail > total) {
                            return 'inventory.validation_available_exceeds_total'
                                .tr();
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: _v.s12),

                // ── Status ────────────────────────────────
                AppDropdown<ItemStatus>(
                  title: 'inventory.field_status'.tr(),
                  value: _selectedStatus,
                  onChanged: (s) {
                    if (s != null) setState(() => _selectedStatus = s);
                  },
                  items: ItemStatus.values
                      .map((s) => DropdownMenuItem(
                    value: s,
                    child: Text(_statusLabel(s).tr()),
                  ))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}