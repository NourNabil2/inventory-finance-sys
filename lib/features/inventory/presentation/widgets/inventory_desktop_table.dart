import 'package:bungee_manage_sys/features/inventory/presentation/widgets/item_form_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/inventory_table_row.dart';

/// Desktop table view for inventory items
class InventoryDesktopTable extends StatelessWidget {
  final List<ItemEntity> items;
  final VoidCallback? onEditItem;

  const InventoryDesktopTable({
    super.key,
    required this.items,
    this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        children: [
          // Table header
          const _TableHeader(),
          Divider(color: Theme.of(context).dividerColor, height: 1),
          // Table rows
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  Divider(color: Theme.of(context).dividerColor, height: 1),
              itemBuilder: (_, index) => InventoryTableRow(
                item: items[index],
                index: index,
                onEdit: () => showItemFormDialog(context, initialItem: items[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Table header widget with column labels
class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          // 👈 الصورة هنا 60.w
          SizedBox(width: 65.w, child: _HeaderText('inventory.col_image')),
          const Expanded(flex: 4, child: _HeaderText('inventory.col_name')),
          const Expanded(flex: 3, child: _HeaderText('inventory.col_price')),
          const Expanded(flex: 2, child: _HeaderText('inventory.col_total')),
          const Expanded(flex: 2, child: _HeaderText('inventory.col_available')),
          const Expanded(flex: 2, child: _HeaderText('inventory.col_status')),
          // 👈 عدلنا دي لـ 100.w عشان تطابق الأزرار اللي تحت
          SizedBox(width: 100.w, child: _HeaderText('inventory.col_actions')),
        ],
      ),
    );
  }
}

/// Header text widget for table columns
class _HeaderText extends StatelessWidget {
  final String translationKey;

  const _HeaderText(this.translationKey);

  @override
  Widget build(BuildContext context) {
    return Text(
      translationKey.tr(),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
