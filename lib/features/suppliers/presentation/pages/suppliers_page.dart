// lib/features/suppliers/presentation/pages/suppliers_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/core/widgets/page_header.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/pages/create_supplier_invoice_page.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/widgets/supplier_form_dialog.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/widgets/supplier_invoice_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/widgets/app_card.dart';
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
                  onPressed: _isExporting ? null : () async {
                    setState(() => _isExporting = true);
                    context.showInfo('جاري تصدير التقرير... ⏳');
                    final success = await context.read<SuppliersCubit>().exportSuppliersToExcel();
                    if (mounted) {
                      setState(() => _isExporting = false);
                      if (success) {
                        context.showSuccess('تم تصدير تقرير الموردين بنجاح ✓');
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

// ─── Desktop split layout ─────────────────────────────────────────────────────

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
                right: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: const _SupplierListPanel(),
          ),
        ),
        const Expanded(child: _DetailPanel()),
      ],
    );
  }
}

// ─── Supplier list panel ──────────────────────────────────────────────────────

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
            icon:       Icons.cloud_off_rounded,
            title:      'فشل في التحميل',
            subtitle:   state.errorMessage ?? '',
            isFullPage: false,
            actionLabel:    'إعادة المحاولة',
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
          itemCount: state.filtered.length,
          itemBuilder: (context, i) {
            final supplier = state.filtered[i];
            final isSelected = state.selectedSupplier?.id == supplier.id;
            return _SupplierListItem(
              supplier:   supplier,
              isSelected: isSelected,
              onTap:      () => context.read<SuppliersCubit>().selectSupplier(supplier),
              onEdit: () => showSupplierFormDialog(context, initialSupplier: supplier),
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
        color:  isSelected ? ColorsManager.primaryColor.withOpacity(0.08) : Colors.transparent,
        border: isSelected
            ? const Border(left: BorderSide(color: ColorsManager.primaryColor, width: 3))
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
                backgroundColor: isSelected ? ColorsManager.primaryColor : ColorsManager.primaryLight,
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
                          color:      isSelected ? ColorsManager.primaryColor : theme.textTheme.bodyMedium?.color,
                        ),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis),
                    if (supplier.phone != null)
                      Text(supplier.phone!, style: theme.textTheme.labelSmall),
                    if (supplier.balance > 0)
                      Text(
                        'مديونية: ${supplier.balance.toStringAsFixed(0)} $cur',
                        style: theme.textTheme.labelSmall?.copyWith(
                            color:      ColorsManager.errorText,
                            fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18.r, color: ColorsManager.defaultTextSecondary),
                padding:     EdgeInsets.zero,
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 16.r, color: ColorsManager.primaryColor),
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

// ─── Detail panel ─────────────────────────────────────────────────────────────

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

        // 🚨 السحر هنا: بنجيب أحدث نسخة من بيانات المورد من اللستة اللي اتحدثت 🚨
        final freshSupplier = state.suppliers.where((s) => s.id == state.selectedSupplier!.id).firstOrNull ?? state.selectedSupplier!;

        if (state.selectedInvoice != null) {
          // بنجيب أحدث نسخة من بيانات الفاتورة لو مفتوحة
          final freshInvoice = state.invoices.where((i) => i.id == state.selectedInvoice!.id).firstOrNull ?? state.selectedInvoice!;
          return _InvoiceDetailView(
            invoice:    freshInvoice,
            supplierId: freshSupplier.id,
          );
        }

        return _SupplierDetailView(supplier: freshSupplier);
      },
    );
  }
}

// ─── Supplier detail view ─────────────────────────────────────────────────────

class _SupplierDetailView extends StatelessWidget {
  final SupplierEntity supplier;
  const _SupplierDetailView({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color:  theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              // 🚨 زرار الرجوع للموبايل فقط 🚨
              if (MediaQuery.of(context).size.width < 900)
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 18.r),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis),
                    Text('سجل الفواتير', style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
              SizedBox(width: 12.w),
              ElevatedButton.icon(
                onPressed: () {
                  final cubit = context.read<SuppliersCubit>();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: context.read<SuppliersCubit>()),
                          BlocProvider(create: (_) => di.sl<InventoryCubit>()..fetchItems()),
                        ],
                        child: CreateSupplierInvoicePage(supplier: supplier),
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primaryColor,
                  foregroundColor: Colors.white,
                  elevation:       0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                ),
                icon:  Icon(Icons.add, size: 18.r),
                label: Text('فاتورة جديدة', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        // Stats + invoices
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SupplierStatsCard(supplier: supplier),
                SizedBox(height: 20.h),
                _InvoicesList(supplierId: supplier.id),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SupplierStatsCard extends StatelessWidget {
  final SupplierEntity supplier;
  const _SupplierStatsCard({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius:          22.r,
                backgroundColor: ColorsManager.primaryColor,
                child: Text(
                  supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(supplier.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        maxLines:  1,
                        overflow:  TextOverflow.ellipsis),
                    if (supplier.phone != null)
                      Text(supplier.phone!, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                'منذ ${DateFormat('yyyy').format(supplier.createdAt)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          SizedBox(height: 16.h),
          // Balance card
          AppCard(
            color:   supplier.balance > 0 ? ColorsManager.errorFill.withOpacity(0.06) : ColorsManager.successFill.withOpacity(0.06),
            variant: AppCardVariant.outlined,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Icon(
                  supplier.balance > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                  size:  20.r,
                  color: supplier.balance > 0 ? ColorsManager.errorText : ColorsManager.successText,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    supplier.balance > 0 ? 'المديونية الإجمالية' : 'لا توجد مديونية',
                    style: TextStyle(fontSize: 13.sp, color: supplier.balance > 0 ? ColorsManager.errorText : ColorsManager.successText),
                  ),
                ),
                Text(
                  '$cur ${supplier.balance.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w800, color: supplier.balance > 0 ? ColorsManager.errorText : ColorsManager.successText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicesList extends StatelessWidget {
  final String supplierId;
  const _InvoicesList({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.isLoading && state.invoices.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }

        if (state.hasError) {
          return EmptyStateWidget(
            icon:            Icons.cloud_off_rounded,
            title:           'فشل في تحميل الفواتير',
            subtitle:        state.errorMessage ?? '',
            isFullPage:      false,
            actionLabel:     'إعادة المحاولة',
            onActionPressed: () => context.read<SuppliersCubit>().fetchSupplierInvoices(supplierId),
          );
        }

        if (state.invoices.isEmpty) {
          return EmptyStateWidget(
            icon:       Icons.receipt_long_outlined,
            title:      'لا توجد فواتير',
            subtitle:   'اضغط على "فاتورة جديدة" لإضافة فاتورة',
            isFullPage: false,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الفواتير', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            SizedBox(height: 10.h),
            ...state.invoices.map((inv) => Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: SupplierInvoiceTile(
                invoice:    inv,
                supplierId: supplierId,
                onTap:      () => context.read<SuppliersCubit>().selectInvoice(inv.id),
              ),
            )),
          ],
        );
      },
    );
  }
}

// ─── Invoice detail view ──────────────────────────────────────────────────────

class _InvoiceDetailView extends StatelessWidget {
  final dynamic invoice;
  final String  supplierId;

  const _InvoiceDetailView({required this.invoice, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Back header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color:  theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, size: 18.r),
                onPressed: () => context.read<SuppliersCubit>().clearSelectedInvoice(),
              ),
              Text('تفاصيل الفاتورة', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp, color: theme.textTheme.titleSmall?.color)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: SupplierInvoiceDetailCard(invoice: invoice, supplierId: supplierId),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile body ──────────────────────────────────────────────────────────────

class _MobileBody extends StatelessWidget {
  const _MobileBody();

  @override
  Widget build(BuildContext context) {
    // 🚨 السحر هنا: بنراقب لو اليوزر داس على مورد، نفتحله التفاصيل في صفحة جديدة 🚨
    return BlocListener<SuppliersCubit, SuppliersState>(
      listenWhen: (prev, current) => prev.selectedSupplier == null && current.selectedSupplier != null,
      listener: (context, state) {
        if (state.selectedSupplier != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SuppliersCubit>(),
                child: Scaffold(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  body: const SafeArea(child: _DetailPanel()),
                ),
              ),
            ),
          ).then((_) {
            // لما يعمل Back من شاشة الموبايل، نفضي السليكت عشان يقدر يدوس تاني
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