// lib/features/suppliers/presentation/pages/suppliers_page.dart
//
// Main suppliers page — uses SupplierUnifiedDetailView instead of
// the old _SupplierDetailView / _SupplierStatsCard combo.

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/core/widgets/page_header.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/pages/supplier_unified_detail_page.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/widgets/supplier_form_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/app_text_feild.dart';

class SuppliersPage extends StatelessWidget {
  const SuppliersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<SuppliersCubit>()..fetchSuppliers(),
      child: const _SuppliersLayout(),
    );
  }
}

class _SuppliersLayout extends StatefulWidget {
  const _SuppliersLayout();

  @override
  State<_SuppliersLayout> createState() => _SuppliersLayoutState();
}

class _SuppliersLayoutState extends State<_SuppliersLayout> {
  bool get _isDesktop => MediaQuery.of(context).size.width >= 900;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SuppliersCubit, SuppliersState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          context.showError(state.errorMessage!);
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Column(
          children: [
            PageHeader(
              titleKey: 'الموردين',
              actionWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.w),
                child: OutlinedButton.icon(
                  onPressed: _isExporting
                      ? null
                      : () async {
                    setState(() => _isExporting = true);
                    context.showInfo('جاري تصدير التقرير... ⏳');
                    final success = await context
                        .read<SuppliersCubit>()
                        .exportSuppliersToExcel();
                    if (mounted) {
                      setState(() => _isExporting = false);
                      if (success) {
                        context.showSuccess(
                            'تم تصدير تقرير الموردين بنجاح ✓');
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.successText,
                    side:  const BorderSide(color: ColorsManager.successText),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                        horizontal: 16.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                  icon: _isExporting
                      ? SizedBox(
                      width:  16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ColorsManager.successText))
                      : const Icon(Icons.file_download_outlined),
                  label: Text(
                    _isExporting ? 'جاري التصدير...' : 'تصدير Excel',
                    style: TextStyle(
                        fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              actionButton: PageHeaderAction(
                textKey:   'إضافة مورد',
                icon:      Icons.add,
                onPressed: () => showSupplierFormDialog(context),
              ),
            ),
            Expanded(
              child: _isDesktop
                  ? const _DesktopBody()
                  : const _MobileBody(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Desktop split layout ─────────────────────────────────────

class _DesktopBody extends StatelessWidget {
  const _DesktopBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 300,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                  right: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: const _SupplierListPanel(),
          ),
        ),
        const Expanded(child: _DetailPanel()),
      ],
    );
  }
}

// ─── Supplier list panel ──────────────────────────────────────

class _SupplierListPanel extends StatefulWidget {
  const _SupplierListPanel();

  @override
  State<_SupplierListPanel> createState() => _SupplierListPanelState();
}

class _SupplierListPanelState extends State<_SupplierListPanel> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12.w),
          child: AppTextFieldFactory.search(
            controller: _searchCtrl,
            hintText:   'بحث عن مورد...',
            onChanged:  (q) => context.read<SuppliersCubit>().search(q),
          ),
        ),
        Expanded(child: _SupplierListBody()),
      ],
    );
  }
}

class _SupplierListBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.isLoading && state.suppliers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.hasError && state.suppliers.isEmpty) {
          return EmptyStateWidget(
            icon:            Icons.cloud_off_rounded,
            title:           'فشل في التحميل',
            subtitle:        state.errorMessage ?? '',
            isFullPage:      false,
            actionLabel:     'إعادة المحاولة',
            onActionPressed: () =>
                context.read<SuppliersCubit>().fetchSuppliers(),
          );
        }
        if (!state.hasSuppliers) {
          return EmptyStateWidget(
            icon:       Icons.storefront_outlined,
            title:      state.searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا يوجد موردون',
            subtitle:   state.searchQuery.isNotEmpty ? '' : 'اضغط على "إضافة مورد" للبدء',
            isFullPage: false,
          );
        }
        return ListView.builder(
          itemCount:   state.filtered.length,
          itemBuilder: (context, i) {
            final supplier   = state.filtered[i];
            final isSelected = state.selectedSupplier?.id == supplier.id;
            return _SupplierListItem(
              supplier:   supplier,
              isSelected: isSelected,
              onTap:      () =>
                  context.read<SuppliersCubit>().selectSupplier(supplier),
              onEdit: () =>
                  showSupplierFormDialog(context, initialSupplier: supplier),
            );
          },
        );
      },
    );
  }
}

class _SupplierListItem extends StatelessWidget {
  final SupplierEntity supplier;
  final bool           isSelected;
  final VoidCallback   onTap;
  final VoidCallback   onEdit;

  const _SupplierListItem({
    required this.supplier,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color:  isSelected
            ? ColorsManager.primaryColor.withOpacity(0.08)
            : Colors.transparent,
        border: isSelected
            ? const Border(
            left: BorderSide(color: ColorsManager.primaryColor, width: 3))
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: isSelected
                    ? ColorsManager.primaryColor
                    : ColorsManager.primaryLight,
                child: Text(
                  supplier.name.isEmpty ? '?' : supplier.name[0].toUpperCase(),
                  style: TextStyle(
                      color:      isSelected ? Colors.white : ColorsManager.primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize:   14.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? ColorsManager.primaryColor
                              : theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis),
                    if (supplier.phone != null)
                      Text(supplier.phone!,
                          style: theme.textTheme.labelSmall),
                    // Show both balances compactly
                    if (supplier.balance > 0 || supplier.serviceDebt > 0)
                      Row(
                        children: [
                          if (supplier.balance > 0)
                            Text(
                              'له: ${supplier.balance.toStringAsFixed(0)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color:      ColorsManager.errorText,
                                  fontWeight: FontWeight.w600),
                            ),
                          if (supplier.balance > 0 && supplier.serviceDebt > 0)
                            Text(' · ',
                                style: theme.textTheme.labelSmall?.copyWith(
                                    color: ColorsManager.defaultTextSecondary)),
                          if (supplier.serviceDebt > 0)
                            Text(
                              'عليه: ${supplier.serviceDebt.toStringAsFixed(0)}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color:      ColorsManager.successText,
                                  fontWeight: FontWeight.w600),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert,
                    size: 18.r, color: ColorsManager.defaultTextSecondary),
                padding:     EdgeInsets.zero,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined,
                          size: 16.r, color: ColorsManager.primaryColor),
                      SizedBox(width: 8.w),
                      Text('تعديل', style: TextStyle(fontSize: 13.sp)),
                    ]),
                  ),
                ],
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Detail panel ─────────────────────────────────────────────

class _DetailPanel extends StatelessWidget {
  const _DetailPanel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.selectedSupplier == null) {
          return EmptyStateWidget(
            icon:       Icons.storefront_outlined,
            title:      'اختر مورداً',
            subtitle:   '',
            isFullPage: false,
          );
        }

        final freshSupplier = state.suppliers
            .where((s) => s.id == state.selectedSupplier!.id)
            .firstOrNull ??
            state.selectedSupplier!;

        return SupplierUnifiedDetailView(supplier: freshSupplier);
      },
    );
  }
}

// ─── Mobile body ──────────────────────────────────────────────

class _MobileBody extends StatelessWidget {
  const _MobileBody();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SuppliersCubit, SuppliersState>(
      listenWhen: (prev, current) =>
      prev.selectedSupplier == null && current.selectedSupplier != null,
      listener: (context, state) {
        if (state.selectedSupplier != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SuppliersCubit>(),
                child: Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: SafeArea(
                    child: SupplierUnifiedDetailView(
                        supplier: state.selectedSupplier!),
                  ),
                ),
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<SuppliersCubit>().clearSelection();
            }
          });
        }
      },
      child: const _SupplierListPanel(),
    );
  }
}