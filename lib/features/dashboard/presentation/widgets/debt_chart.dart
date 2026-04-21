// lib/features/dashboard/presentation/widgets/debt_chart.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/theme/text_theme.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';

class DebtChart extends StatefulWidget {
  final double totalCollectedPercent;
  final double totalDebtPercent;

  const DebtChart({
    super.key,
    required this.totalCollectedPercent,
    required this.totalDebtPercent,
  });

  @override
  State<DebtChart> createState() => _DebtChartState();
}

class _DebtChartState extends State<DebtChart>
    with SingleTickerProviderStateMixin {
  int _touchedIndex = -1;

  static const _colorCollected      = Color(0xFF3266AD);
  static const _colorCollectedLight = Color(0xFF4A80CC);
  static const _colorDebt           = Color(0xFFE9A23B);
  static const _colorDebtLight      = Color(0xFFF0B94A);

  late final AnimationController _animCtrl;
  late final Animation<double>   _labelAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _labelAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _onTouch(int index) {
    if (_touchedIndex == index) return;
    setState(() => _touchedIndex = index);
    _animCtrl.forward(from: 0);
  }

  void _onRelease() {
    if (_touchedIndex == -1) return;
    setState(() => _touchedIndex = -1);
    _animCtrl.forward(from: 0);
  }

  String get _centerPercent {
    if (_touchedIndex == 1) return '${widget.totalDebtPercent.toInt()}%';
    return '${widget.totalCollectedPercent.toInt()}%';
  }

  String get _centerLabel {
    if (_touchedIndex == 1) return 'dashboard.debt'.tr();
    return 'dashboard.collected'.tr();
  }

  Color get _centerColor {
    if (_touchedIndex == 1) return _colorDebt;
    return _colorCollected;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.dividerColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            'dashboard.debtChart'.tr().toUpperCase(),
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: ColorsManager.defaultTextSecondary,
              letterSpacing: 1.2,
              fontFamily: AppTextTheme.fontFamily,
            ),
          ),

          // 🌟 السر هنا: استخدام Expanded عشان يسحب كل المساحة الفاضية ويسنتر الرسمة فيها 🌟
          Expanded(
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 32.w, // المسافة بين الرسمة والمؤشرات
                runSpacing: 24.h,
                children: [

                  // ── 1. Chart ──
                  SizedBox(
                    width: 200.r,
                    height: 200.r,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 55.r,
                            startDegreeOffset: -90,
                            pieTouchData: PieTouchData(
                              touchCallback: (event, response) {
                                if (event is FlTapUpEvent ||
                                    event is FlPointerHoverEvent ||
                                    event is FlPointerExitEvent) {
                                  if (response?.touchedSection != null &&
                                      event is! FlPointerExitEvent) {
                                    _onTouch(response!.touchedSection!.touchedSectionIndex);
                                  } else if (event is FlPointerExitEvent || event is FlTapUpEvent) {
                                    _onRelease();
                                  }
                                }
                                if (event is FlLongPressEnd) _onRelease();
                              },
                            ),
                            sections: [
                              _buildSection(
                                index: 0,
                                value: widget.totalCollectedPercent,
                                color: _colorCollected,
                                hoverColor: _colorCollectedLight,
                                isTouched: _touchedIndex == 0,
                              ),
                              _buildSection(
                                index: 1,
                                value: widget.totalDebtPercent,
                                color: _colorDebt,
                                hoverColor: _colorDebtLight,
                                isTouched: _touchedIndex == 1,
                              ),
                            ],
                          ),
                          swapAnimationDuration: const Duration(milliseconds: 300),
                          swapAnimationCurve: Curves.easeOutCubic,
                        ),

                        // ── Center Text ──
                        AnimatedBuilder(
                          animation: _labelAnim,
                          builder: (_, __) => Opacity(
                            opacity: 0.7 + 0.3 * _labelAnim.value,
                            child: Transform.scale(
                              scale: 0.93 + 0.07 * _labelAnim.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 24.sp,
                                      fontWeight: FontWeight.w800,
                                      color: _centerColor,
                                      height: 1,
                                      fontFamily: AppTextTheme.fontFamily,
                                    ),
                                    child: Text(_centerPercent),
                                  ),
                                  SizedBox(height: 4.h),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 200),
                                    style: TextStyle(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: ColorsManager.defaultTextSecondary,
                                      fontFamily: AppTextTheme.fontFamily,
                                    ),
                                    child: Text(_centerLabel),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 2. Legend ──
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(
                        color: _colorCollected,
                        label: 'dashboard.collected'.tr(),
                        value: widget.totalCollectedPercent,
                        isActive: _touchedIndex == 0,
                        isInactive: _touchedIndex == 1,
                        onEnter: () => _onTouch(0),
                        onExit: _onRelease,
                      ),
                      SizedBox(height: 20.h),
                      _LegendItem(
                        color: _colorDebt,
                        label: 'dashboard.debt'.tr(),
                        value: widget.totalDebtPercent,
                        isActive: _touchedIndex == 1,
                        isInactive: _touchedIndex == 0,
                        onEnter: () => _onTouch(1),
                        onExit: _onRelease,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildSection({
    required int    index,
    required double value,
    required Color  color,
    required Color  hoverColor,
    required bool   isTouched,
  }) {
    final radius = isTouched ? 74.r : 60.r;
    return PieChartSectionData(
      value:       value,
      color:       isTouched ? hoverColor : color,
      title:       '',
      radius:      radius,
      borderSide:  const BorderSide(color: Colors.transparent, width: 0),
    );
  }
}

// ─── Legend item ──────────────────────────────────────────────────────────────

class _LegendItem extends StatelessWidget {
  final Color    color;
  final String   label;
  final double   value;
  final bool     isActive;
  final bool     isInactive;
  final VoidCallback onEnter;
  final VoidCallback onExit;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.isActive,
    required this.isInactive,
    required this.onEnter,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onEnter(),
      onExit:  (_) => onExit(),
      child: GestureDetector(
        onTap: onEnter,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity:  isInactive ? 0.35 : 1.0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width:       isActive ? 14.r : 12.r,
                height:      isActive ? 14.r : 12.r,
                decoration:  BoxDecoration(
                  color:        color,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 10.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color:    ColorsManager.defaultTextSecondary,
                      fontFamily: AppTextTheme.fontFamily,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize:   isActive ? 18.sp : 15.sp,
                      fontWeight: FontWeight.w700,
                      color:      isActive ? color : Theme.of(context).hintColor,
                      fontFamily: AppTextTheme.fontFamily,
                    ),
                    child: Text('${value.toInt()}%'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}