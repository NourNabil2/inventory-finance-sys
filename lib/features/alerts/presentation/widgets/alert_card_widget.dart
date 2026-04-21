import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/alerts/domain/entities/alert_entity.dart';
import 'package:bungee_manage_sys/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class AlertCardWidget extends StatelessWidget {
  final AlertEntity alert;

  const AlertCardWidget({super.key, required this.alert});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isOverdue = alert.isOverdue;
    final Color statusColor = isOverdue ? ColorsManager.errorFill : ColorsManager.primaryColor;
    final Color surfaceColor = isOverdue ? ColorsManager.errorSurface : ColorsManager.primaryColor.withOpacity(0.08);
    final String statusTitle = isOverdue ? 'alerts.overdue_title'.tr() : 'alerts.upcoming_title'.tr();
    final IconData statusIcon = isOverdue ? Icons.timer_off_outlined : Icons.notification_important_outlined;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Dismissible(
        key: Key(alert.id),
        direction: DismissDirection.endToStart, // السحب من اليمين لليسار للحذف
        onDismissed: (_) {
          context.read<AlertsCubit>().dismissAlert(alert.id);
        },
        background: Container(
          decoration: BoxDecoration(
            color: ColorsManager.errorFill,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.w),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(color: statusColor, width: 4.w),
                ),
              ),
              padding: EdgeInsets.all(16.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 22.r),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'alerts.rental_end'.tr(),
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleMedium?.color,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd').format(alert.dueDate),
                              style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          statusTitle,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(fontSize: 12.sp, color: theme.textTheme.bodyMedium?.color, height: 1.5),
                            children: [
                              TextSpan(text: '${'alerts.customer_word'.tr()} '),
                              TextSpan(text: alert.customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              TextSpan(text: ' ${isOverdue ? 'alerts.delayed_in_return'.tr() : 'alerts.has_upcoming_return'.tr()} '),
                              TextSpan(
                                  text: '${alert.qty}x ${alert.itemName}',
                                  style: TextStyle(fontWeight: FontWeight.w700, color: ColorsManager.primaryColor)
                              ),
                              if (isOverdue)
                                TextSpan(text: ' ${'alerts.since_days'.tr(namedArgs: {'days': '${alert.daysDiff.abs()}'})}'),
                            ],
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'alerts.invoice_num'.tr(namedArgs: {'id': alert.invoiceId.substring(0, 8).toUpperCase()}),
                          style: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 18.r, color: ColorsManager.defaultTextSecondary),
                    onPressed: () => context.read<AlertsCubit>().dismissAlert(alert.id),
                    tooltip: 'alerts.dismiss'.tr(),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}