// lib/features/dashboard/presentation/widgets/stats_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/theme/text_theme.dart';

class StatsCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String mainValue;
  final String subtitle;

  const StatsCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.mainValue,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(20.r), // مساحة داخلية مريحة
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r), // نفس زوايا كروت الرسم البياني
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.3), // إطار خفيف جداً لتوحيد الشكل
          width: 1,
        ),
        boxShadow: [
          // ظل خفيف جداً يدي عمق للكارت
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center, // توسيط المحتوى رأسيًا
        children: [
          // ─── Header (الأيقونة + العنوان) ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1), // خلفية ناعمة بنفس لون الأيقونة
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: iconColor, size: 20.r),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: ColorsManager.defaultTextSecondary,
                    fontFamily: AppTextTheme.fontFamily,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // ─── Main Value (الرقم الأساسي) ───
          Text(
            mainValue,
            style: TextStyle(
              fontSize: 26.sp, // تكبير الرقم ليكون هو محور الانتباه
              fontWeight: FontWeight.w800, // خط عريض
              color: theme.textTheme.titleLarge?.color,
              fontFamily: AppTextTheme.fontFamily,
              letterSpacing: -0.5, // تقريب الأرقام من بعضها ليعطي مظهر Premium
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 10.h),

          // ─── Subtitle Badge (النص الفرعي) ───
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: ColorsManager.primaryColor.withOpacity(0.08), // خلفية خفيفة
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                color: ColorsManager.primaryColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                fontFamily: AppTextTheme.fontFamily,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}