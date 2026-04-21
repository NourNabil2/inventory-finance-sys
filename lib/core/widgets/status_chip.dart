// lib/core/widgets/status_chip.dart

import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';

class StatusChip extends StatelessWidget {
  final String label;
  final ChipStatus status;

  const StatusChip({
    super.key,
    required this.label,
    required this.status,
  });

  ({Color surface, Color fill, Color text}) get _colors => switch (status) {
    ChipStatus.available || ChipStatus.cashed || ChipStatus.success || ChipStatus.completed => (
    surface: ColorsManager.successSurface,
    fill: ColorsManager.successFill,
    text: ColorsManager.successText,
    ),
    ChipStatus.rented || ChipStatus.active || ChipStatus.info => (
    surface: ColorsManager.infoSurface,
    fill: ColorsManager.infoFill,
    text: ColorsManager.infoText,
    ),
    ChipStatus.maintenance || ChipStatus.pending || ChipStatus.warning || ChipStatus.draft => (
    surface: ColorsManager.warningSurface,
    fill: ColorsManager.warningFill,
    text: ColorsManager.warningText,
    ),
    ChipStatus.reserved || ChipStatus.canceled || ChipStatus.bounced || ChipStatus.error => (
    surface: ColorsManager.errorSurface,
    fill: ColorsManager.errorFill,
    text: ColorsManager.errorText,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = _colors;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: c.fill.withOpacity(0.4)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: c.text,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}