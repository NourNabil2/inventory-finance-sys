// lib/features/customers/presentation/widgets/customer_list_item.dart
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomerListItem extends StatelessWidget {
  final CustomerEntity customer;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CustomerListItem({
    super.key,
    required this.customer,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? ColorsManager.primaryColor.withOpacity(0.08) : Colors.transparent,
        border: isSelected ? const Border(left: BorderSide(color: ColorsManager.primaryColor, width: 3)) : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              _Avatar(name: customer.name, isSelected: isSelected),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ColorsManager.primaryColor : theme.textTheme.bodyMedium?.color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (customer.phone != null && customer.phone!.isNotEmpty)
                      Text(customer.phone!, style: theme.textTheme.labelSmall),
                    if (customer.totalDebt > 0)
                      Text(
                        'customers.debt_label'.tr(namedArgs: {
                          'amount': customer.totalDebt.toStringAsFixed(0),
                          'currency': 'dashboard.currency'.tr(),
                        }),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ColorsManager.errorText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              _ActionMenu(onEdit: onEdit, onDelete: onDelete),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  final bool isSelected;

  const _Avatar({required this.name, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20.r,
      backgroundColor: isSelected ? ColorsManager.primaryColor : ColorsManager.primaryLight,
      child: Text(
        name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?',
        style: TextStyle(
          color: isSelected ? Colors.white : ColorsManager.primaryColor,
          fontWeight: FontWeight.w700,
          fontSize: 14.sp,
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ActionMenu({required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 18.r, color: ColorsManager.defaultTextSecondary),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 16.r, color: ColorsManager.primaryColor),
              SizedBox(width: 8.w),
              Text('common.edit'.tr(), style: TextStyle(fontSize: 13.sp)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 16.r, color: ColorsManager.errorFill),
              SizedBox(width: 8.w),
              Text('common.delete'.tr(), style: TextStyle(fontSize: 13.sp, color: ColorsManager.errorText)),
            ],
          ),
        ),
      ],
      onSelected: (v) {
        if (v == 'edit') onEdit();
        if (v == 'delete') onDelete();
      },
    );
  }
}