// lib/features/dashboard/presentation/widgets/revenue_chart.dart

import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/theme/text_theme.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';

class RevenueChart extends StatefulWidget {
  final List<double> monthlyRevenues;

  const RevenueChart({super.key, required this.monthlyRevenues});

  @override
  State<RevenueChart> createState() => _RevenueChartState();
}

class _RevenueChartState extends State<RevenueChart> {
  int touchedIndex = -1;

  static const _monthKeys = [
    'dashboard.months_jan',
    'dashboard.months_feb',
    'dashboard.months_mar',
    'dashboard.months_apr',
    'dashboard.months_may',
    'dashboard.months_jun',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = AppSizeVertical.instance;

    final maxRevenue = widget.monthlyRevenues.isEmpty
        ? 0.0
        : widget.monthlyRevenues.reduce(max);
    final maxY = maxRevenue == 0 ? 1000.0 : maxRevenue * 1.2;

    return Container(
      width: double.infinity, // لتوحيد العرض مع باقي كروت الداشبورد
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3), // نفس درجة الشفافية بتاعة DebtChart
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header موحد مع DebtChart ───
          Text(
            'dashboard.revenueChart'.tr().toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: ColorsManager.defaultTextSecondary,
              letterSpacing: 1.2,
              fontFamily: AppTextTheme.fontFamily, // ربط الخط
            ),
          ),
          SizedBox(height: v.s32),

          // ─── البار شارت ───
          AspectRatio(
            aspectRatio: 1.7,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                backgroundColor: Colors.transparent,

                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: ColorsManager.primaryDark, // الطريقة الأحدث
                    tooltipRoundedRadius: 8.r,
                    tooltipPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    tooltipMargin: 8.h,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()}',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          fontFamily: AppTextTheme.fontFamily, // توحيد الخط
                        ),
                      );
                    },
                  ),
                  touchCallback: (FlTouchEvent event, barTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          barTouchResponse == null ||
                          barTouchResponse.spot == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                    });
                  },
                ),

                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: theme.dividerColor.withOpacity(0.4),
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),

                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42.w,
                      getTitlesWidget: (val, _) {
                        if (val == 0) return const SizedBox.shrink();
                        return Text(
                          '${(val / 1000).toInt()}k',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: ColorsManager.defaultTextSecondary,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTextTheme.fontFamily,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32.h,
                      getTitlesWidget: (val, _) {
                        final index = val.toInt();
                        if (index < 0 || index >= _monthKeys.length) return const SizedBox.shrink();

                        final isTouched = index == touchedIndex;
                        return Padding(
                          padding: EdgeInsets.only(top: 10.h),
                          child: Text(
                            _monthKeys[index].tr(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: isTouched ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary,
                              fontWeight: isTouched ? FontWeight.w800 : FontWeight.w600,
                              fontFamily: AppTextTheme.fontFamily,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),

                barGroups: List.generate(
                  widget.monthlyRevenues.length,
                      (i) {
                    final isTouched = i == touchedIndex;
                    final opacity = (touchedIndex == -1 || isTouched) ? 1.0 : 0.4;

                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: widget.monthlyRevenues[i],
                          width: isTouched ? 28.w : 22.w,

                          gradient: LinearGradient(
                            colors: [
                              ColorsManager.primaryColor.withOpacity(opacity),
                              ColorsManager.primaryColor.withOpacity(opacity * 0.5),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),

                          borderRadius: BorderRadius.circular(100.r),

                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: maxY,
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}