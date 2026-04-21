import 'package:bungee_manage_sys/features/inventory/presentation/widgets/item_form_dialog.dart' show showItemFormDialog;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/item_card.dart';

/// Mobile grid view for inventory items
class InventoryMobileGrid extends StatelessWidget {
  final List<ItemEntity> items;
  final VoidCallback? onEditItem;

  const InventoryMobileGrid({
    super.key,
    required this.items,
    this.onEditItem,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(16.r),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 0.75,
      ),
      itemCount: items.length,
      itemBuilder: (_, index) => ItemCard(
        item: items[index],
        onEdit: () => showItemFormDialog(context, initialItem: items[index]), // ← Edit mode
      ),
    );
  }
}
