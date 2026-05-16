// lib/features/suppliers/presentation/pages/supplier_unified_detail_page.dart
//
// Unified Supplier & Customer Ledger — single profile page.
// Replaces _SupplierDetailView inside suppliers_page.dart.

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/service_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/pages/create_supplier_invoice_page.dart';
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
// Entry point — replaces _SupplierDetailView in suppliers_page.dart
// ─────────────────────────────────────────────────────────────────────────────

class SupplierUnifiedDetailView extends StatelessWidget {
  final SupplierEntity supplier;
  const SupplierUnifiedDetailView({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        // Always use the freshest supplier from the list
        final fresh = state.suppliers
            .where((s) => s.id == supplier.id)
            .firstOrNull ??
            supplier;

        // If a purchase-invoice detail is open, show it instead
        if (state.selectedInvoice != null) {
          final freshInv = state.invoices
              .where((i) => i.id == state.selectedInvoice!.id)
              .firstOrNull ??
              state.selectedInvoice!;
          return _InvoiceDetailShell(invoice: freshInv, supplierId: fresh.id);
        }

        return _UnifiedProfileShell(supplier: fresh);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shell with header + tab bar
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
// Header — name, phone, action buttons
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
          // Back button (mobile only)
          if (MediaQuery.of(context).size.width < 900)
            Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: IconButton(
                icon:      Icon(Icons.arrow_back_ios, size: 18.r),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

          // Avatar
          CircleAvatar(
            radius:          22.r,
            backgroundColor: ColorsManager.primaryColor,
            child: Text(
              supplier.name.isNotEmpty ? supplier.name[0].toUpperCase() : '?',
              style: TextStyle(
                  color:      Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize:   16.sp),
            ),
          ),
          SizedBox(width: 12.w),

          // Name + phone
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.name,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (supplier.phone != null)
                  Text(supplier.phone!,
                      style: theme.textTheme.labelSmall),
                Text(
                  'منذ ${DateFormat('yyyy').format(supplier.createdAt)}',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),

          // Actions
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
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorsManager.primaryColor,
                side: const BorderSide(color: ColorsManager.primaryColor),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              icon: Icon(Icons.add_circle_outline, size: 16.r),
              label: Text('فاتورة جديدة',
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
            ),

            // ── زرار المقاصة ──
            if (supplier.balance > 0 || supplier.serviceDebt > 0)
              ElevatedButton.icon(
                onPressed: isClearing
                    ? null
                    : () async {
                  final done = await showFlexibleClearingDialog(
                    context: context,
                    supplier: supplier,
                  );
                  if (done && context.mounted) {
                    context.read<SuppliersCubit>().resetClearingStatus();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                ),
                icon: isClearing
                    ? SizedBox(width: 14.r, height: 14.r,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.compare_arrows_rounded, size: 16.r),
                label: Text('تسوية', style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w600)),
              ),
          ],
        );
      },
    );
  }
}

// ── شاشة مبسطة لإنشاء فاتورة الخدمات ──
class _CreateServiceInvoiceDialog extends StatefulWidget {
  final SupplierEntity supplier;
  const _CreateServiceInvoiceDialog({required this.supplier});

  @override
  State<_CreateServiceInvoiceDialog> createState() => _CreateServiceInvoiceDialogState();
}

class _CreateServiceInvoiceDialogState extends State<_CreateServiceInvoiceDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  void _submit() async {
    final amt = double.tryParse(_amountCtrl.text);
    if (amt == null || amt <= 0) {
      context.showError('أدخل مبلغ صحيح');
      return;
    }
    setState(() => _loading = true);

    await context.read<SuppliersCubit>().createServiceInvoiceForSupplier(
      supplierId: widget.supplier.id,
      totalAmount: amt,
      notes: _notesCtrl.text.trim(),
    );

    if (mounted) {
      context.showSuccess('تم إضافة الفاتورة والمديونية بنجاح');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('إنشاء فاتورة خدمات', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('تسجيل مديونية على המورد (${widget.supplier.name}) مقابل خدمات أو إيجار.', style: TextStyle(fontSize: 12.sp, color: ColorsManager.defaultTextSecondary)),
          SizedBox(height: 16.h),
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'قيمة الفاتورة (المديونية)'),
          ),
          SizedBox(height: 12.h),
          TextField(
            controller: _notesCtrl,
            decoration: const InputDecoration(labelText: 'ملاحظات (البيان)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          child: _loading ? const CircularProgressIndicator() : const Text('حفظ الفاتورة'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ledger summary bar — three balance cards
// ─────────────────────────────────────────────────────────────────────────────

class _LedgerSummaryBar extends StatelessWidget {
  final SupplierEntity supplier;
  const _LedgerSummaryBar({required this.supplier});

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();
    final net = supplier.netPosition; // balance - serviceDebt

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color:  Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        children: [
          // مديونية له
          Expanded(
            child: _BalanceCard(
              label:      'مديونية له',
              subLabel:   'نحن ندفع لهم',
              amount:     supplier.balance,
              cur:        cur,
              color:      ColorsManager.errorText,
              fillColor:  ColorsManager.errorFill.withOpacity(0.07),
              icon:       Icons.arrow_circle_down_outlined,
            ),
          ),
          SizedBox(width: 8.w),

          // مديونية عليه
          Expanded(
            child: _BalanceCard(
              label:      'مديونية عليه',
              subLabel:   'يدفعون لنا',
              amount:     supplier.serviceDebt,
              cur:        cur,
              color:      ColorsManager.successText,
              fillColor:  ColorsManager.successFill.withOpacity(0.07),
              icon:       Icons.arrow_circle_up_outlined,
            ),
          ),
          SizedBox(width: 8.w),

          // صافي المركز
          Expanded(
            child: _BalanceCard(
              label:      'صافي المركز',
              subLabel:   net >= 0 ? 'لصالحهم' : 'لصالحنا',
              amount:     net.abs(),
              cur:        cur,
              color:      net >= 0
                  ? ColorsManager.warningText
                  : ColorsManager.primaryColor,
              fillColor:  (net >= 0
                  ? ColorsManager.warningSurface
                  : ColorsManager.primaryColor)
                  .withOpacity(0.07),
              icon: net >= 0
                  ? Icons.balance_outlined
                  : Icons.trending_up_rounded,
              prefixLabel: net < 0 ? '−' : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String  label;
  final String  subLabel;
  final double  amount;
  final String  cur;
  final Color   color;
  final Color   fillColor;
  final IconData icon;
  final String? prefixLabel;

  const _BalanceCard({
    required this.label,
    required this.subLabel,
    required this.amount,
    required this.cur,
    required this.color,
    required this.fillColor,
    required this.icon,
    this.prefixLabel,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      color:   fillColor,
      variant: AppCardVariant.outlined,
      padding: EdgeInsets.all(10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13.r, color: color),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize:   10.sp,
                        fontWeight: FontWeight.w600,
                        color:      color)),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit:       BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              '${prefixLabel ?? ''}$cur ${amount.toStringAsFixed(0)}',
              style: TextStyle(
                  fontSize:   15.sp,
                  fontWeight: FontWeight.w800,
                  color:      color),
            ),
          ),
          Text(subLabel,
              style: TextStyle(
                  fontSize: 9.sp,
                  color:    ColorsManager.defaultTextSecondary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab bar
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
            color:  Theme.of(context).cardColor,
            border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              _Tab(
                label:      'فواتير الشراء',
                icon:       Icons.shopping_cart_outlined,
                isSelected: state.activeTab == SupplierLedgerTab.purchases,
                onTap: () => context
                    .read<SuppliersCubit>()
                    .switchTab(SupplierLedgerTab.purchases),
              ),
              _Tab(
                label:      'فواتير الخدمات',
                icon:       Icons.receipt_outlined,
                isSelected: state.activeTab == SupplierLedgerTab.services,
                onTap: () => context
                    .read<SuppliersCubit>()
                    .switchTab(SupplierLedgerTab.services),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  final String     label;
  final IconData   icon;
  final bool       isSelected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    isSelected ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding:  EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? ColorsManager.primaryColor
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15.r, color: color),
              SizedBox(width: 6.w),
              Text(label,
                  style: TextStyle(
                      fontSize:   13.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab body — switches between purchase and service invoice lists
// ─────────────────────────────────────────────────────────────────────────────

class _TabBody extends StatelessWidget {
  const _TabBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.activeTab == SupplierLedgerTab.purchases) {
          return _PurchaseInvoicesList(
              supplierId: state.selectedSupplier?.id ?? '');
        }
        return _ServiceInvoicesList(
            supplierId: state.selectedSupplier?.id ?? '');
      },
    );
  }
}

// ── Purchase invoices tab ─────────────────────────────────────

class _PurchaseInvoicesList extends StatelessWidget {
  final String supplierId;
  const _PurchaseInvoicesList({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.isLoading && state.invoices.isEmpty) {
          return const Center(
              child:
              Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()));
        }
        if (state.hasError) {
          return EmptyStateWidget(
            icon:            Icons.cloud_off_rounded,
            title:           'فشل في تحميل الفواتير',
            subtitle:        state.errorMessage ?? '',
            isFullPage:      false,
            actionLabel:     'إعادة المحاولة',
            onActionPressed: () =>
                context.read<SuppliersCubit>().fetchSupplierInvoices(supplierId),
          );
        }
        if (state.invoices.isEmpty) {
          return EmptyStateWidget(
            icon:       Icons.receipt_long_outlined,
            title:      'لا توجد فواتير شراء',
            subtitle:   'اضغط على "فاتورة شراء" لإضافة فاتورة',
            isFullPage: false,
          );
        }
        return ListView.builder(
          padding:     EdgeInsets.all(16.w),
          itemCount:   state.invoices.length,
          itemBuilder: (ctx, i) {
            final inv = state.invoices[i];
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: SupplierInvoiceTile(
                invoice:    inv,
                supplierId: supplierId,
                onTap: () =>
                    ctx.read<SuppliersCubit>().selectInvoice(inv.id),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Service invoices tab ──────────────────────────────────────

class _ServiceInvoicesList extends StatelessWidget {
  final String supplierId;
  const _ServiceInvoicesList({required this.supplierId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SuppliersCubit, SuppliersState>(
      builder: (context, state) {
        if (state.isServiceInvoicesLoading && state.serviceInvoices.isEmpty) {
          return const Center(
              child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (state.serviceInvoicesStatus == ServiceInvoicesStatus.failure) {
          return EmptyStateWidget(
            icon:            Icons.cloud_off_rounded,
            title:           'فشل في تحميل فواتير الخدمات',
            subtitle:        state.errorMessage ?? '',
            isFullPage:      false,
            actionLabel:     'إعادة المحاولة',
            onActionPressed: () => context
                .read<SuppliersCubit>()
                .fetchSupplierServiceInvoices(supplierId),
          );
        }
        if (state.serviceInvoices.isEmpty) {
          return EmptyStateWidget(
            icon:       Icons.receipt_outlined,
            title:      'لا توجد فواتير خدمات',
            subtitle:   'لم يتم إصدار أي فاتورة إيجار لهذا المورد بعد',
            isFullPage: false,
          );
        }
        return ListView.builder(
          padding:     EdgeInsets.all(16.w),
          itemCount:   state.serviceInvoices.length,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: _ServiceInvoiceTile(invoice: state.serviceInvoices[i], supplierId: supplierId),
          ),
        );
      },
    );
  }
}

// ── Service invoice tile ──────────────────────────────────────

// ── Service invoice tile ──────────────────────────────────────

// ── دوال مساعدة لحالة فاتورة الخدمات ─────────────────────────
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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<SuppliersCubit>(),
              child: _ServiceInvoiceDetailPage(invoice: invoice, supplierId: supplierId),
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8.r),
      child: AppCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            Container(
              width:  38.r, height: 38.r,
              decoration: BoxDecoration(
                color:        ColorsManager.successFill.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(Icons.receipt_outlined, size: 18.r, color: ColorsManager.successText),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فاتورة خدمة #${invoice.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: theme.textTheme.bodyMedium?.color),
                  ),
                  SizedBox(height: 2.h),
                  Text(fmt.format(invoice.createdAt), style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary)),
                  if (invoice.notes != null && invoice.notes!.isNotEmpty)
                    Text(invoice.notes!, style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.sp, color: ColorsManager.successText),
                ),
                SizedBox(height: 4.h),
                // 🚨 استخدام الدوال الجديدة هنا 🚨
                StatusChip(
                    label: _getServiceStatusLabel(invoice.status),
                    status: _getServiceChipStatus(invoice.status)
                ),
                if (!invoice.isFullyPaid) ...[
                  SizedBox(height: 2.h),
                  Text('متبقي: $cur ${invoice.remaining.toStringAsFixed(0)}', style: TextStyle(fontSize: 10.sp, color: ColorsManager.errorText, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Invoice Detail Page ───────────────────────────────

class _ServiceInvoiceDetailPage extends StatelessWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;
  const _ServiceInvoiceDetailPage({required this.invoice, required this.supplierId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur = 'dashboard.currency'.tr();
    final fmt = DateFormat('EEEE, d MMMM yyyy');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: theme.cardColor,
                border: Border(bottom: BorderSide(color: theme.dividerColor)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 18.r),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل فاتورة الخدمات',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                            color: theme.textTheme.titleSmall?.color,
                          ),
                        ),
                        Text(
                          '#${invoice.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: ColorsManager.defaultTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    AppCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48.r,
                                height: 48.r,
                                decoration: BoxDecoration(
                                  color: ColorsManager.successFill.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.receipt_outlined,
                                  size: 24.r,
                                  color: ColorsManager.successText,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'فاتورة خدمة',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15.sp,
                                        color: theme.textTheme.titleSmall?.color,
                                      ),
                                    ),
                                    SizedBox(height: 2.h),
                                    Text(
                                      fmt.format(invoice.createdAt),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: ColorsManager.defaultTextSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(
                                label: _getServiceStatusLabel(invoice.status),
                                status: _getServiceChipStatus(invoice.status),
                              ),
                            ],
                          ),
                          if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                            SizedBox(height: 12.h),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                              decoration: BoxDecoration(
                                color: theme.scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.notes_rounded,
                                      size: 16.r, color: ColorsManager.defaultTextSecondary),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      invoice.notes!,
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: ColorsManager.defaultTextSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Amount Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تفاصيل المبلغ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.sp,
                              color: theme.textTheme.titleSmall?.color,
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Payment progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'نسبة السداد',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: ColorsManager.defaultTextSecondary,
                                ),
                              ),
                              Text(
                                '${invoice.paymentPercent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.sp,
                                  color: invoice.isFullyPaid
                                      ? ColorsManager.successText
                                      : ColorsManager.primaryColor,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8.h),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.r),
                            child: LinearProgressIndicator(
                              value: invoice.paymentPercent / 100,
                              minHeight: 8.h,
                              backgroundColor: theme.dividerColor,
                              valueColor: AlwaysStoppedAnimation(
                                invoice.isFullyPaid
                                    ? ColorsManager.successFill
                                    : ColorsManager.primaryColor,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.h),

                          // Amounts
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _AmountItem(
                                label: 'الإجمالي',
                                value: '$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                                color: theme.textTheme.bodyMedium?.color ?? Colors.black,
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

                    SizedBox(height: 16.h),

                    // Pay button (if not fully paid)
                    if (!invoice.isFullyPaid)
                      SizedBox(
                        width: double.infinity,
                        height: 48.h,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _showServicePaymentDialog(context, invoice);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorsManager.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          icon: Icon(Icons.payments_outlined, size: 20.r),
                          label: Text(
                            'تسجيل دفعة',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServicePaymentDialog(BuildContext context, ServiceInvoiceEntity invoice) {
    final cubit = context.read<SuppliersCubit>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: _ServicePaymentDialog(invoice: invoice, supplierId: supplierId),
      ),
    );
  }
}

class _AmountItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AmountItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: ColorsManager.defaultTextSecondary,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Service Payment Dialog ────────────────────────────────────

class _ServicePaymentDialog extends StatefulWidget {
  final ServiceInvoiceEntity invoice;
  final String supplierId;
  const _ServicePaymentDialog({required this.invoice, required this.supplierId});

  @override
  State<_ServicePaymentDialog> createState() => _ServicePaymentDialogState();
}

class _ServicePaymentDialogState extends State<_ServicePaymentDialog> {
  final _ctrl = TextEditingController();
  String _method = 'safe';
  bool _loading = false;
  String? _error;

  double get _remaining => widget.invoice.remaining;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'أدخل مبلغاً صحيحاً';
    if (amt > _remaining) {
      return 'المبلغ أكبر من المتبقي (${_remaining.toStringAsFixed(0)})';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate(_ctrl.text);
    if (err != null) { setState(() => _error = err); return; }
    setState(() { _loading = true; _error = null; });

    final cubit = context.read<SuppliersCubit>();
    await cubit.recordServicePayment(
      invoiceId:  widget.invoice.id,
      supplierId: widget.supplierId,
      amount:     double.parse(_ctrl.text),
      method:     _method,
    );

    if (!mounted) return;
    final st = cubit.state;
    if (st.hasError) {
      setState(() { _loading = false; _error = st.errorMessage; });
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
            Text(
              'تسجيل دفعة',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'فاتورة #${widget.invoice.id.substring(0, 8).toUpperCase()}',
              style: TextStyle(
                fontSize: 12.sp,
                color: ColorsManager.defaultTextSecondary,
              ),
            ),
            SizedBox(height: 16.h),

            // Remaining banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: ColorsManager.warningSurface,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16.r, color: ColorsManager.warningText),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'المبلغ المتبقي: $cur ${_remaining.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: ColorsManager.warningText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Amount field
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'المبلغ',
                suffixText: cur,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
                errorText: _error,
              ),
              onChanged: (v) => setState(() => _error = _validate(v)),
            ),
            SizedBox(height: 16.h),

            // Method selector
            Text(
              'طريقة الدفع',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Expanded(
                  child: _MethodOption(
                    label: 'كاش',
                    icon: Icons.account_balance_wallet_outlined,
                    isSelected: _method == 'safe',
                    onTap: () => setState(() => _method = 'safe'),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: _MethodOption(
                    label: 'بنك',
                    icon: Icons.account_balance_outlined,
                    isSelected: _method == 'bank',
                    onTap: () => setState(() => _method = 'bank'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                child: _loading
                    ? SizedBox(
                  width: 20.r,
                  height: 20.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  'تأكيد الدفع',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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

  const _MethodOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

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
            color: isSelected
                ? ColorsManager.primaryColor
                : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16.r,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? ColorsManager.primaryColor
                    : ColorsManager.defaultTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Invoice detail shell (purchase invoice drill-down)
// ─────────────────────────────────────────────────────────────────────────────

class _InvoiceDetailShell extends StatelessWidget {
  final dynamic invoice;
  final String  supplierId;

  const _InvoiceDetailShell({
    required this.invoice,
    required this.supplierId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
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
                onPressed: () =>
                    context.read<SuppliersCubit>().clearSelectedInvoice(),
              ),
              Text('تفاصيل الفاتورة',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize:   15.sp,
                      color:      theme.textTheme.titleSmall?.color)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: SupplierInvoiceDetailCard(
                invoice: invoice, supplierId: supplierId),
          ),
        ),
      ],
    );
  }
}