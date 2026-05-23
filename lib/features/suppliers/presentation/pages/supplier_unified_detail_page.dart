// lib/features/suppliers/presentation/pages/supplier_unified_detail_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/pages/create_supplier_invoice_page.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/pages/edit_supplier_invoice_page.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/widgets/supplier_invoice_widgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../widgets/clearing_dialog.dart';
import '../widgets/flexible_clearing_dialog.dart' show showFlexibleClearingDialog;

// ─────────────────────────────────────────────────────────────────────────────
// Entry point
// ─────────────────────────────────────────────────────────────────────────────

class SupplierUnifiedDetailView extends StatelessWidget {
  final SupplierEntity supplier;
  const SupplierUnifiedDetailView({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        final fresh = state.suppliers
            .where((s) => s.id == supplier.id)
            .firstOrNull ?? supplier;

        // ── Purchase invoice detail ──
        if (state.selectedInvoice != null) {
          final freshInv = state.invoices
              .where((i) => i.id == state.selectedInvoice!.id)
              .firstOrNull ?? state.selectedInvoice!;
          return _InvoiceDetailShell(invoice: freshInv, supplierId: fresh.id);
        }

        // ── Service invoice detail (inline, same flow) ──
        if (state.selectedServiceInvoice != null) {
          final freshSvc = state.serviceInvoices
              .where((i) => i.id == state.selectedServiceInvoice!.id)
              .firstOrNull ?? state.selectedServiceInvoice!;
          return _ServiceInvoiceDetailShell(invoice: freshSvc, supplierId: fresh.id);
        }

        return _UnifiedProfileShell(supplier: fresh);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile shell
// ─────────────────────────────────────────────────────────────────────────────

class _UnifiedProfileShell extends StatelessWidget {
  final SupplierEntity supplier;
  const _UnifiedProfileShell({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileHeader(supplier: supplier),
        _LedgerSummaryBar(supplier: supplier),
        _TabBar(supplier: supplier),
        const Expanded(child: _TabBody()),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  final SupplierEntity supplier;
  const _ProfileHeader({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color:  theme.cardColor,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: IconButton(
                icon:      Icon(Icons.arrow_back_ios, size: 18.r),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
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
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (supplier.phone != null)
                  Text(supplier.phone!, style: theme.textTheme.labelSmall),
                Text('منذ ${DateFormat('yyyy').format(supplier.createdAt)}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          _HeaderActions(supplier: supplier),
        ],
      ),
    );
  }
}

class _HeaderActions extends StatelessWidget {
  final SupplierEntity supplier;
  const _HeaderActions({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        final isClearing = state.isClearingInProgress;
        return Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => MultiBlocProvider(
                    providers: [
                      BlocProvider.value(value: context.read<SuppliersCubit>()),
                      BlocProvider(create: (_) => di.sl<InventoryCubit>()..fetchItems()),
                    ],
                    child: CreateSupplierInvoicePage(supplier: supplier),
                  ),
                ));
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsManager.primaryColor,
                side: const BorderSide(color: ColorsManager.primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              icon: Icon(Icons.add_circle_outline, size: 16.r),
              label: Text('فاتورة جديدة',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),
            if (supplier.balance > 0 || supplier.serviceDebt > 0)
              ElevatedButton.icon(
                onPressed: isClearing
                    ? null
                    : () async {
                  final done = await showFlexibleClearingDialog(
                      context: context, supplier: supplier);
                  if (done && context.mounted) {
                    context.read<SuppliersCubit>().resetClearingStatus();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                icon: isClearing
                    ? SizedBox(width: 14.r, height: 14.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.compare_arrows_rounded, size: 16.r),
                label: Text('تسوية',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ledger summary bar
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerSummaryBar extends StatelessWidget {
  final SupplierEntity supplier;
  const _LedgerSummaryBar({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();
    final net = supplier.netPosition;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color:  Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          Expanded(child: _BalanceCard(label: 'مديونية له', subLabel: 'نحن ندفع لهم',
              amount: supplier.balance, cur: cur, color: ColorsManager.errorText,
              fillColor: ColorsManager.errorFill.withOpacity(0.07), icon: Icons.arrow_circle_down_outlined)),
          SizedBox(width: 8.w),
          Expanded(child: _BalanceCard(label: 'مديونية عليه', subLabel: 'يدفعون لنا',
              amount: supplier.serviceDebt, cur: cur, color: ColorsManager.successText,
              fillColor: ColorsManager.successFill.withOpacity(0.07), icon: Icons.arrow_circle_up_outlined)),
          SizedBox(width: 8.w),
          Expanded(child: _BalanceCard(
              label: 'صافي المركز',
              subLabel: net >= 0 ? 'لصالحهم' : 'لصالحنا',
              amount: net.abs(), cur: cur,
              color: net >= 0 ? ColorsManager.warningText : ColorsManager.primaryColor,
              fillColor: (net >= 0 ? ColorsManager.warningSurface : ColorsManager.primaryColor).withOpacity(0.07),
              icon: net >= 0 ? Icons.balance_outlined : Icons.trending_up_rounded,
              prefixLabel: net < 0 ? '−' : null)),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String label, subLabel, cur;
  final double amount;
  final Color color, fillColor;
  final IconData icon;
  final String? prefixLabel;

  const _BalanceCard({
    required this.label, required this.subLabel, required this.amount,
    required this.cur, required this.color, required this.fillColor,
    required this.icon, this.prefixLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: fillColor, variant: AppCardVariant.outlined,
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13.r, color: color),
            SizedBox(width: 4.w),
            Expanded(child: Text(label,
                style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: color))),
          ]),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text('${prefixLabel ?? ''}$cur ${amount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: color)),
          ),
          Text(subLabel,
              style: TextStyle(fontSize: 9.sp, color: ColorsManager.defaultTextSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar & body
// ─────────────────────────────────────────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final SupplierEntity supplier;
  const _TabBar({required this.supplier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      buildWhen: (p, c) => p.activeTab != c.activeTab,
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(children: [
            _Tab(label: 'فواتير الشراء', icon: Icons.shopping_cart_outlined,
                isSelected: state.activeTab == SupplierLedgerTab.purchases,
                onTap: () => context.read<SuppliersCubit>().switchTab(SupplierLedgerTab.purchases)),
            _Tab(label: 'فواتير الخدمات', icon: Icons.receipt_outlined,
                isSelected: state.activeTab == SupplierLedgerTab.services,
                onTap: () => context.read<SuppliersCubit>().switchTab(SupplierLedgerTab.services)),
          ]),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(
                color: isSelected ? ColorsManager.primaryColor : Colors.transparent, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15.r, color: color),
              SizedBox(width: 6.w),
              Text(label, style: TextStyle(fontSize: 13.sp,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBody extends StatelessWidget {
  const _TabBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.activeTab == SupplierLedgerTab.purchases) {
          return _PurchaseInvoicesList(supplierId: state.selectedSupplier?.id ?? '');
        }
        return _ServiceInvoicesList(supplierId: state.selectedSupplier?.id ?? '');
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase invoices list
// ─────────────────────────────────────────────────────────────────────────────

class _PurchaseInvoicesList extends StatelessWidget {
  final String supplierId;
  const _PurchaseInvoicesList({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.isLoading && state.invoices.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        if (state.hasError) {
          return EmptyStateWidget(
            icon: Icons.cloud_off_rounded, title: 'فشل في تحميل الفواتير',
            subtitle: state.errorMessage ?? '', isFullPage: false,
            actionLabel: 'إعادة المحاولة',
            onActionPressed: () => context.read<SuppliersCubit>().fetchSupplierInvoices(supplierId),
          );
        }
        if (state.invoices.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.receipt_long_outlined, title: 'لا توجد فواتير شراء',
            subtitle: 'اضغط على "فاتورة شراء" لإضافة فاتورة', isFullPage: false,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.invoices.length,
          itemBuilder: (ctx, i) {
            final inv = state.invoices[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: SupplierInvoiceTile(
                invoice: inv,
                supplierId: supplierId,
                onTap: () => ctx.read<SuppliersCubit>().selectInvoice(inv.id),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service invoices list
// ─────────────────────────────────────────────────────────────────────────────

ChipStatus _getServiceChipStatus(ServiceInvoiceStatus s) => switch (s) {
  ServiceInvoiceStatus.paid    => ChipStatus.completed,
  ServiceInvoiceStatus.partial => ChipStatus.pending,
  ServiceInvoiceStatus.unpaid  => ChipStatus.reserved,
};

String _getServiceStatusLabel(ServiceInvoiceStatus s) => switch (s) {
  ServiceInvoiceStatus.paid    => 'مدفوعة',
  ServiceInvoiceStatus.partial => 'مدفوعة جزئياً',
  ServiceInvoiceStatus.unpaid  => 'غير مدفوعة',
};

class _ServiceInvoicesList extends StatelessWidget {
  final String supplierId;
  const _ServiceInvoicesList({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.isServiceInvoicesLoading && state.serviceInvoices.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        if (state.serviceInvoicesStatus == ServiceInvoicesStatus.failure) {
          return EmptyStateWidget(
            icon: Icons.cloud_off_rounded, title: 'فشل في تحميل فواتير الخدمات',
            subtitle: state.errorMessage ?? '', isFullPage: false,
            actionLabel: 'إعادة المحاولة',
            onActionPressed: () => context.read<SuppliersCubit>().fetchSupplierServiceInvoices(supplierId),
          );
        }
        if (state.serviceInvoices.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.receipt_outlined, title: 'لا توجد فواتير خدمات',
            subtitle: 'لم يتم إصدار أي فاتورة إيجار لهذا المورد بعد', isFullPage: false,
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: state.serviceInvoices.length,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _ServiceInvoiceTile(invoice: state.serviceInvoices[i], supplierId: supplierId),
          ),
        );
      },
    );
  }
}

class _ServiceInvoiceTile extends StatelessWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;
  const _ServiceInvoiceTile({required this.invoice, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();
    final fmt   = DateFormat('d MMM yyyy');

    return InkWell(
      onTap: () => context.read<SuppliersCubit>().selectServiceInvoice(invoice),
      borderRadius: BorderRadius.circular(8.r),
      child: AppCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            Container(
              width: 38.r, height: 38.r,
              decoration: BoxDecoration(
                color: ColorsManager.successFill.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.receipt_outlined, size: 18.r, color: ColorsManager.successText),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('فاتورة خدمة #${invoice.id.substring(0, 8).toUpperCase()}',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp,
                          color: theme.textTheme.bodyMedium?.color)),
                  SizedBox(height: 2.h),
                  Text(fmt.format(invoice.createdAt),
                      style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary)),
                  if (invoice.notes != null && invoice.notes!.isNotEmpty)
                    Text(invoice.notes!,
                        style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 🚨 إظهار السعر قبل الخصم (مشطوب) لو فيه خصم 🚨
                if (invoice.discount > 0)
                  Text('$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                      style: TextStyle(decoration: TextDecoration.lineThrough, fontSize: 11.sp,
                          color: ColorsManager.defaultTextSecondary)),
                // 🚨 إظهار الصافي 🚨
                Text('$cur ${invoice.netTotal.toStringAsFixed(0)}',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp,
                        color: ColorsManager.successText)),
                SizedBox(height: 4.h),
                StatusChip(label: _getServiceStatusLabel(invoice.status),
                    status: _getServiceChipStatus(invoice.status)),
                if (!invoice.isFullyPaid) ...[
                  SizedBox(height: 2.h),
                  Text('متبقي: $cur ${invoice.remaining.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10.sp, color: ColorsManager.errorText,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🆕 Invoice Detail Shell — مع أزرار تعديل وإلغاء
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceDetailShell extends StatelessWidget {
  final SupplierInvoiceEntity invoice;
  final String supplierId;

  const _InvoiceDetailShell({required this.invoice, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isCancelled = invoice.isCancelled;

    return Column(
      children: [
        // ── Header ──────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          decoration: BoxDecoration(
            color:  theme.cardColor,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Row(
            children: [
              IconButton(
                icon:      Icon(Icons.arrow_back_ios, size: 18.r),
                onPressed: () => context.read<SuppliersCubit>().clearSelectedInvoice(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('تفاصيل الفاتورة',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp,
                            color: theme.textTheme.titleSmall?.color)),
                    if (isCancelled)
                      Text('ملغية', style: TextStyle(fontSize: 11.sp, color: ColorsManager.errorText,
                          fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

              // ── 🆕 أزرار التعديل والإلغاء ──────────────────────────────
              if (!isCancelled) ...[
                // زرار تعديل
                BlocBuilder<SuppliersCubit, SuppliersState>(
                  builder: (ctx, state) => IconButton(
                    icon: Icon(Icons.edit_outlined, size: 20.r, color: ColorsManager.primaryColor),
                    tooltip: 'تعديل الفاتورة',
                    onPressed: state.isInvoiceEditLoading || state.isInvoiceCancelLoading
                        ? null
                        : () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => MultiBlocProvider(
                        providers: [
                          BlocProvider.value(value: context.read<SuppliersCubit>()),
                          BlocProvider(create: (_) => di.sl<InventoryCubit>()..fetchItems()),
                        ],
                        child: EditSupplierInvoicePage(
                            invoice: invoice, supplierId: supplierId),
                      ),
                    )),
                  ),
                ),

                // زرار إلغاء
                BlocBuilder<SuppliersCubit, SuppliersState>(
                  builder: (ctx, state) => IconButton(
                    icon: Icon(Icons.cancel_outlined, size: 20.r, color: ColorsManager.errorText),
                    tooltip: 'إلغاء الفاتورة',
                    onPressed: state.isInvoiceEditLoading || state.isInvoiceCancelLoading
                        ? null
                        : () => showCancelInvoiceDialog(
                      context: context,
                      invoice: invoice,
                      supplierId: supplierId,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // ── Body ────────────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // بانر الإلغاء لو الفاتورة ملغية
                if (isCancelled)
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color:        ColorsManager.errorText.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: ColorsManager.errorText.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: ColorsManager.errorText, size: 18.r),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            'هذه الفاتورة ملغية — لا تُحتسب في مديونية المورد',
                            style: TextStyle(fontSize: 12.sp, color: ColorsManager.errorText,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                SupplierInvoiceDetailCard(invoice: invoice, supplierId: supplierId),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service invoice detail shell — مع أزرار تعديل وإلغاء وجدول البنود
// ─────────────────────────────────────────────────────────────────────────────

class _ServiceInvoiceDetailShell extends StatelessWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;

  const _ServiceInvoiceDetailShell({required this.invoice, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();
    final fmt   = DateFormat('EEEE, d MMMM yyyy');

    return BlocConsumer<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) =>
      p.serviceInvoiceCancelStatus != c.serviceInvoiceCancelStatus ||
          p.serviceInvoiceEditStatus   != c.serviceInvoiceEditStatus,
      listener: (ctx, state) {
        if (state.serviceInvoiceCancelStatus == ServiceInvoiceCancelStatus.success) {
          ctx.showSuccess('تم إلغاء الفاتورة وتحديث مديونية المورد');
          ctx.read<SuppliersCubit>().clearSelectedServiceInvoice();
        } else if (state.serviceInvoiceCancelStatus == ServiceInvoiceCancelStatus.failure) {
          ctx.showError(state.errorMessage ?? 'فشل الإلغاء');
        }
        if (state.serviceInvoiceEditStatus == ServiceInvoiceEditStatus.success) {
          ctx.showSuccess('تم تعديل الفاتورة بنجاح');
        } else if (state.serviceInvoiceEditStatus == ServiceInvoiceEditStatus.failure) {
          ctx.showError(state.errorMessage ?? 'فشل التعديل');
        }
      },
      builder: (ctx, state) {
        final isEditLoading   = state.isServiceInvoiceEditLoading;
        final isCancelLoading = state.isServiceInvoiceCancelLoading;
        final busy = isEditLoading || isCancelLoading;

        return Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color:  theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon:      Icon(Icons.arrow_back_ios, size: 18.r),
                    onPressed: busy
                        ? null
                        : () => ctx.read<SuppliersCubit>().clearSelectedServiceInvoice(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تفاصيل فاتورة الخدمات',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15.sp,
                                color: theme.textTheme.titleSmall?.color)),
                        Text('#${invoice.id.substring(0, 8).toUpperCase()}',
                            style: TextStyle(fontSize: 11.sp,
                                color: ColorsManager.defaultTextSecondary)),
                      ],
                    ),
                  ),
                  // ── أزرار تعديل وإلغاء ──────────────────────────────────────
                  IconButton(
                    icon: isEditLoading
                        ? SizedBox(width: 18.r, height: 18.r,
                        child: const CircularProgressIndicator(strokeWidth: 2))
                        : Icon(Icons.edit_outlined, size: 20.r,
                        color: ColorsManager.primaryColor),
                    tooltip:  'تعديل الفاتورة',
                    onPressed: busy ? null : () => _showEditDialog(ctx),
                  ),
                  IconButton(
                    icon: isCancelLoading
                        ? SizedBox(width: 18.r, height: 18.r,
                        child: const CircularProgressIndicator(
                            strokeWidth: 2, color: ColorsManager.errorText))
                        : Icon(Icons.cancel_outlined, size: 20.r,
                        color: ColorsManager.errorText),
                    tooltip:  'إلغاء الفاتورة',
                    onPressed: busy ? null : () => _showCancelDialog(ctx),
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header card ──
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48.r, height: 48.r,
                                decoration: BoxDecoration(
                                  color: ColorsManager.successFill.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(Icons.receipt_outlined, size: 24.r,
                                    color: ColorsManager.successText),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('فاتورة خدمة',
                                        style: TextStyle(fontWeight: FontWeight.w700,
                                            fontSize: 15.sp,
                                            color: theme.textTheme.titleSmall?.color)),
                                    SizedBox(height: 2.h),
                                    Text(fmt.format(invoice.createdAt),
                                        style: TextStyle(fontSize: 12.sp,
                                            color: ColorsManager.defaultTextSecondary)),
                                    if (invoice.invoiceNumber.isNotEmpty)
                                      Text('رقم: ${invoice.invoiceNumber}',
                                          style: TextStyle(fontSize: 11.sp,
                                              color: ColorsManager.defaultTextSecondary)),
                                  ],
                                ),
                              ),
                              StatusChip(
                                label:  _getServiceStatusLabel(invoice.status),
                                status: _getServiceChipStatus(invoice.status),
                              ),
                            ],
                          ),
                          if (invoice.jobName != null && invoice.jobName!.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            _InfoRow(icon: Icons.movie_outlined,
                                text: 'مشروع: ${invoice.jobName!}'),
                          ],
                          if (invoice.production != null && invoice.production!.isNotEmpty)
                            _InfoRow(icon: Icons.business_outlined,
                                text: 'إنتاج: ${invoice.production!}'),
                          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                            SizedBox(height: 8.h),
                            _InfoRow(icon: Icons.notes_rounded, text: invoice.notes!),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // ── Payment progress card ──
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('حالة السداد',
                                  style: TextStyle(fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                      color: theme.textTheme.titleSmall?.color)),
                              Text('${invoice.paymentPercent.toStringAsFixed(0)}%',
                                  style: TextStyle(fontWeight: FontWeight.w700,
                                      fontSize: 13.sp,
                                      color: invoice.isFullyPaid
                                          ? ColorsManager.successFill
                                          : ColorsManager.primaryColor)),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value:           invoice.paymentPercent / 100,
                              minHeight:       8.h,
                              backgroundColor: theme.dividerColor,
                              valueColor: AlwaysStoppedAnimation(
                                  invoice.isFullyPaid
                                      ? ColorsManager.successFill
                                      : ColorsManager.primaryColor),
                            ),
                          ),
                          SizedBox(height: 16.h),
                          Wrap(
                            spacing:    8.w,
                            runSpacing: 12.h,
                            alignment:  WrapAlignment.spaceBetween,
                            children: [
                              _AmountItem(
                                label: 'الإجمالي (قبل)',
                                value: '$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                                color: theme.textTheme.bodyMedium?.color ?? Colors.black,
                              ),
                              if (invoice.discount > 0)
                                _AmountItem(
                                  label: 'الخصم',
                                  value: '-$cur ${invoice.discount.toStringAsFixed(0)}',
                                  color: ColorsManager.warningText,
                                ),
                              _AmountItem(
                                label: 'الصافي النهائي',
                                value: '$cur ${invoice.netTotal.toStringAsFixed(0)}',
                                color: ColorsManager.primaryColor,
                              ),
                              _AmountItem(
                                label: 'المدفوع',
                                value: '$cur ${invoice.paidAmount.toStringAsFixed(0)}',
                                color: ColorsManager.successText,
                              ),
                              _AmountItem(
                                label: 'المتبقي',
                                value: '$cur ${invoice.remaining.toStringAsFixed(0)}',
                                color: invoice.remaining > 0
                                    ? ColorsManager.errorText
                                    : ColorsManager.successText,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // ── 🆕 Items table ───────────────────────────────────────────
                    if (invoice.items.isNotEmpty) ...[
                      Text('الأصناف',
                          style: TextStyle(fontWeight: FontWeight.w600,
                              fontSize: 14.sp,
                              color: theme.textTheme.titleSmall?.color)),
                      SizedBox(height: 8.h),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.r),
                          child: Column(
                            children: [
                              // Table header
                              Container(
                                color:   theme.scaffoldBackgroundColor,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 10.h),
                                child: Row(children: [
                                  Expanded(flex: 4,
                                      child: Text('الصنف',
                                          style: TextStyle(fontSize: 11.sp,
                                              fontWeight: FontWeight.w600,
                                              color: ColorsManager.defaultTextSecondary))),
                                  _SvcColHdr('الكمية'),
                                  _SvcColHdr('الأيام'),
                                  _SvcColHdr('سعر/يوم'),
                                  _SvcColHdr('الإجمالي', end: true),
                                ]),
                              ),
                              ...invoice.items.map((item) => Column(children: [
                                Divider(height: 1, color: theme.dividerColor),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 10.h),
                                  child: Row(children: [
                                    Expanded(
                                      flex: 4,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.itemName ?? '-',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13.sp,
                                                  color: theme.textTheme.bodyMedium?.color),
                                              overflow: TextOverflow.ellipsis),
                                          if (item.itemModel != null)
                                            Text(item.itemModel!,
                                                style: TextStyle(fontSize: 10.sp,
                                                    color: ColorsManager.defaultTextSecondary)),
                                          if (item.isFullyReturned)
                                            Container(
                                              margin: EdgeInsets.only(top: 2.h),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 6.w, vertical: 1.h),
                                              decoration: BoxDecoration(
                                                color: ColorsManager.successFill.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4.r),
                                              ),
                                              child: Text('مُسترجع',
                                                  style: TextStyle(fontSize: 9.sp,
                                                      color: ColorsManager.successText,
                                                      fontWeight: FontWeight.w600)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    _SvcCell('${item.qty}'),
                                    _SvcCell('${item.days}'),
                                    _SvcCell(item.pricePerDay.toStringAsFixed(0)),
                                    _SvcCell(item.lineTotal.toStringAsFixed(0),
                                        end: true, bold: true),
                                  ]),
                                ),
                              ])),
                              // Footer totals
                              Divider(height: 1, color: theme.dividerColor),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 8.h),
                                child: Row(children: [
                                  Expanded(flex: 4,
                                      child: Text('الإجمالي',
                                          style: TextStyle(fontSize: 12.sp,
                                              color: theme.textTheme.bodyMedium?.color))),
                                  const _SvcCell(''), const _SvcCell(''),
                                  const _SvcCell(''),
                                  _SvcCell('$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                                      end: true),
                                ]),
                              ),
                              if (invoice.discount > 0)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 14.w, vertical: 8.h),
                                  child: Row(children: [
                                    Expanded(flex: 4,
                                        child: Text('الخصم',
                                            style: TextStyle(fontSize: 12.sp,
                                                color: ColorsManager.warningText))),
                                    const _SvcCell(''), const _SvcCell(''),
                                    const _SvcCell(''),
                                    _SvcCell(
                                        '-$cur ${invoice.discount.toStringAsFixed(0)}',
                                        end: true,
                                        color: ColorsManager.warningText),
                                  ]),
                                ),
                              Divider(height: 1, color: theme.dividerColor),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 14.w, vertical: 10.h),
                                child: Row(children: [
                                  Expanded(flex: 4,
                                      child: Text('الصافي النهائي',
                                          style: TextStyle(fontWeight: FontWeight.w700,
                                              fontSize: 13.sp,
                                              color: theme.textTheme.bodyMedium?.color))),
                                  const _SvcCell(''), const _SvcCell(''),
                                  const _SvcCell(''),
                                  _SvcCell(
                                      '$cur ${invoice.netTotal.toStringAsFixed(0)}',
                                      end: true, bold: true,
                                      color: ColorsManager.primaryColor),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 12.h),
                    ],

                    // ── Pay button ───────────────────────────────────────────────
                    if (!invoice.isFullyPaid)
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: busy ? null : () {
                            final cubit = ctx.read<SuppliersCubit>();
                            showDialog(
                              context: ctx,
                              builder: (_) => BlocProvider.value(
                                value: cubit,
                                child: _ServicePaymentDialog(
                                    invoice: invoice, supplierId: supplierId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManager.primaryColor,
                            foregroundColor: Colors.white,
                            elevation:       0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r)),
                          ),
                          icon:  Icon(Icons.payments_outlined, size: 20.r),
                          label: Text('تسجيل دفعة',
                              style: TextStyle(fontSize: 14.sp,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SuppliersCubit>(),
        child: _ServiceInvoiceEditDialog(invoice: invoice, supplierId: supplierId),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BlocProvider.value(
        value: context.read<SuppliersCubit>(),
        child: _ServiceInvoiceCancelDialog(invoice: invoice, supplierId: supplierId),
      ),
    );
  }
}

// ── Small helper widgets ──────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: 6.h),
    child: Row(children: [
      Icon(icon, size: 14.r, color: ColorsManager.defaultTextSecondary),
      SizedBox(width: 6.w),
      Expanded(child: Text(text,
          style: TextStyle(fontSize: 12.sp,
              color: ColorsManager.defaultTextSecondary))),
    ]),
  );
}

class _SvcColHdr extends StatelessWidget {
  final String text;
  final bool   end;
  const _SvcColHdr(this.text, {this.end = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 66.w,
    child: Text(text,
        style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600,
            color: ColorsManager.defaultTextSecondary),
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

class _SvcCell extends StatelessWidget {
  final String text;
  final bool   end;
  final bool   bold;
  final Color? color;
  const _SvcCell(this.text, {this.end = false, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 66.w,
    child: Text(text,
        style: TextStyle(fontSize: 13.sp,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color ?? Theme.of(context).textTheme.bodyMedium?.color),
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

// ── 🆕 Edit dialog ────────────────────────────────────────────────────────────

class _ServiceInvoiceEditDialog extends StatefulWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;
  const _ServiceInvoiceEditDialog({required this.invoice, required this.supplierId});

  @override
  State<_ServiceInvoiceEditDialog> createState() => _ServiceInvoiceEditDialogState();
}

class _ServiceInvoiceEditDialogState extends State<_ServiceInvoiceEditDialog> {
  late final TextEditingController _discCtrl;
  late final TextEditingController _notesCtrl;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _discCtrl  = TextEditingController(
        text: widget.invoice.discount.toStringAsFixed(0));
    _notesCtrl = TextEditingController(text: widget.invoice.notes ?? '');
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return BlocConsumer<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) =>
      p.serviceInvoiceEditStatus != c.serviceInvoiceEditStatus,
      listener: (ctx, state) {
        if (state.serviceInvoiceEditStatus == ServiceInvoiceEditStatus.success) {
          if (_isPopping || !mounted) return;
          _isPopping = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(ctx).pop();
          });
        } else if (state.serviceInvoiceEditStatus == ServiceInvoiceEditStatus.failure) {
          ctx.showError(state.errorMessage ?? 'فشل التعديل');
        }
      },
      builder: (ctx, state) {
        final loading = state.isServiceInvoiceEditLoading;
        final disc    = double.tryParse(_discCtrl.text) ?? 0;
        final net     = (widget.invoice.totalAmount - disc).clamp(0.0, double.infinity);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          title: Row(children: [
            Icon(Icons.edit_outlined, color: ColorsManager.primaryColor, size: 22.r),
            SizedBox(width: 8.w),
            Text('تعديل فاتورة الخدمات',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 400.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: ColorsManager.primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline, size: 14.r,
                        color: ColorsManager.primaryColor),
                    SizedBox(width: 8.w),
                    Expanded(child: Text(
                      'الإجمالي: $cur ${widget.invoice.totalAmount.toStringAsFixed(0)}'
                          '   →   صافي بعد الخصم: $cur ${net.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 12.sp,
                          color: ColorsManager.primaryColor,
                          fontWeight: FontWeight.w600),
                    )),
                  ]),
                ),
                SizedBox(height: 14.h),
                Text('خصم الفاتورة ($cur)',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleSmall?.color)),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _discCtrl,
                  enabled:    !loading,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    suffixText: cur,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
                SizedBox(height: 14.h),
                Text('ملاحظات',
                    style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
                        color: theme.textTheme.titleSmall?.color)),
                SizedBox(height: 6.h),
                TextFormField(
                  controller: _notesCtrl,
                  enabled:    !loading,
                  maxLines:   2,
                  decoration: InputDecoration(
                    hintText: 'ملاحظات (اختياري)',
                    border:   OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton.icon(
              onPressed: loading ? null : () {
                final disc = double.tryParse(_discCtrl.text) ?? 0;
                if (disc < 0) {
                  context.showError('الخصم لا يمكن أن يكون سالباً');
                  return;
                }
                final net = widget.invoice.totalAmount - disc;
                if (net < widget.invoice.paidAmount) {
                  context.showError(
                      'الصافي (${net.toStringAsFixed(0)}) أقل من المدفوع '
                          '(${widget.invoice.paidAmount.toStringAsFixed(0)})');
                  return;
                }
                context.read<SuppliersCubit>().editServiceInvoice(
                  invoiceId:       widget.invoice.id,
                  supplierId:      widget.supplierId,
                  discount:        disc,
                  notes:           _notesCtrl.text.trim().isEmpty
                      ? null : _notesCtrl.text.trim(),
                  deletedItemIds:  const [],
                  existingUpdates: const [],
                  newItems:        const [],
                );
              },
              icon: loading
                  ? SizedBox(width: 14.r, height: 14.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.save_outlined, size: 16.r),
              label: Text('حفظ التعديلات',
                  style: TextStyle(fontSize: 13.sp)),
              style: FilledButton.styleFrom(
                  backgroundColor: ColorsManager.primaryColor),
            ),
          ],
        );
      },
    );
  }
}

// ── 🆕 Cancel dialog ──────────────────────────────────────────────────────────

class _ServiceInvoiceCancelDialog extends StatefulWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;
  const _ServiceInvoiceCancelDialog({required this.invoice, required this.supplierId});

  @override
  State<_ServiceInvoiceCancelDialog> createState() =>
      _ServiceInvoiceCancelDialogState();
}

class _ServiceInvoiceCancelDialogState
    extends State<_ServiceInvoiceCancelDialog> {
  late final TextEditingController _reasonCtrl;
  bool _isPopping = false;

  @override
  void initState() {
    super.initState();
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    final cur = 'dashboard.currency'.tr();

    return BlocConsumer<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) =>
      p.serviceInvoiceCancelStatus != c.serviceInvoiceCancelStatus,
      listener: (ctx, state) {
        if (state.serviceInvoiceCancelStatus ==
            ServiceInvoiceCancelStatus.success) {
          if (_isPopping || !mounted) return;
          _isPopping = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            Navigator.of(ctx).pop();
          });
        } else if (state.serviceInvoiceCancelStatus ==
            ServiceInvoiceCancelStatus.failure) {
          if (!ctx.mounted) return;
          ctx.showError(state.errorMessage ?? 'فشل الإلغاء');
        }
      },
      builder: (ctx, state) {
        final loading = state.isServiceInvoiceCancelLoading;

        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r)),
          title: Row(children: [
            Icon(Icons.cancel_outlined,
                color: ColorsManager.errorText, size: 22.r),
            SizedBox(width: 8.w),
            Text('إلغاء فاتورة الخدمات',
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w700)),
          ]),
          content: SizedBox(
            width: 400.w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: ColorsManager.errorText.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('سيتم خصم هذه الفاتورة من مديونية المورد علينا:',
                          style: TextStyle(fontSize: 12.sp,
                              color: ColorsManager.errorText,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 6.h),
                      Text(
                          'الصافي: ${fmt.format(widget.invoice.netTotal)} $cur',
                          style: TextStyle(fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: ColorsManager.errorText)),
                      if (widget.invoice.paidAmount > 0) ...[
                        SizedBox(height: 4.h),
                        Text(
                            '⚠️ تم استلام ${fmt.format(widget.invoice.paidAmount)} $cur'
                                ' — تأكد من مراجعة الأرصدة',
                            style: TextStyle(fontSize: 11.sp,
                                color: Theme.of(context).hintColor)),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _reasonCtrl,
                  maxLines:   2,
                  decoration: InputDecoration(
                    labelText: 'سبب الإلغاء (اختياري)',
                    hintText:  'مثال: خطأ في الإدخال',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('تراجع'),
            ),
            FilledButton.icon(
              onPressed: loading
                  ? null
                  : () => context.read<SuppliersCubit>().cancelServiceInvoice(
                invoiceId:  widget.invoice.id,
                supplierId: widget.supplierId,
                reason:     _reasonCtrl.text.trim().isEmpty
                    ? null
                    : _reasonCtrl.text.trim(),
              ),
              icon: loading
                  ? SizedBox(width: 14.r, height: 14.r,
                  child: const CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.check_rounded, size: 16.r),
              label: Text('تأكيد الإلغاء',
                  style: TextStyle(fontSize: 13.sp)),
              style: FilledButton.styleFrom(
                  backgroundColor: ColorsManager.errorText),
            ),
          ],
        );
      },
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label, value;
  final Color color;
  const _AmountItem({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary)),
        SizedBox(height: 4.h),
        Text(value, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Service payment dialog (unchanged)
// ─────────────────────────────────────────────────────────────────────────────

class _ServicePaymentDialog extends StatefulWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;
  const _ServicePaymentDialog({required this.invoice, required this.supplierId});

  @override
  State<_ServicePaymentDialog> createState() => _ServicePaymentDialogState();
}

class _ServicePaymentDialogState extends State<_ServicePaymentDialog> {
  final _ctrl = TextEditingController();
  String _method  = 'safe';
  bool   _loading = false;
  String? _error;

  double get _remaining => widget.invoice.remaining;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String? _validate(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'أدخل مبلغاً صحيحاً';
    if (amt > _remaining) return 'المبلغ أكبر من المتبقي (${_remaining.toStringAsFixed(0)})';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate(_ctrl.text);
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _loading = true; _error = null; });

    final cubit = context.read<SuppliersCubit>();
    await cubit.recordServicePayment(
      invoiceId: widget.invoice.id, supplierId: widget.supplierId,
      amount: double.parse(_ctrl.text), method: _method,
    );

    if (!mounted) return;
    if (cubit.state.hasError) {
      setState(() { _loading = false; _error = cubit.state.errorMessage; });
    } else {
      context.showSuccess('تم تسجيل الدفعة بنجاح');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('تسجيل دفعة', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 4.h),
            Text('فاتورة #${widget.invoice.id.substring(0, 8).toUpperCase()}',
                style: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary)),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(color: ColorsManager.warningSurface,
                  borderRadius: BorderRadius.circular(8.r)),
              child: Row(children: [
                Icon(Icons.info_outline, size: 16.r, color: ColorsManager.warningText),
                SizedBox(width: 8.w),
                Expanded(child: Text('المبلغ المتبقي: $cur ${_remaining.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 12.sp, color: ColorsManager.warningText,
                        fontWeight: FontWeight.w600))),
              ]),
            ),
            SizedBox(height: 16.h),
            TextFormField(
              controller: _ctrl, autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: 'المبلغ', suffixText: cur,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                  errorText: _error),
              onChanged: (v) => setState(() => _error = _validate(v)),
            ),
            SizedBox(height: 16.h),
            Text('طريقة الدفع', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            Row(children: [
              Expanded(child: _MethodOption(label: 'كاش', icon: Icons.account_balance_wallet_outlined,
                  isSelected: _method == 'safe', onTap: () => setState(() => _method = 'safe'))),
              SizedBox(width: 10.w),
              Expanded(child: _MethodOption(label: 'بنك', icon: Icons.account_balance_outlined,
                  isSelected: _method == 'bank', onTap: () => setState(() => _method = 'bank'))),
            ]),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity, height: 46.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primaryColor, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                ),
                child: _loading
                    ? SizedBox(width: 20.r, height: 20.r,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('تأكيد الدفع', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _MethodOption({required this.label, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withOpacity(0.08)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? ColorsManager.primaryColor : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16.r,
                color: isSelected ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary),
            SizedBox(width: 6.w),
            Text(label, style: TextStyle(fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary)),
          ],
        ),
      ),
    );
  }
}