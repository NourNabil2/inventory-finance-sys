// lib/features/dashboard/presentation/widgets/recent_invoices_table.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:bungee_manage_sys/core/widgets/status_chip.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/entities/dashboard_entity.dart';

import '../../../../core/utils/enums.dart';

class RecentInvoicesTable extends StatelessWidget {
  final List<RecentInvoiceEntity> invoices;

  const RecentInvoicesTable({super.key, required this.invoices});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(20.r),
            child: Text(
              'finance.recent_transactions'.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Divider(color: Theme.of(context).dividerColor, height: 1),

          if (invoices.isEmpty)
            Padding(
              padding: EdgeInsets.all(32.r),
              child: Center(
                child: Text(
                  'common.noData'.tr(), // 🚨 تم استخدام الترجمة
                  style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ),
            )
          else ...[
            const _TableHeader(),
            Divider(color: Theme.of(context).dividerColor, height: 1),
            ...List.generate(invoices.length, (i) => Column(
              children: [
                _TableRow(invoice: invoices[i]),
                if (i < invoices.length - 1)
                  Divider(color: Theme.of(context).dividerColor, height: 1),
              ],
            )),
          ]
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          _Cell('invoices.invoice_number'.tr(namedArgs: {'id':''}).replaceAll('#', '').trim(), flex: 2, isHeader: true),
          _Cell('customers.name'.tr(), flex: 3, isHeader: true),
          _Cell('invoices.date'.tr(), flex: 2, isHeader: true),
          _Cell('invoices.net_total'.tr(), flex: 2, isHeader: true),
          _Cell('invoices.status'.tr(), flex: 2, isHeader: true),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final RecentInvoiceEntity invoice;

  const _TableRow({required this.invoice});

  (ChipStatus, String) get _statusInfo {
    switch (invoice.status.toLowerCase()) {
      case 'active':
        return (ChipStatus.active, 'invoices.status_active');
      case 'completed':
        return (ChipStatus.completed, 'invoices.status_completed');
      case 'canceled':
        return (ChipStatus.canceled, 'invoices.status_canceled');
      default:
        return (ChipStatus.draft, 'invoices.status_draft');
    }
  }

  @override
  Widget build(BuildContext context) {
    final (chipStatus, labelKey) = _statusInfo;
    final currency = 'dashboard.currency'.tr();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
      child: Row(
        children: [
          _Cell(
            invoice.invoiceNumber.isNotEmpty
                ? invoice.invoiceNumber
                : invoice.id.substring(0, 8).toUpperCase(),
            flex: 2,
            bold: true,
          ),
          _Cell(invoice.customerName, flex: 3),
          _Cell(DateFormat('yyyy-MM-dd').format(invoice.createdAt), flex: 2),
          _Cell('${invoice.netTotal.toStringAsFixed(0)} $currency', flex: 2, bold: true),
          Expanded(
            flex: 2,
            child: StatusChip(
              label: labelKey.tr(),
              status: chipStatus,
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isHeader;
  final bool bold;

  const _Cell(this.text, {required this.flex, this.isHeader = false, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: isHeader
            ? Theme.of(context).textTheme.bodySmall
            : Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}