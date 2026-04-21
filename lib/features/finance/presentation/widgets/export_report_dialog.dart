// lib/features/finance/presentation/widgets/export_report_dialog.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/finance/domain/entities/financial_transaction_entity.dart';
import 'package:bungee_manage_sys/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

enum ReportPeriod { today, thisWeek, thisMonth, custom }
enum ReportAccFilter { all, cash, bank }
enum ReportTypeFilter { all, income, expense }

class ExportReportDialog extends StatefulWidget {
  const ExportReportDialog({super.key});

  @override
  State<ExportReportDialog> createState() => _ExportReportDialogState();
}

class _ExportReportDialogState extends State<ExportReportDialog> {
  ReportAccFilter _selectedAcc = ReportAccFilter.all;
  ReportTypeFilter _selectedType = ReportTypeFilter.all;
  ReportPeriod _selectedPeriod = ReportPeriod.today;
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
      builder: (context, child) {
        return Theme(
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
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = ReportPeriod.custom;
      });
    }
  }

  void _handleExport() {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    switch (_selectedPeriod) {
      case ReportPeriod.today:
        startDate = now;
        endDate = now;
        break;
      case ReportPeriod.thisWeek:
        startDate = now.subtract(const Duration(days: 6));
        endDate = now;
        break;
      case ReportPeriod.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        endDate = DateTime(now.year, now.month + 1, 0);
        break;
      case ReportPeriod.custom:
        if (_customDateRange == null) return;
        startDate = _customDateRange!.start;
        endDate = _customDateRange!.end;
        break;
    }

    // ترجمة الفلاتر للـ Enums بتاعة الدومين
    PaymentMethod? methodArg;
    if (_selectedAcc == ReportAccFilter.cash) methodArg = PaymentMethod.cash;
    if (_selectedAcc == ReportAccFilter.bank) methodArg = PaymentMethod.bank;

    TransactionType? typeArg;
    if (_selectedType == ReportTypeFilter.income) typeArg = TransactionType.income;
    if (_selectedType == ReportTypeFilter.expense) typeArg = TransactionType.expense;

    Navigator.of(context).pop();
    context.read<FinanceCubit>().exportLedgerToExcel(
      method: methodArg,
      type: typeArg,
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
        width: 480.w, // عرضناه شوية عشان الفلاتر الجديدة
        padding: EdgeInsets.all(24.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'استخراج تقرير مالي (Excel)',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: theme.iconTheme.color),
                  ),
                ],
              ),
              SizedBox(height: 20.h),

              // ─── اختيار الحساب ───
              Text(
                'الحساب المطلوب:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _SelectionBtn(
                      label: 'الكل',
                      icon: Icons.account_balance_wallet,
                      isSelected: _selectedAcc == ReportAccFilter.all,
                      onTap: () => setState(() => _selectedAcc = ReportAccFilter.all),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _SelectionBtn(
                      label: 'الخزينة',
                      icon: Icons.point_of_sale,
                      isSelected: _selectedAcc == ReportAccFilter.cash,
                      onTap: () => setState(() => _selectedAcc = ReportAccFilter.cash),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _SelectionBtn(
                      label: 'البنك',
                      icon: Icons.account_balance,
                      isSelected: _selectedAcc == ReportAccFilter.bank,
                      onTap: () => setState(() => _selectedAcc = ReportAccFilter.bank),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // ─── اختيار نوع الحركة ───
              Text(
                'نوع الحركة:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Row(
                children: [
                  Expanded(
                    child: _SelectionBtn(
                      label: 'يومية (الكل)',
                      icon: Icons.import_export,
                      isSelected: _selectedType == ReportTypeFilter.all,
                      onTap: () => setState(() => _selectedType = ReportTypeFilter.all),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _SelectionBtn(
                      label: 'الوارد فقط',
                      icon: Icons.arrow_downward,
                      isSelected: _selectedType == ReportTypeFilter.income,
                      onTap: () => setState(() => _selectedType = ReportTypeFilter.income),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: _SelectionBtn(
                      label: 'الصادر فقط',
                      icon: Icons.arrow_upward,
                      isSelected: _selectedType == ReportTypeFilter.expense,
                      onTap: () => setState(() => _selectedType = ReportTypeFilter.expense),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // ─── اختيار الفترة ───
              Text(
                'عن فترة:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _PeriodChip(
                    label: 'اليوم',
                    isSelected: _selectedPeriod == ReportPeriod.today,
                    onTap: () => setState(() => _selectedPeriod = ReportPeriod.today),
                  ),
                  _PeriodChip(
                    label: 'آخر 7 أيام',
                    isSelected: _selectedPeriod == ReportPeriod.thisWeek,
                    onTap: () => setState(() => _selectedPeriod = ReportPeriod.thisWeek),
                  ),
                  _PeriodChip(
                    label: 'الشهر الحالي',
                    isSelected: _selectedPeriod == ReportPeriod.thisMonth,
                    onTap: () => setState(() => _selectedPeriod = ReportPeriod.thisMonth),
                  ),
                ],
              ),
              SizedBox(height: 12.h),

              // ─── فترة مخصصة ───
              InkWell(
                onTap: _pickDateRange,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _selectedPeriod == ReportPeriod.custom
                          ? ColorsManager.primaryColor
                          : theme.dividerColor,
                      width: _selectedPeriod == ReportPeriod.custom ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    color: _selectedPeriod == ReportPeriod.custom
                        ? ColorsManager.primaryColor.withOpacity(0.08)
                        : theme.scaffoldBackgroundColor,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range,
                        color: _selectedPeriod == ReportPeriod.custom
                            ? ColorsManager.primaryColor
                            : theme.textTheme.bodyMedium?.color,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          _selectedPeriod == ReportPeriod.custom && _customDateRange != null
                              ? '${DateFormat('yyyy/MM/dd').format(_customDateRange!.start)} إلى ${DateFormat('yyyy/MM/dd').format(_customDateRange!.end)}'
                              : 'تحديد فترة مخصصة...',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: _selectedPeriod == ReportPeriod.custom
                                ? ColorsManager.primaryColor
                                : theme.textTheme.bodyMedium?.color,
                            fontWeight: _selectedPeriod == ReportPeriod.custom
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 24.h),

              // ─── زرار الإرسال ───
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton.icon(
                  onPressed: (_selectedPeriod == ReportPeriod.custom && _customDateRange == null)
                      ? null
                      : _handleExport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.successFill,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                    disabledBackgroundColor: ColorsManager.successFill.withOpacity(0.4),
                  ),
                  icon: const Icon(Icons.file_download_outlined),
                  label: Text('تصدير Excel', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withOpacity(0.08)
              : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? ColorsManager.primaryColor : theme.dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20.r,
              color: isSelected ? ColorsManager.primaryColor : theme.textTheme.bodyMedium?.color,
            ),
            SizedBox(height: 6.h),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? ColorsManager.primaryColor : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? ColorsManager.primaryColor : theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? ColorsManager.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13.sp,
          ),
        ),
      ),
    );
  }
}