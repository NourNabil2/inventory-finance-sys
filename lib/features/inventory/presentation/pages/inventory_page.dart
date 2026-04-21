// lib/features/inventory/presentation/pages/inventory_page.dart
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/item_form_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/widgets/page_header.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/inventory_content.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/widgets/inventory_filter_bar.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryCubit, InventoryState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        return Column(
          children: [
            PageHeader(
              titleKey: 'inventory.title',
              subtitleKey: 'inventory.subtitle',
              actionWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.w),
                child: OutlinedButton.icon(
                  onPressed: _isExporting ? null : () async {
                    setState(() => _isExporting = true);
                    context.showInfo('جاري تصدير التقرير... ⏳');

                    final success = await context.read<InventoryCubit>().exportInventoryToExcel();

                    if (mounted) {
                      setState(() => _isExporting = false);
                      if (success) {
                        context.showSuccess('تم تصدير جرد المخزن بنجاح ✓');
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.successText,
                    side: const BorderSide(color: ColorsManager.successText),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  icon: _isExporting
                      ? SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: ColorsManager.successText)
                  )
                      : const Icon(Icons.file_download_outlined),
                  label: Text(
                    _isExporting ? 'جاري التصدير...' : 'تصدير Excel',
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),

              actionButton: PageHeaderAction(
                textKey: 'inventory.add_item',
                icon: Icons.add,
                onPressed: () => _showAddItemDialog(context),
              ),
            ),

            // Filter bar
            const InventoryFilterBar(),

            // Main content based on state
            Expanded(child: _buildContent(context, state)),
          ],
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, InventoryState state) {
    if (state is InventoryError) {
      context.showError(
        state.message,
        actionLabel: 'common.retry'.tr(),
        onAction: () => context.read<InventoryCubit>().fetchItems(),
      );
    }
  }

  Widget _buildContent(BuildContext context, InventoryState state) {
    return switch (state) {
      InventoryInitial() || InventoryLoading() =>
      const Center(child: CircularProgressIndicator()),

      InventoryError(:final message) => InventoryErrorContent(
        message: message,
        onRetry: () => context.read<InventoryCubit>().fetchItems(),
      ),

      InventoryLoaded(:final filtered, :final items) => InventoryContent(
        items: filtered,
        totalCount: items.length,
        onAddItem: () => _showAddItemDialog(context),
      ),
    };
  }

  void _showAddItemDialog(BuildContext context) {
    showItemFormDialog(context);
  }
}