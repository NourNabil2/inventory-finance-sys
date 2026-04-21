import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/inventory_desktop_table.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/inventory_mobile_grid.dart';

/// Main content widget for inventory page
/// 
/// Displays items in either a desktop table or mobile grid layout
/// based on screen width
class InventoryContent extends StatelessWidget {
  final List<ItemEntity> items;
  final int totalCount;
  final VoidCallback? onAddItem;

  const InventoryContent({
    super.key,
    required this.items,
    required this.totalCount,
    this.onAddItem,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.inventory_2_outlined,
        title: 'inventory.empty_title'.tr(),
        subtitle: 'inventory.empty_sub'.tr(),
        isFullPage: false,
        actionLabel: 'inventory.add_item'.tr(),
        onActionPressed: onAddItem,
      );
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Column(
      children: [
        // Items count bar
        _ItemsCountBar(
          filteredCount: items.length,
          totalCount: totalCount,
        ),

        // Content based on screen size
        Expanded(
          child: isDesktop
              ? InventoryDesktopTable(items: items)
              : InventoryMobileGrid(items: items),
        ),
      ],
    );
  }
}

/// Widget showing the count of filtered vs total items
class _ItemsCountBar extends StatelessWidget {
  final int filteredCount;
  final int totalCount;

  const _ItemsCountBar({
    required this.filteredCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Text(
          'inventory.items_count'.tr(namedArgs: {
            'count': '$filteredCount',
            'total': '$totalCount',
          }),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// Error content widget for inventory page
class InventoryErrorContent extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const InventoryErrorContent({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'inventory.load_error'.tr(),
      subtitle: message,
      isFullPage: false,
      actionLabel: 'common.retry'.tr(),
      onActionPressed: onRetry,
    );
  }
}
