// lib/features/customers/presentation/widgets/customer_stats_card.dart

import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/app_info_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/theme/colors.dart';
import '../../../domain/entities/customer_entity.dart';

class CustomerStatsCard extends StatelessWidget {
  final CustomerEntity customer;
  const CustomerStatsCard({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Customer avatar + name ─────────────────────────────────────
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundColor: ColorsManager.primaryColor,
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(customer.name,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (customer.phone != null)
                      Text(customer.phone!, style: theme.textTheme.labelSmall),
                  ],
                ),
              ),
              Text(
                'customers.since'.tr(
                    namedArgs: {'year': customer.createdAt.year.toString()}),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // ── Financial stats row ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCell(
                  label: 'customers.stat_total_invoiced'.tr(),
                  value: '${customer.totalInvoiced.toStringAsFixed(0)} $cur',
                  color: ColorsManager.primaryColor,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatCell(
                  label: 'customers.stat_total_paid'.tr(),
                  value: '${customer.totalPaid.toStringAsFixed(0)} $cur',
                  color: ColorsManager.successText,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _StatCell(
                  label: 'customers.stat_total_debt'.tr(),
                  value: '${customer.totalDebt.toStringAsFixed(0)} $cur',
                  color: customer.totalDebt > 0
                      ? ColorsManager.errorText
                      : ColorsManager.successText,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // ── Wallet balance banner ──────────────────────────────────────
          _WalletRow(customer: customer, cur: cur),
        ],
      ),
    );
  }
}

// ── Wallet banner ──────────────────────────────────────────────────────────────

class _WalletRow extends StatelessWidget {
  final CustomerEntity customer;
  final String         cur;
  const _WalletRow({required this.customer, required this.cur});

  @override
  Widget build(BuildContext context) {
    final hasBalance = customer.walletBalance > 0;

    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      color:   hasBalance
          ? ColorsManager.primaryColor.withOpacity(0.06)
          : Theme.of(context).scaffoldBackgroundColor,
      variant: hasBalance ? AppCardVariant.highlighted : AppCardVariant.outlined,
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size:  18.r,
            color: hasBalance
                ? ColorsManager.primaryColor
                : ColorsManager.defaultTextSecondary,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'رصيد المحفظة',
              style: TextStyle(
                  fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
            ),
          ),
          Text(
            '${customer.walletBalance.toStringAsFixed(0)} $cur',
            style: TextStyle(
              fontSize:   15.sp,
              fontWeight: FontWeight.w700,
              color: hasBalance
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary,
            ),
          ),
          if (!hasBalance) ...[
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color:        ColorsManager.backgroundSurface,
                borderRadius: BorderRadius.circular(4.r),
                border:       Border.all(color: ColorsManager.inputBorder),
              ),
              child: Text('لا يوجد',
                  style: TextStyle(
                      fontSize: 10.sp,
                      color:    ColorsManager.defaultTextSecondary)),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Stat cell ──────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => AppCard.flat(
    color:   color.withOpacity(0.06),
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    child: AppInfoRow.stacked(label, value,
        valueColor: color, bold: true),
  );
}