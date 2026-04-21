// lib/features/suppliers/presentation/widgets/supplier_invoice_widgets.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/app_info_row.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/widgets/supplier_record_payment_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// ── Status chip helper ────────────────────────────────────────────────────────

ChipStatus _chipStatus(SupplierInvoiceStatus s) => switch (s) {
  SupplierInvoiceStatus.paid    => ChipStatus.completed,
  SupplierInvoiceStatus.partial => ChipStatus.pending,
  SupplierInvoiceStatus.unpaid  => ChipStatus.reserved,
};

String _statusLabel(SupplierInvoiceStatus s) => switch (s) {
  SupplierInvoiceStatus.paid    => 'مدفوعة',
  SupplierInvoiceStatus.partial => 'مدفوعة جزئياً',
  SupplierInvoiceStatus.unpaid  => 'غير مدفوعة',
};

// ── Invoice card (used in the invoices list) ─────────────────────────────────

class SupplierInvoiceTile extends StatelessWidget {
  final SupplierInvoiceEntity invoice;
  final String                supplierId;
  final VoidCallback?         onTap;

  const SupplierInvoiceTile({
    super.key,
    required this.invoice,
    required this.supplierId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();
    final fmt   = DateFormat('d MMM yyyy');

    return InkWell(
      borderRadius: BorderRadius.circular(8.r),
      onTap: onTap,
      child: AppCard(
        padding: EdgeInsets.all(14.w),
        child: Row(
          children: [
            // Icon
            Container(
              width:  38.r,
              height: 38.r,
              decoration: BoxDecoration(
                  color:        ColorsManager.primaryLight,
                  borderRadius: BorderRadius.circular(8.r)),
              child: Icon(Icons.receipt_long_outlined,
                  size: 18.r, color: ColorsManager.primaryColor),
            ),
            SizedBox(width: 12.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'فاتورة #${invoice.id.substring(0, 8).toUpperCase()}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize:   13.sp,
                        color:      theme.textTheme.bodyMedium?.color),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    fmt.format(invoice.createdAt),
                    style: TextStyle(
                        fontSize: 11.sp,
                        color:    ColorsManager.defaultTextSecondary),
                  ),
                ],
              ),
            ),
            // Amount + status
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize:   14.sp,
                      color:      ColorsManager.errorText),
                ),
                SizedBox(height: 4.h),
                StatusChip(
                  label:  _statusLabel(invoice.status),
                  status: _chipStatus(invoice.status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Invoice detail card ───────────────────────────────────────────────────────

class SupplierInvoiceDetailCard extends StatelessWidget {
  final SupplierInvoiceEntity invoice;
  final String                supplierId;

  const SupplierInvoiceDetailCard({
    super.key,
    required this.invoice,
    required this.supplierId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();
    final fmt   = DateFormat('EEEE, d MMMM yyyy');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ──
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 20.r, color: ColorsManager.primaryColor),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'فاتورة #${invoice.id.substring(0, 8).toUpperCase()}',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize:   14.sp,
                              color:      theme.textTheme.titleSmall?.color),
                        ),
                        Text(fmt.format(invoice.createdAt),
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: ColorsManager.defaultTextSecondary)),
                      ],
                    ),
                  ),
                  StatusChip(
                    label:  _statusLabel(invoice.status),
                    status: _chipStatus(invoice.status),
                  ),
                ],
              ),
              if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color:        theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes_rounded,
                          size: 14.r,
                          color: ColorsManager.defaultTextSecondary),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(invoice.notes!,
                            style: TextStyle(
                                fontSize: 12.sp,
                                color: ColorsManager.defaultTextSecondary)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // ── Payment progress ──
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('حالة السداد',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize:   13.sp,
                          color:      theme.textTheme.titleSmall?.color)),
                  Text(
                    '${invoice.paymentPercent.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize:   13.sp,
                        color:      invoice.isFullyPaid
                            ? ColorsManager.successFill
                            : ColorsManager.primaryColor),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(4.r),
                child: LinearProgressIndicator(
                  value:       invoice.paymentPercent / 100,
                  minHeight:   8.h,
                  backgroundColor: theme.dividerColor,
                  valueColor:  AlwaysStoppedAnimation(
                    invoice.isFullyPaid
                        ? ColorsManager.successFill
                        : ColorsManager.primaryColor,
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppInfoRow.stacked('الإجمالي',
                      '$cur ${invoice.totalAmount.toStringAsFixed(0)}'),
                  AppInfoRow.stacked('المدفوع',
                      '$cur ${invoice.paidAmount.toStringAsFixed(0)}',
                      valueColor: ColorsManager.successText),
                  AppInfoRow.stacked('المتبقي',
                      '$cur ${invoice.remaining.toStringAsFixed(0)}',
                      valueColor: invoice.remaining > 0
                          ? ColorsManager.errorText
                          : ColorsManager.successText),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),

        // ── Items table ──
        Text('الأصناف',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize:   14.sp,
                color:      theme.textTheme.titleSmall?.color)),
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
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 4,
                          child: Text('الصنف',
                              style: TextStyle(
                                  fontSize:   11.sp,
                                  fontWeight: FontWeight.w600,
                                  color:      ColorsManager.defaultTextSecondary))),
                      _ColHdr('الكمية'),
                      _ColHdr('الأيام'),
                      _ColHdr('السعر/يوم'),
                      _ColHdr('الإجمالي', end: true),
                    ],
                  ),
                ),
                ...invoice.items.map((item) {
                  return Column(
                    children: [
                      Divider(height: 1, color: theme.dividerColor),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 10.h),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(item.itemName,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize:   13.sp,
                                      color: theme.textTheme.bodyMedium?.color),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            _Cell('${item.qty}'),
                            _Cell('${item.days}'),
                            _Cell(item.pricePerDay.toStringAsFixed(0)),
                            _Cell(
                              item.lineTotal.toStringAsFixed(0),
                              end: true,
                              bold: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }),
                // Total row
                Divider(height: 1, color: theme.dividerColor),
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: Text('الإجمالي',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize:   13.sp,
                                color: theme.textTheme.bodyMedium?.color)),
                      ),
                      const _Cell(''),
                      const _Cell(''),
                      const _Cell(''),
                      _Cell(
                        '$cur ${invoice.totalAmount.toStringAsFixed(0)}',
                        end: true,
                        bold: true,
                        color: ColorsManager.primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16.h),

        // ── Pay button (if not fully paid) ──
        if (!invoice.isFullyPaid)
          SizedBox(
            width: double.infinity,
            height: 46.h,
            child: ElevatedButton.icon(
              onPressed: () {
                final cubit = context.read<SuppliersCubit>();
                showDialog(
                  context: context,
                  builder: (_) => BlocProvider.value(
                    value: cubit,
                    child: SupplierRecordPaymentDialog(
                      invoice:    invoice,
                      supplierId: supplierId,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorsManager.primaryColor,
                foregroundColor: Colors.white,
                elevation:       0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r)),
              ),
              icon:  Icon(Icons.payments_outlined, size: 18.r),
              label: Text('تسجيل دفعة',
                  style: TextStyle(
                      fontSize:   14.sp,
                      fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

class _ColHdr extends StatelessWidget {
  final String text;
  final bool   end;
  const _ColHdr(this.text, {this.end = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 66.w,
    child: Text(text,
        style: TextStyle(
            fontSize:   11.sp,
            fontWeight: FontWeight.w600,
            color:      ColorsManager.defaultTextSecondary),
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

class _Cell extends StatelessWidget {
  final String text;
  final bool   end;
  final bool   bold;
  final Color? color;

  const _Cell(this.text, {this.end = false, this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 66.w,
    child: Text(text,
        style: TextStyle(
            fontSize:   13.sp,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color:      color ?? Theme.of(context).textTheme.bodyMedium?.color),
        textAlign: end ? TextAlign.end : TextAlign.center),
  );
}