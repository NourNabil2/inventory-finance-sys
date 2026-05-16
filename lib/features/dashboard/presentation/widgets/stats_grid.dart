// lib/features/dashboard/presentation/widgets/stats_grid.dart

import 'package:bungee_manage_sys/core/utils/extension.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/widgets/stats_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/entities/dashboard_entity.dart';

class StatsGrid extends StatelessWidget {
  final DashboardEntity data;

  const StatsGrid({super.key, required this.data});

  /// Format growth percentage with + or - sign
  String _formatGrowthPercent(double percent) {
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    // Calculate dynamic growth percentage
    final growthPercent = data.revenueGrowthPercent;
    final growthText = '${_formatGrowthPercent(growthPercent)} ${'dashboard.fromLastMonth'.tr()}';
    final currency = 'dashboard.currency'.tr();

    final cards = [
      StatsCard(
        icon: Icons.attach_money,
        iconColor: ColorsManager.successFill,
        title: 'dashboard.totalRevenue'.tr(),
        mainValue: data.totalRevenue.toPrefixMoney(currency),
        subtitle: growthText,
      ),
      StatsCard(
        icon: Icons.videocam_outlined,
        iconColor: ColorsManager.warningFill,
        title: 'dashboard.activeRentals'.tr(),
        mainValue: data.activeRentals.toString(),
        subtitle: '',
      ),
      // 🆕 استبدال كارت المدفوعات المعلقة بكارت ديون الموردين
      StatsCard(
        icon: Icons.business_outlined,
        iconColor: ColorsManager.errorFill,
        title: 'dashboard.supplierDebts'.tr(),
        mainValue: data.supplierDebts.toPrefixMoney(currency),
        subtitle: 'dashboard.whatWeOwe'.tr(),
      ),
      StatsCard(
        icon: Icons.people_outline,
        iconColor: ColorsManager.errorFill,
        title: 'dashboard.customerDebts'.tr(),
        mainValue: data.customerDebts.toPrefixMoney(currency),
        subtitle: 'dashboard.debtors'
            .tr(namedArgs: {'count': '${data.debtorsCount}'}),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: isDesktop ? 1.7 : 1.4,
      children: cards,
    );
  }
}