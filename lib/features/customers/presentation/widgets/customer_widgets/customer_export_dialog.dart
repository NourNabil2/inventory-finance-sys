// lib/features/customers/presentation/widgets/customer_export_dialog.dart
//
// Usage:
//   showDialog(
//     context: context,
//     builder: (_) => BlocProvider.value(
//       value: context.read<InvoicesCubit>(),
//       child: CustomerExportDialog(
//         customerId: customer.id,
//         customerName: customer.name,
//       ),
//     ),
//   );

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

enum _ReportPeriod { last7Days, lastMonth, allTime, custom }

class CustomerExportDialog extends StatefulWidget {
  final String customerId;
  final String customerName;

  const CustomerExportDialog({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  @override
  State<CustomerExportDialog> createState() => _CustomerExportDialogState();
}

class _CustomerExportDialogState extends State<CustomerExportDialog> {
  _ReportPeriod _period = _ReportPeriod.last7Days;
  DateTimeRange? _customRange;

  Future<void> _pickDateRange() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (context, child) => Theme(
        data: theme.copyWith(
          colorScheme: isDark
              ? const ColorScheme.dark(
            primary: ColorsManager.primaryColor,
            onPrimary: Colors.white,
            surface: ColorsManager.darkColor,
            onSurface: Colors.white,
          )
              : const ColorScheme.light(
            primary: ColorsManager.primaryColor,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _customRange = picked;
        _period = _ReportPeriod.custom;
      });
    }
  }

  void _handleExport() {
    final now = DateTime.now();
    late DateTime startDate;
    late DateTime endDate;

    switch (_period) {
      case _ReportPeriod.last7Days:
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
      case _ReportPeriod.lastMonth:
        startDate = DateTime(now.year, now.month - 1, now.day);
        endDate = now;
      case _ReportPeriod.allTime:
        startDate = DateTime(2020);
        endDate = now;
      case _ReportPeriod.custom:
        if (_customRange == null) return;
        startDate = _customRange!.start;
        endDate = _customRange!.end;
    }

    Navigator.of(context).pop();

    context.read<InvoicesCubit>().exportCustomerReport(
      customerId: widget.customerId,
      customerName: widget.customerName,
      startDate: startDate,
      endDate: endDate,
    );
  }

  bool get _canExport =>
      _period != _ReportPeriod.custom || _customRange != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        width: 440.w,
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: ColorsManager.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.file_download_outlined,
                      color: ColorsManager.primaryColor, size: 20.r),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تصدير تقرير العميل',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 16.sp, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.customerName,
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: ColorsManager.primaryColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: theme.iconTheme.color, size: 20.r),
                ),
              ],
            ),

            SizedBox(height: 20.h),

            // ── Period selection ───────────────────────────────────────────
            Text(
              'اختر الفترة الزمنية',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13.sp),
            ),
            SizedBox(height: 10.h),

            // Chips row
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                _PeriodChip(
                  label: 'آخر 7 أيام',
                  icon: Icons.calendar_today_outlined,
                  isSelected: _period == _ReportPeriod.last7Days,
                  onTap: () => setState(() => _period = _ReportPeriod.last7Days),
                ),
                _PeriodChip(
                  label: 'آخر شهر',
                  icon: Icons.calendar_month_outlined,
                  isSelected: _period == _ReportPeriod.lastMonth,
                  onTap: () => setState(() => _period = _ReportPeriod.lastMonth),
                ),
                _PeriodChip(
                  label: 'كل الوقت',
                  icon: Icons.history_outlined,
                  isSelected: _period == _ReportPeriod.allTime,
                  onTap: () => setState(() => _period = _ReportPeriod.allTime),
                ),
              ],
            ),

            SizedBox(height: 10.h),

            // Custom date range picker
            InkWell(
              onTap: _pickDateRange,
              borderRadius: BorderRadius.circular(8.r),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: _period == _ReportPeriod.custom
                      ? ColorsManager.primaryColor.withOpacity(0.06)
                      : theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: _period == _ReportPeriod.custom
                        ? ColorsManager.primaryColor
                        : theme.dividerColor,
                    width: _period == _ReportPeriod.custom ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 18.r,
                      color: _period == _ReportPeriod.custom
                          ? ColorsManager.primaryColor
                          : theme.textTheme.bodySmall?.color,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        _period == _ReportPeriod.custom &&
                            _customRange != null
                            ? '${DateFormat('yyyy/MM/dd').format(_customRange!.start)}  →  ${DateFormat('yyyy/MM/dd').format(_customRange!.end)}'
                            : 'تحديد فترة مخصصة...',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: _period == _ReportPeriod.custom
                              ? ColorsManager.primaryColor
                              : theme.textTheme.bodySmall?.color,
                          fontWeight: _period == _ReportPeriod.custom
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      size: 16.r,
                      color: _period == _ReportPeriod.custom
                          ? ColorsManager.primaryColor
                          : theme.iconTheme.color?.withOpacity(0.4),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20.h),

            // ── What's included note ───────────────────────────────────────
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: ColorsManager.infoSurface,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 16.r, color: ColorsManager.infoText),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'الملف سيحتوي على: رقم الفاتورة، التاريخ، الحالة، الإجمالي، الخصم، الصافي، وتفاصيل الأصناف.',
                      style: TextStyle(
                          fontSize: 11.sp, color: ColorsManager.infoText),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            // ── Export button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: ElevatedButton.icon(
                onPressed: _canExport ? _handleExport : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorsManager.successFill,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.r)),
                  disabledBackgroundColor:
                  ColorsManager.successFill.withOpacity(0.4),
                ),
                icon: Icon(Icons.file_download_outlined, size: 18.r),
                label: Text(
                  'تصدير Excel',
                  style: TextStyle(
                      fontSize: 14.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Period chip ──────────────────────────────────────────────────────────────

class _PeriodChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? ColorsManager.primaryColor
                : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14.r,
              color: isSelected
                  ? Colors.white
                  : theme.textTheme.bodySmall?.color,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}