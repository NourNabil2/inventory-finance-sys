import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

enum CustomersExportPeriod { allTime, today, thisWeek, thisMonth, custom }

class ExportCustomersDialog extends StatefulWidget {
  const ExportCustomersDialog({super.key});

  @override
  State<ExportCustomersDialog> createState() => _ExportCustomersDialogState();
}

class _ExportCustomersDialogState extends State<ExportCustomersDialog> {
  CustomersExportPeriod _selectedPeriod = CustomersExportPeriod.allTime;
  DateTimeRange? _customDateRange;

  Future<void> _pickDateRange() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
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
        _customDateRange = picked;
        _selectedPeriod = CustomersExportPeriod.custom;
      });
    }
  }

  void _handleExport() {
    final now = DateTime.now();
    DateTime? startDate;
    DateTime? endDate;

    switch (_selectedPeriod) {
      case CustomersExportPeriod.allTime:
        break;
      case CustomersExportPeriod.today:
        startDate = DateTime(now.year, now.month, now.day);
        endDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case CustomersExportPeriod.thisWeek:
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
        break;
      case CustomersExportPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59, 999);
        break;
      case CustomersExportPeriod.custom:
        if (_customDateRange == null) return;
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end;
        break;
    }

    Navigator.of(context).pop();

    // استدعاء الـ Cubit — هو اللي هيجيب الـ customers ويبعتهم لـ CustomersExcelExport
    context.read<CustomersCubit>().exportCustomersToExcel(
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: theme.cardColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        width: 420.w,
        padding: EdgeInsets.all(24.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: ColorsManager.successFill.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.table_chart_rounded,
                      color: ColorsManager.successFill,
                      size: 22.r,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تصدير بيانات العملاء',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16.sp,
                          ),
                        ),
                        Text(
                          'Excel • ورقتان: ملخص + تفاصيل',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: theme.iconTheme.color, size: 20.r),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              Divider(color: theme.dividerColor, height: 1),
              SizedBox(height: 20.h),

              // ─── Period chips ─────────────────────────────────────────────
              Text(
                'الفترة الزمنية',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _PeriodChip(
                    label: 'كل الوقت',
                    icon: Icons.all_inclusive_rounded,
                    isSelected: _selectedPeriod == CustomersExportPeriod.allTime,
                    onTap: () => setState(() => _selectedPeriod = CustomersExportPeriod.allTime),
                  ),
                  _PeriodChip(
                    label: 'اليوم',
                    icon: Icons.today_rounded,
                    isSelected: _selectedPeriod == CustomersExportPeriod.today,
                    onTap: () => setState(() => _selectedPeriod = CustomersExportPeriod.today),
                  ),
                  _PeriodChip(
                    label: 'آخر 7 أيام',
                    icon: Icons.date_range_rounded,
                    isSelected: _selectedPeriod == CustomersExportPeriod.thisWeek,
                    onTap: () => setState(() => _selectedPeriod = CustomersExportPeriod.thisWeek),
                  ),
                  _PeriodChip(
                    label: 'الشهر الحالي',
                    icon: Icons.calendar_month_rounded,
                    isSelected: _selectedPeriod == CustomersExportPeriod.thisMonth,
                    onTap: () => setState(() => _selectedPeriod = CustomersExportPeriod.thisMonth),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              // ─── Custom date picker ───────────────────────────────────────
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(8.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedPeriod == CustomersExportPeriod.custom
                          ? ColorsManager.primaryColor
                          : theme.dividerColor,
                      width: _selectedPeriod == CustomersExportPeriod.custom ? 1.8 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    color: _selectedPeriod == CustomersExportPeriod.custom
                        ? ColorsManager.primaryColor.withOpacity(0.07)
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 18.r,
                        color: _selectedPeriod == CustomersExportPeriod.custom
                            ? ColorsManager.primaryColor
                            : theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _selectedPeriod == CustomersExportPeriod.custom && _customDateRange != null
                              ? '${DateFormat('yyyy/MM/dd').format(_customDateRange!.start)}  →  ${DateFormat('yyyy/MM/dd').format(_customDateRange!.end)}'
                              : 'تحديد فترة مخصصة...',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: _selectedPeriod == CustomersExportPeriod.custom
                                ? ColorsManager.primaryColor
                                : theme.textTheme.bodyMedium?.color?.withOpacity(0.55),
                            fontWeight: _selectedPeriod == CustomersExportPeriod.custom
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_left_rounded,
                        size: 18.r,
                        color: _selectedPeriod == CustomersExportPeriod.custom
                            ? ColorsManager.primaryColor
                            : theme.iconTheme.color?.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),

              // ─── What's inside card ───────────────────────────────────────
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 14.r, color: ColorsManager.primaryColor),
                        SizedBox(width: 6.w),
                        Text(
                          'محتوى الملف',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: ColorsManager.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    _ContentRow(icon: Icons.bar_chart_rounded, text: 'ورقة 1: ملخص وإحصائيات (نشط / غير نشط / إجمالي المشتريات)'),
                    SizedBox(height: 4.h),
                    _ContentRow(icon: Icons.table_rows_rounded, text: 'ورقة 2: بيانات كل العملاء بالتفصيل'),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ─── Export button ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 46.h,
                child: ElevatedButton.icon(
                  onPressed: (_selectedPeriod == CustomersExportPeriod.custom &&
                      _customDateRange == null)
                      ? null
                      : _handleExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.successFill,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r)),
                    disabledBackgroundColor:
                    ColorsManager.successFill.withOpacity(0.35),
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
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────

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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
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
              size: 13.r,
              color: isSelected ? Colors.white : theme.iconTheme.color?.withOpacity(0.6),
            ),
            SizedBox(width: 5.w),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContentRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13.r, color: theme.textTheme.bodySmall?.color?.withOpacity(0.6)),
        SizedBox(width: 6.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11.sp,
              color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}