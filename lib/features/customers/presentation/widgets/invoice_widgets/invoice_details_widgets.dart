// lib/features/customers/presentation/widgets/invoice_details_widgets.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_dialog_shell.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/app_info_row.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_item_entity.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_payment_summary.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'invoice_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header card
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceHeaderCard extends StatelessWidget {
  final InvoiceEntity invoice;
  final CustomerEntity customer;

  const InvoiceHeaderCard({
    super.key,
    required this.invoice,
    required this.customer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      variant: AppCardVariant.flat,
      color: theme.cardColor,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.receipt_long_rounded,
                size: 24.r, color: ColorsManager.primaryColor),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'invoices.invoice_number'.tr(
                    namedArgs: {'id': invoice.invoiceNumber},
                  ),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15.sp,
                    color: theme.textTheme.titleSmall?.color,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  DateFormat('EEEE, d MMMM yyyy').format(invoice.createdAt),
                  style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: ColorsManager.defaultTextSecondary),
                ),
                if (invoice.jobName != null && invoice.jobName!.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  _MetaChip(
                    icon: Icons.work_outline_rounded,
                    label: invoice.jobName!,
                  ),
                ],
                if (invoice.production != null && invoice.production!.isNotEmpty) ...[
                  SizedBox(height: 3.h),
                  _MetaChip(
                    icon: Icons.location_on_outlined,
                    label: invoice.production!,
                  ),
                ],
              ],
            ),
          ),
          _CustomerChip(customer: customer),
        ],
      ),
    );
  }
}

/// Small inline chip for job name / production label in the header card.
class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 12.r, color: ColorsManager.defaultTextSecondary),
      SizedBox(width: 4.w),
      Flexible(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: ColorsManager.defaultTextSecondary,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );
}

class _CustomerChip extends StatelessWidget {
  final CustomerEntity customer;
  const _CustomerChip({required this.customer});

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
    color: ColorsManager.primaryColor.withOpacity(0.06),
    variant: AppCardVariant.flat,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12.r,
          backgroundColor: ColorsManager.primaryColor,
          child: Text(
            customer.name.isEmpty ? '?' : customer.name[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
        SizedBox(width: 10.w),
        Text(
          customer.name,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: ColorsManager.primaryDark,
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment progress card
// ─────────────────────────────────────────────────────────────────────────────

class InvoicePaymentCard extends StatelessWidget {
  final InvoicePaymentSummary summary;
  const InvoicePaymentCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return AppCard(
      variant: AppCardVariant.flat,
      color: theme.cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'invoices.payment_status'.tr(),
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.sp,
                    color: theme.textTheme.titleSmall?.color),
              ),
              _PaymentBadge(isFullyPaid: summary.isFullyPaid),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(100.r), // Fully rounded
            child: LinearProgressIndicator(
              value:    summary.paymentPercent / 100,
              minHeight: 10.h, // Thicker
              backgroundColor: theme.dividerColor.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation(
                summary.isFullyPaid
                    ? ColorsManager.successFill
                    : ColorsManager.primaryColor,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppInfoRow.stacked('invoices.total_due'.tr(),
                  '$cur ${summary.totalDue.toStringAsFixed(0)}'),
              AppInfoRow.stacked('invoices.paid'.tr(),
                  '$cur ${summary.totalPaid.toStringAsFixed(0)}',
                  valueColor: ColorsManager.successText),
              AppInfoRow.stacked('invoices.remaining'.tr(),
                  '$cur ${summary.remaining.toStringAsFixed(0)}',
                  valueColor: summary.remaining > 0
                      ? ColorsManager.errorText
                      : ColorsManager.successText),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final bool isFullyPaid;
  const _PaymentBadge({required this.isFullyPaid});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(
      color: isFullyPaid
          ? ColorsManager.successSurface
          : ColorsManager.warningSurface,
      borderRadius: BorderRadius.circular(100.r), // Pill shape
    ),
    child: Text(
      isFullyPaid
          ? 'invoices.fully_paid'.tr()
          : 'invoices.partial_paid'.tr(),
      style: TextStyle(
        fontSize: 11.sp,
        fontWeight: FontWeight.w700,
        color: isFullyPaid
            ? ColorsManager.successText
            : ColorsManager.warningText,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary stat row
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceSummaryRow extends StatelessWidget {
  final InvoiceEntity invoice;
  const InvoiceSummaryRow({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();
    final cards = [
      _SCard(label: 'invoices.total_amount'.tr(),
          value: '$cur ${invoice.totalAmount.toStringAsFixed(0)}'),
      _SCard(
          label: 'invoices.discount'.tr(),
          value: invoice.discount > 0
              ? '−$cur ${invoice.discount.toStringAsFixed(0)} (${invoice.discountPercent.toStringAsFixed(1)}%)'
              : '—',
          valueColor: invoice.discount > 0 ? ColorsManager.errorText : null),
      _SCard(
          label: 'invoices.net_total'.tr(),
          value: '$cur ${invoice.netTotal.toStringAsFixed(0)}',
          highlight: true),
      _SCard(
          label: 'invoices.items'.tr(),
          value:
          '${invoice.items.length} (${invoice.itemsOutCount} ${'invoices.out'.tr()} / ${invoice.itemsReturnedCount} ${'invoices.returned'.tr()})'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(children: [
            Row(children: [
              Expanded(child: cards[0]),
              SizedBox(width: 10.w),
              Expanded(child: cards[1])
            ]),
            SizedBox(height: 10.h),
            Row(children: [
              Expanded(child: cards[2]),
              SizedBox(width: 10.w),
              Expanded(child: cards[3])
            ]),
          ]);
        }
        return Row(
          children: cards
              .expand((c) => [Expanded(child: c), SizedBox(width: 12.w)])
              .toList()
            ..removeLast(),
        );
      },
    );
  }
}

class _SCard extends StatelessWidget {
  final String  label, value;
  final Color?  valueColor;
  final bool    highlight;
  const _SCard(
      {required this.label,
        required this.value,
        this.valueColor,
        this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      // Use tonal flats instead of borders
      variant: AppCardVariant.flat,
      color: highlight
          ? ColorsManager.primaryColor.withOpacity(0.08)
          : theme.scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: ColorsManager.defaultTextSecondary)),
          SizedBox(height: 6.h),
          Text(value,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14.sp,
                  color: valueColor ?? (highlight ? ColorsManager.primaryColor : theme.textTheme.bodyMedium?.color))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Totals card
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceTotalsCard extends StatelessWidget {
  final InvoiceEntity invoice;
  const InvoiceTotalsCard({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return AppCard(
      variant: AppCardVariant.flat,
      color: theme.cardColor,
      child: Column(
        children: [
          AppInfoRow('invoices.gross_total'.tr(),
              '$cur ${invoice.grossTotal.toStringAsFixed(0)}'),
          if (invoice.totalItemDiscounts > 0)
            AppInfoRow(
              'invoices.item_discounts'.tr(),
              '−$cur ${invoice.totalItemDiscounts.toStringAsFixed(0)}',
              valueColor: ColorsManager.errorText,
            ),
          AppInfoRow('invoices.subtotal'.tr(),
              '$cur ${invoice.totalAmount.toStringAsFixed(0)}'),
          if (invoice.discount > 0)
            AppInfoRow(
              'invoices.discount'.tr(),
              '−$cur ${invoice.discount.toStringAsFixed(0)}',
              valueColor: ColorsManager.errorText,
            ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            child: Divider(height: 16.h, color: theme.dividerColor.withOpacity(0.3), thickness: 1),
          ),
          AppInfoRow.bold(
            'invoices.net_total'.tr(),
            '$cur ${invoice.netTotal.toStringAsFixed(0)}',
            valueColor: ColorsManager.primaryColor,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action bar
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceActionBar extends StatelessWidget {
  final InvoiceEntity           invoice;
  final InvoicePaymentSummary?  paymentSummary;
  final double                  hPad;
  final VoidCallback            onPay, onEdit, onComplete, onCancel;

  const InvoiceActionBar({
    super.key,
    required this.invoice,
    this.paymentSummary,
    required this.hPad,
    required this.onPay,
    required this.onEdit,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme       = Theme.of(context);
    final remaining   = paymentSummary?.remaining ?? invoice.netTotal;
    final isFullyPaid = paymentSummary?.isFullyPaid ?? false;
    final isActive    = invoice.status == InvoiceStatus.active ||  invoice.status == InvoiceStatus.draft;

    return Container(
      decoration: BoxDecoration(
        color:  theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16.h),
      child: SafeArea(
        child: Wrap(
          spacing:    12.w,
          runSpacing: 10.h,
          children: [
            if (remaining > 0)
              _ABtn(
                label:     'invoices.record_payment'.tr(),
                icon:      Icons.payments_rounded,
                isPrimary: true,
                onTap:     onPay,
              ),
            if (isActive)
              _ABtn(
                label: 'invoices.edit_invoice'.tr(),
                icon:  Icons.edit_rounded,
                onTap: onEdit,
              ),
            if (isActive && isFullyPaid)
              _ABtn(
                label: 'invoices.action_complete'.tr(),
                icon:  Icons.check_circle_rounded,
                color: ColorsManager.successFill,
                onTap: onComplete,
              ),
            if (isActive)
              _ABtn(
                label:    'invoices.action_cancel'.tr(),
                icon:     Icons.cancel_rounded,
                isDanger: true,
                onTap:    onCancel,
              ),
          ],
        ),
      ),
    );
  }
}

class _ABtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isPrimary, isDanger;
  final Color?   color;
  final VoidCallback onTap;

  const _ABtn({
    required this.label,
    required this.icon,
    this.isPrimary = false,
    this.isDanger  = false,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Tonal logic: pure solid for primary, light translucent for secondaries. No hard borders.
    final bg = isPrimary
        ? ColorsManager.primaryColor
        : (color != null
        ? color!.withOpacity(0.1)
        : isDanger
        ? ColorsManager.errorSurface
        : theme.scaffoldBackgroundColor);

    final fg = isPrimary
        ? Colors.white
        : (color ??
        (isDanger
            ? ColorsManager.errorText
            : theme.textTheme.bodyMedium?.color ?? ColorsManager.defaultText));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height:  42.h, // Slightly taller for modern touch targets
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color:        bg,
          borderRadius: BorderRadius.circular(10.r), // Softer radius
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.r, color: fg),
            SizedBox(width: 8.w),
            Text(label,
                style: TextStyle(
                    fontSize: 13.sp, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status pill
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceStatusPill extends StatelessWidget {
  final InvoiceEntity          invoice;
  final InvoicePaymentSummary? paymentSummary;

  const InvoiceStatusPill(
      {super.key, required this.invoice, this.paymentSummary});

  @override
  Widget build(BuildContext context) {
    final isFullyPaid = paymentSummary?.isFullyPaid ?? false;
    final isCompleted = invoice.status == InvoiceStatus.completed;

    final Color  color;
    final Color  bgColor;
    final String labelKey;

    if (invoice.status == InvoiceStatus.canceled) {
      color    = ColorsManager.errorText;
      bgColor  = ColorsManager.errorSurface;
      labelKey = 'invoices.status_canceled';
    } else if (invoice.status == InvoiceStatus.draft) {
      color    = ColorsManager.defaultTextSecondary;
      bgColor  = ColorsManager.backgroundSurface;
      labelKey = 'invoices.status_draft';
    } else if (isCompleted && isFullyPaid) {
      color    = ColorsManager.successFill;
      bgColor  = ColorsManager.successSurface;
      labelKey = 'invoices.status_completed';
    } else if (isCompleted && !isFullyPaid) {
      color    = ColorsManager.warningText;
      bgColor  = ColorsManager.warningSurface;
      labelKey = 'invoices.status_returned_unpaid';
    } else {
      color    = ColorsManager.primaryColor;
      bgColor  = ColorsManager.primaryLight;
      labelKey = 'invoices.status_active';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(100.r)), // Pill shape
      child: Text(labelKey.tr(),
          style: TextStyle(
              fontSize: 12.sp, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Return-qty dialog
// ─────────────────────────────────────────────────────────────────────────────

class InvoiceReturnQtyDialog extends StatefulWidget {
  final InvoiceItemEntity item;
  const InvoiceReturnQtyDialog({super.key, required this.item});

  @override
  State<InvoiceReturnQtyDialog> createState() => _InvoiceReturnQtyDialogState();
}

class _InvoiceReturnQtyDialogState extends State<InvoiceReturnQtyDialog> {
  late int _qty;

  @override
  void initState() {
    super.initState();
    _qty = widget.item.remainingQty;
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.item.remainingQty;

    return AppDialogShell(
      title:     'invoices.return_item_title'.tr(),
      saveLabel: 'invoices.return_confirm_btn'.tr(),
      isLoading: false,
      onSave:    () => Navigator.of(context).pop(_qty),
      onClose:   () => Navigator.of(context).pop(),
      maxWidth:  420,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard.flat(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.item.itemName ?? '—',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15.sp)),
                SizedBox(height: 6.h),
                Text(
                  'invoices.return_qty_info'.tr(namedArgs: {
                    'total':    '${widget.item.qty}',
                    'returned': '${widget.item.returnedQty}',
                    'remaining': '$remaining',
                  }),
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      color: ColorsManager.defaultTextSecondary),
                ),
              ],
            ),
          ),
          SizedBox(height: 24.h),
          Text('invoices.return_how_many'.tr(),
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepBtn(
                  icon:    Icons.remove_rounded,
                  enabled: _qty > 1,
                  onTap:   () =>
                      setState(() => _qty = (_qty - 1).clamp(1, remaining))),
              SizedBox(width: 24.w),
              Container(
                width: 72.w, height: 48.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ColorsManager.primaryColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text('$_qty',
                    style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w800,
                        color: ColorsManager.primaryColor)),
              ),
              SizedBox(width: 24.w),
              _StepBtn(
                  icon:    Icons.add_rounded,
                  enabled: _qty < remaining,
                  onTap:   () =>
                      setState(() => _qty = (_qty + 1).clamp(1, remaining))),
            ],
          ),
          SizedBox(height: 12.h),
          Center(
            child: Text(
              'invoices.return_max'.tr(namedArgs: {'max': '$remaining'}),
              style: TextStyle(
                  fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  final IconData icon;
  final bool     enabled;
  final VoidCallback onTap;

  const _StepBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44.r, height: 44.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? ColorsManager.primaryColor
              : theme.dividerColor.withOpacity(0.2),
        ),
        child: Icon(icon,
            size: 20.r,
            color: enabled
                ? Colors.white
                : ColorsManager.defaultTextSecondary),
      ),
    );
  }
}

class InvoiceRecordPaymentDialog extends StatefulWidget {
  final String invoiceId;
  final double maxAmount;
  final CustomerEntity customer;

  const InvoiceRecordPaymentDialog({
    super.key,
    required this.invoiceId,
    required this.maxAmount,
    required this.customer,
  });

  @override
  State<InvoiceRecordPaymentDialog> createState() =>
      _InvoiceRecordPaymentDialogState();
}

class _InvoiceRecordPaymentDialogState
    extends State<InvoiceRecordPaymentDialog> {
  final _ctrl = TextEditingController();
  String _method = 'safe';
  bool _loading = false;
  String? _error;

  bool get _isWallet => _method == 'wallet';
  double get _walletBal => widget.customer.walletBalance;
  double get _effectiveMax =>
      _isWallet ? _walletBal.clamp(0, widget.maxAmount) : widget.maxAmount;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'invoices.error_positive_amount'.tr();

    if (amt > widget.maxAmount) {
      return 'invoices.error_exceeds_remaining'.tr(
          namedArgs: {'max': widget.maxAmount.toStringAsFixed(0)});
    }

    if (_isWallet && amt > _walletBal) {
      return 'رصيد المحفظة غير كافٍ (المتاح: ${_walletBal.toStringAsFixed(0)})';
    }
    return null;
  }

  void _submit() {
    final err = _validate(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    context.read<InvoicesCubit>().recordPayment(
      invoiceId: widget.invoiceId,
      amount: double.parse(_ctrl.text),
      method: _method,
    );
  }

  void _onMethodChanged(String m) {
    setState(() {
      _method = m;
      _error = _validate(_ctrl.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();

    return BlocListener<InvoicesCubit, InvoicesState>(
      listener: (context, state) {
        if (state is PaymentRecorded) {
          Navigator.of(context).pop();
        } else if (state is InvoicesError) {
          setState(() {
            _loading = false;
            _error = state.message;
          });
        }
      },
      child: AppDialogShell(
        title: 'invoices.record_payment'.tr(),
        saveLabel: 'invoices.confirm_payment'.tr(),
        isLoading: _loading,
        onSave: _submit,
        onClose: () => Navigator.of(context).pop(),
        maxWidth: 460,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              color: ColorsManager.warningSurface.withOpacity(0.5),
              variant: AppCardVariant.flat,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_rounded,
                      size: 16.r, color: ColorsManager.warningText),
                  SizedBox(width: 8.w),
                  Flexible(
                    child: Text(
                      'invoices.remaining_balance'.tr(namedArgs: {
                        'amount': '${widget.maxAmount.toStringAsFixed(0)} $cur',
                      }),
                      style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: ColorsManager.warningText),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            _WalletBalanceCard(
              customer: widget.customer,
              isSelected: _isWallet,
            ),
            SizedBox(height: 20.h),

            _PaymentMethodRow(
              method: _method,
              enabled: !_loading,
              walletBal: _walletBal,
              onChanged: _onMethodChanged,
            ),
            SizedBox(height: 20.h),

            TextFormField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
              decoration: InputDecoration(
                labelText: 'invoices.amount'.tr(),
                suffixText: cur,
                suffixStyle: TextStyle(fontWeight: FontWeight.w700, color: ColorsManager.defaultTextSecondary),
                helperText: _isWallet && _effectiveMax < widget.maxAmount
                    ? 'الحد الأقصى من المحفظة: ${_effectiveMax.toStringAsFixed(0)} $cur'
                    : null,
                helperStyle: TextStyle(
                    fontSize: 12.sp, color: ColorsManager.primaryColor, fontWeight: FontWeight.w500),
                filled: true,
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: ColorsManager.primaryColor, width: 2)),
                errorText: _error,
              ),
              onChanged: (v) => setState(() => _error = _validate(v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  final CustomerEntity customer;
  final bool isSelected;

  const _WalletBalanceCard({required this.customer, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur = 'dashboard.currency'.tr();
    final hasBalance = customer.walletBalance > 0;

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      color: isSelected
          ? ColorsManager.primaryColor.withOpacity(0.08)
          : (hasBalance
          ? ColorsManager.successSurface.withOpacity(0.3)
          : theme.scaffoldBackgroundColor),
      variant: AppCardVariant.flat, // No hard borders
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: hasBalance
                  ? ColorsManager.primaryColor.withOpacity(0.1)
                  : theme.dividerColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_rounded,
              size: 22.r,
              color: hasBalance
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رصيد محفظة ${customer.name}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.defaultTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  '${customer.walletBalance.toStringAsFixed(0)} $cur',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: hasBalance
                        ? ColorsManager.primaryColor
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          if (!hasBalance)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: ColorsManager.warningSurface,
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Text('لا يوجد رصيد',
                  style: TextStyle(
                      fontSize: 12.sp,
                      color: ColorsManager.warningText,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }
}

class _PaymentMethodRow extends StatelessWidget {
  final String method;
  final bool enabled;
  final double walletBal;
  final ValueChanged<String> onChanged;

  const _PaymentMethodRow({
    required this.method,
    required this.enabled,
    required this.walletBal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('طريقة الدفع',
            style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: theme.textTheme.titleSmall?.color)),
        SizedBox(height: 12.h),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MethodOption(
                  label: 'invoices.method_safe'.tr(),
                  icon: Icons.storefront_rounded,
                  isSelected: method == 'safe',
                  onTap: enabled ? () => onChanged('safe') : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MethodOption(
                  label: 'invoices.method_bank'.tr(),
                  icon: Icons.account_balance_rounded,
                  isSelected: method == 'bank',
                  onTap: enabled ? () => onChanged('bank') : null,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MethodOption(
                  label: 'رصيد العميل',
                  icon: Icons.wallet_rounded,
                  isSelected: method == 'wallet',
                  onTap: (enabled && walletBal > 0)
                      ? () => onChanged('wallet')
                      : null,
                  badge: walletBal > 0 ? walletBal.toStringAsFixed(0) : null,
                  dimmed: walletBal <= 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MethodOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;
  final String? badge;
  final bool dimmed;

  const _MethodOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
    this.badge,
    this.dimmed = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final activeColor = dimmed
        ? ColorsManager.defaultTextSecondary.withOpacity(0.5)
        : (isSelected ? ColorsManager.primaryColor : theme.textTheme.bodyMedium?.color);

    final bgColor = isSelected
        ? ColorsManager.primaryColor.withOpacity(0.08)
        : (dimmed ? theme.dividerColor.withOpacity(0.1) : theme.scaffoldBackgroundColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          // Extremely subtle border logic for a flat aesthetic
          border: Border.all(
            color: isSelected ? ColorsManager.primaryColor : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26.r, color: activeColor),
            SizedBox(height: 10.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: activeColor,
              ),
            ),
            SizedBox(height: 6.h),
            if (badge != null)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                    color: ColorsManager.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4.r)
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: ColorsManager.primaryColor,
                  ),
                ),
              )
            else if (dimmed)
              Text(
                'لا يوجد رصيد',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: ColorsManager.warningText.withOpacity(0.7),
                  fontWeight: FontWeight.w700,
                ),
              )
            else
              SizedBox(height: 11.sp * 1.2),
          ],
        ),
      ),
    );
  }
}