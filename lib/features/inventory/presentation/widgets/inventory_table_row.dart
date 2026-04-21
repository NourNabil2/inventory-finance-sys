// lib/features/inventory/presentation/widgets/inventory_table_row.dart
// للـ Desktop table view

import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/confirmation_dialog.dart';
import 'package:bungee_manage_sys/core/widgets/custom_network_image.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';

class InventoryTableRow extends StatelessWidget {
  final ItemEntity item;
  final int index;
  final VoidCallback? onEdit;

  const InventoryTableRow({
    super.key,
    required this.item,
    required this.index,
    this.onEdit,
  });

  ChipStatus get _chipStatus => switch (item.status) {
    ItemStatus.available   => ChipStatus.available,
    ItemStatus.rented      => ChipStatus.rented,
    ItemStatus.maintenance => ChipStatus.maintenance,
    ItemStatus.reserved    => ChipStatus.reserved,
  };

  String get _statusKey => switch (item.status) {
    ItemStatus.available   => 'inventory.status_available',
    ItemStatus.rented      => 'inventory.status_rented',
    ItemStatus.maintenance => 'inventory.status_maintenance',
    ItemStatus.reserved    => 'inventory.status_reserved',
  };

  Future<void> _onDelete(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'inventory.delete_item'.tr(),
      message: 'inventory.delete_confirm'.tr(),
      confirmText: 'common.confirm'.tr(),
      cancelText: 'common.cancel'.tr(),
      icon: Icons.delete_outline,
      isDangerous: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<InventoryCubit>().deleteItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEven = index % 2 == 0;

    return Container(
      color: isEven
          ? Theme.of(context).cardColor
          : Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          // Image
          SizedBox(
            width: 50.w,
            child: CustomNetworkImage.rounded(
              imageUrl: item.imageUrl ?? '',
              width: 48.w,
              height: 48.w,
              borderRadius: 8.r,
            ),
          ),
        SizedBox.fromSize(size: Size(12.w, 0)),
          // Name + Model
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.model != null)
                  Text(item.model!,
                      style: Theme.of(context).textTheme.labelSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),

          // Price
          Expanded(
            flex: 3,
            child: Text(
              'inventory.price_per_day'
                  .tr(namedArgs: {'price': item.defaultPrice.toStringAsFixed(0)}),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: ColorsManager.successText),
            ),
          ),

          // Total qty
          Expanded(
            flex: 2,
            child: _QtyBadge(value: item.totalQty),
          ),

          // Available qty
          Expanded(
            flex: 2,
            child: _QtyBadge(
              value: item.availableQty,
              highlight: item.availableQty == 0,
            ),
          ),

          // Status
          Expanded(
            flex: 2,
            child: StatusChip(
              label: _statusKey.tr(),
              status: _chipStatus,
            ),
          ),

          // Actions
          SizedBox(
            width: 100.w,
            child: FittedBox(
              fit: BoxFit.scaleDown, // 👈 التعديل السحري هنا
              alignment: Alignment.center, // عشان يفضل في النص
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18.r, color: ColorsManager.primaryColor),
                    onPressed: onEdit,
                    tooltip: 'inventory.action_edit'.tr(),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 18.r, color: ColorsManager.errorFill),
                    onPressed: () => _onDelete(context),
                    tooltip: 'inventory.action_delete'.tr(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBadge extends StatelessWidget {
  final int value;
  final bool highlight;

  const _QtyBadge({required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32.r,
      height: 32.r,
      decoration: BoxDecoration(
        color: highlight
            ? ColorsManager.errorSurface
            : ColorsManager.primaryLight,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: highlight
                ? ColorsManager.errorText
                : ColorsManager.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}