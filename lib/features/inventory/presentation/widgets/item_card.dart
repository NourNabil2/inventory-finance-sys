// lib/features/inventory/presentation/widgets/item_card.dart

import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/confirmation_dialog.dart';
import 'package:bungee_manage_sys/core/widgets/custom_network_image.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ItemCard extends StatelessWidget {
  final ItemEntity item;
  final VoidCallback? onEdit;

  const ItemCard({super.key, required this.item, this.onEdit});

  ChipStatus get _chipStatus => switch (item.status) {
    ItemStatus.available  => ChipStatus.available,
    ItemStatus.rented     => ChipStatus.rented,
    ItemStatus.maintenance => ChipStatus.maintenance,
    ItemStatus.reserved   => ChipStatus.reserved,
  };

  String get _statusKey => switch (item.status) {
    ItemStatus.available  => 'inventory.status_available',
    ItemStatus.rented     => 'inventory.status_rented',
    ItemStatus.maintenance => 'inventory.status_maintenance',
    ItemStatus.reserved   => 'inventory.status_reserved',
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
      await context.read<InventoryCubit>().deleteItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.06),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                child: CustomNetworkImage(
                  imageUrl: item.imageUrl,
                  width: double.infinity,
                  height: 130.h,
                  fit: BoxFit.cover,
                ),
              ),
              // Status badge over the image
              Positioned(
                top: 8.h,
                right: 8.w,
                child: StatusChip(
                  label: _statusKey.tr(),
                  status: _chipStatus,
                ),
              ),
              // Actions menu
              Positioned(
                top: 4.h,
                left: 4.w,
                child: _ActionsMenu(
                  onEdit: onEdit,
                  onDelete: () => _onDelete(context),
                ),
              ),
            ],
          ),

          // ── Info ───────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name
                Text(
                  item.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                if (item.model != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    item.model!,
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                SizedBox(height: 8.h),

                // Price
                Text(
                  'inventory.price_per_day'.tr(namedArgs: {
                    'price': item.defaultPrice.toStringAsFixed(0),
                  }),
                  style: Theme.of(context).textTheme.labelLarge,
                ),

                SizedBox(height: 6.h),

                // Qty row
                Row(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14.r,
                      color: Theme.of(context).iconTheme.color,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'inventory.qty_display'.tr(namedArgs: {
                        'available': '${item.availableQty}',
                        'total':     '${item.totalQty}',
                      }),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Actions popup menu ───────────────────────────────────────────────────────

class _ActionsMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  const _ActionsMenu({this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor.withOpacity(0.85),
      borderRadius: BorderRadius.circular(8.r),
      child: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, size: 18.r),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r)),
        onSelected: (val) {
          if (val == 'edit')   onEdit?.call();
          if (val == 'delete') onDelete();
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_outlined,
                    size: 16.r, color: ColorsManager.primaryColor),
                SizedBox(width: 8.w),
                Text('inventory.action_edit'.tr(),
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline,
                    size: 16.r, color: ColorsManager.errorFill),
                SizedBox(width: 8.w),
                Text('inventory.action_delete'.tr(),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: ColorsManager.errorFill)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}