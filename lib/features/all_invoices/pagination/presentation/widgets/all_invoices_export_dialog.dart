// lib/features/all_invoices/presentation/widgets/all_invoices_export_dialog.dart

import 'dart:typed_data';

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:bungee_manage_sys/features/all_invoices/pagination/presentation/cubit/all_invoices_cubit.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/invoice_entity.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart' hide Border;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

// ─── Local-only enums ────────────────────────────────────────────────────────

enum _ExportPeriod { all, today, week, month, custom }

// ─────────────────────────────────────────────────────────────────────────────
// Dialog
// ─────────────────────────────────────────────────────────────────────────────

class AllInvoicesExportDialog extends StatefulWidget {
  const AllInvoicesExportDialog({super.key});

  @override
  State<AllInvoicesExportDialog> createState() =>
      _AllInvoicesExportDialogState();
}

class _AllInvoicesExportDialogState extends State<AllInvoicesExportDialog> {
  _ExportPeriod _period = _ExportPeriod.all;
  DateTimeRange? _customRange;
  InvoiceStatusFilter _statusFilter   = InvoiceStatusFilter.all;
  PaymentStatusFilter _paymentFilter  = PaymentStatusFilter.all;
  bool _isExporting = false;

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickRange() async {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      builder: (ctx, child) => Theme(
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
        _period      = _ExportPeriod.custom;
      });
    }
  }

  // ── Date range resolution ──────────────────────────────────────────────────
  ({DateTime? start, DateTime? end}) get _resolvedRange {
    final now = DateTime.now();
    return switch (_period) {
      _ExportPeriod.all   => (start: null, end: null),
      _ExportPeriod.today => (start: DateTime(now.year, now.month, now.day), end: now),
      _ExportPeriod.week  => (start: now.subtract(const Duration(days: 6)), end: now),
      _ExportPeriod.month => (
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
      ),
      _ExportPeriod.custom => _customRange != null
          ? (start: _customRange!.start, end: _customRange!.end)
          : (start: null, end: null),
    };
  }

  bool get _canExport =>
      _period != _ExportPeriod.custom || _customRange != null;

  // ── Export logic ───────────────────────────────────────────────────────────
  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      // Pull invoices from the cubit (all loaded pages are already in state).
      // For a full export we call the cubit to fetch all without pagination.
      final cubit = context.read<AllInvoicesCubit>();
      final invoices = await cubit.fetchAllForExport(
        statusFilter:  _statusFilter,
        paymentFilter: _paymentFilter,
        startDate:     _resolvedRange.start,
        endDate:       _resolvedRange.end,
      );

      await _buildAndSaveExcel(invoices);

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('all_invoices.export_error'.tr()),
            backgroundColor: ColorsManager.errorFill,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _buildAndSaveExcel(List<AllInvoiceEntity> invoices) async {
    final cur     = 'dashboard.currency'.tr();
    final dateFmt = DateFormat('yyyy-MM-dd');

    // ── Period label for title ─────────────────────────────────────────────
    final range  = _resolvedRange;
    final period = range.start == null
        ? 'كل الفترات'
        : range.start == range.end
        ? dateFmt.format(range.start!)
        : '${dateFmt.format(range.start!)} → ${dateFmt.format(range.end!)}';

    // ── Create workbook ────────────────────────────────────────────────────
    final excel     = Excel.createExcel();
    final sheetName = 'all_invoices.export_sheet_name'.tr();
    final sheet     = excel[sheetName];
    excel.setDefaultSheet(sheetName);
    sheet.isRTL = true;

    // Styles
    final titleStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Center,
    );
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final dataStyle = CellStyle(
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    final summaryStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );

    // Column widths
    sheet.setColumnWidth(0, 18);  // رقم الفاتورة
    sheet.setColumnWidth(1, 16);  // التاريخ
    sheet.setColumnWidth(2, 20);  //  اسم العمل
    sheet.setColumnWidth(3, 20);  //  جهة الإنتاج
    sheet.setColumnWidth(4, 14);  // الحالة
    sheet.setColumnWidth(5, 14);  // الإجمالي
    sheet.setColumnWidth(6, 14);  // الخصم
    sheet.setColumnWidth(7, 14);  // الصافي
    sheet.setColumnWidth(8, 40);  // الأصناف
    int row = 0;

    // ── Report title ──────────────────────────────────────────────────────
    sheet.appendRow([
      TextCellValue('all_invoices.export_report_title'.tr(namedArgs: {'period': period})),
    ]);
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle = titleStyle;
    row++;

    sheet.appendRow([TextCellValue('')]);
    row++;

    // ── Column headers ────────────────────────────────────────────────────
    final headers = [
      'all_invoices.export_col_number'.tr(),
      'all_invoices.export_col_customer'.tr(),
      'all_invoices.export_col_phone'.tr(),
      'all_invoices.export_col_status'.tr(),
      'all_invoices.export_col_net_total'.tr(),
      'all_invoices.export_col_paid'.tr(),
      'all_invoices.export_col_remaining'.tr(),
      'all_invoices.export_col_date'.tr(),
    ];
    sheet.appendRow(headers.map(TextCellValue.new).toList());
    for (int c = 0; c < headers.length; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = headerStyle;
    }
    row++;

    // ── Data rows ─────────────────────────────────────────────────────────
    double totalNet       = 0;
    double totalPaidSum   = 0;
    double totalRemaining = 0;

    for (final inv in invoices) {
      final statusStr = switch (inv.status) {
        InvoiceStatus.active    => 'invoices.status_active'.tr(),
        InvoiceStatus.completed => 'invoices.status_completed'.tr(),
        InvoiceStatus.canceled  => 'invoices.status_canceled'.tr(),
        _                       => 'invoices.status_draft'.tr(),
      };

      final numLabel = inv.invoiceNumber != null
          ? '#${inv.invoiceNumber}'
          : inv.id.substring(0, 8).toUpperCase();

      sheet.appendRow([
        TextCellValue(numLabel),
        TextCellValue(inv.customerName),
        TextCellValue(inv.customerPhone ?? ''),
        TextCellValue(statusStr),
        DoubleCellValue(inv.netTotal),
        DoubleCellValue(inv.totalPaid),
        DoubleCellValue(inv.remaining),
        TextCellValue(dateFmt.format(inv.createdAt)),
      ]);

      for (int c = 0; c < 8; c++) {
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
            .cellStyle = dataStyle;
      }
      row++;

      totalNet       += inv.netTotal;
      totalPaidSum   += inv.totalPaid;
      totalRemaining += inv.remaining;
    }

    // ── Summary row ───────────────────────────────────────────────────────
    sheet.appendRow([TextCellValue('')]);
    row++;

    sheet.appendRow([
      TextCellValue('all_invoices.export_summary_total'.tr()),
      TextCellValue('${invoices.length}'),
      TextCellValue(''),
      TextCellValue(''),
      DoubleCellValue(totalNet),
      DoubleCellValue(totalPaidSum),
      DoubleCellValue(totalRemaining),
      TextCellValue(''),
    ]);
    for (int c = 0; c < 8; c++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row))
          .cellStyle = summaryStyle;
    }

    // ── Save ──────────────────────────────────────────────────────────────
    final bytes = excel.encode();
    if (bytes != null) {
      final fileName =
          'Invoices_Report_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: Uint8List.fromList(bytes),
        ext: 'xlsx',
        mimeType: MimeType.microsoftExcel,
      );
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor:
      isDark ? ColorsManager.secondaryDarkColor : ColorsManager.backgroundCard,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      child: Container(
        width: 460.w,
        padding: EdgeInsets.all(24.r),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: ColorsManager.successFill.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      Icons.file_download_outlined,
                      size: 18.r,
                      color: ColorsManager.successText,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'all_invoices.export_title'.tr(),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : ColorsManager.defaultText,
                          ),
                        ),
                        Text(
                          'تصدير الفواتير إلى ملف Excel',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: ColorsManager.defaultTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      size: 20.r,
                      color: ColorsManager.defaultTextSecondary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 20.h),
              _Divider(isDark: isDark),
              SizedBox(height: 16.h),

              // ── Period ─────────────────────────────────────────────────
              _SectionLabel(
                label: 'all_invoices.export_period'.tr(),
                isDark: isDark,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: [
                  _PeriodChip(
                    label: 'all_invoices.export_period_all'.tr(),
                    isSelected: _period == _ExportPeriod.all,
                    onTap: () => setState(() => _period = _ExportPeriod.all),
                  ),
                  _PeriodChip(
                    label: 'all_invoices.export_period_today'.tr(),
                    isSelected: _period == _ExportPeriod.today,
                    onTap: () => setState(() => _period = _ExportPeriod.today),
                  ),
                  _PeriodChip(
                    label: 'all_invoices.export_period_week'.tr(),
                    isSelected: _period == _ExportPeriod.week,
                    onTap: () => setState(() => _period = _ExportPeriod.week),
                  ),
                  _PeriodChip(
                    label: 'all_invoices.export_period_month'.tr(),
                    isSelected: _period == _ExportPeriod.month,
                    onTap: () => setState(() => _period = _ExportPeriod.month),
                  ),
                ],
              ),
              SizedBox(height: 8.h),

              // Custom date range picker
              InkWell(
                onTap: _pickRange,
                borderRadius: BorderRadius.circular(8.r),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.r),
                    color: _period == _ExportPeriod.custom
                        ? ColorsManager.primaryColor.withOpacity(0.07)
                        : (isDark
                        ? ColorsManager.darkColor
                        : ColorsManager.defaultSurface),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_outlined,
                        size: 16.r,
                        color: _period == _ExportPeriod.custom
                            ? ColorsManager.primaryColor
                            : ColorsManager.defaultTextSecondary,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          _period == _ExportPeriod.custom &&
                              _customRange != null
                              ? '${DateFormat('yyyy/MM/dd').format(_customRange!.start)}'
                              ' إلى '
                              '${DateFormat('yyyy/MM/dd').format(_customRange!.end)}'
                              : 'all_invoices.export_period_custom'.tr(),
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: _period == _ExportPeriod.custom
                                ? ColorsManager.primaryColor
                                : ColorsManager.defaultTextSecondary,
                            fontWeight: _period == _ExportPeriod.custom
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 20.h),
              _Divider(isDark: isDark),
              SizedBox(height: 16.h),

              // ── Status filter ──────────────────────────────────────────
              _SectionLabel(
                label: 'all_invoices.export_status'.tr(),
                isDark: isDark,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: InvoiceStatusFilter.values
                    .map((f) => _FilterChip(
                  label: _statusLabel(f),
                  isSelected: _statusFilter == f,
                  onTap: () => setState(() => _statusFilter = f),
                ))
                    .toList(),
              ),

              SizedBox(height: 16.h),

              // ── Payment filter ─────────────────────────────────────────
              _SectionLabel(
                label: 'all_invoices.export_payment'.tr(),
                isDark: isDark,
              ),
              SizedBox(height: 10.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: PaymentStatusFilter.values
                    .map((f) => _FilterChip(
                  label: _paymentLabel(f),
                  isSelected: _paymentFilter == f,
                  onTap: () => setState(() => _paymentFilter = f),
                ))
                    .toList(),
              ),

              SizedBox(height: 24.h),

              // ── Export button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: (_canExport && !_isExporting)
                      ? _handleExport
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorsManager.successFill,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor:
                    ColorsManager.successFill.withOpacity(0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                  child: _isExporting
                      ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.file_download_outlined, size: 18.r),
                      SizedBox(width: 8.w),
                      Text(
                        'all_invoices.export_btn'.tr(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(InvoiceStatusFilter f) => switch (f) {
    InvoiceStatusFilter.all       => 'all_invoices.status_all'.tr(),
    InvoiceStatusFilter.active    => 'invoices.status_active'.tr(),
    InvoiceStatusFilter.completed => 'invoices.status_completed'.tr(),
    InvoiceStatusFilter.canceled  => 'invoices.status_canceled'.tr(),
    InvoiceStatusFilter.draft     => 'invoices.status_draft'.tr(),
  };

  String _paymentLabel(PaymentStatusFilter f) => switch (f) {
    PaymentStatusFilter.all       => 'all_invoices.payment_all'.tr(),
    PaymentStatusFilter.fullyPaid => 'all_invoices.payment_paid'.tr(),
    PaymentStatusFilter.hasDebt   => 'all_invoices.payment_partial'.tr(),
    PaymentStatusFilter.unpaid    => 'all_invoices.payment_unpaid'.tr(),
  };
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;

  const _SectionLabel({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: ColorsManager.defaultTextSecondary,
        letterSpacing: 0.3,
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      color: isDark ? Colors.grey.shade800 : ColorsManager.inputBorder,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor
              : (isDark ? ColorsManager.darkColor : ColorsManager.defaultSurface),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : ColorsManager.defaultText),
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withOpacity(0.12)
              : (isDark ? ColorsManager.darkColor : ColorsManager.defaultSurface),
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? ColorsManager.primaryColor
                : (isDark ? Colors.white70 : ColorsManager.defaultText),
          ),
        ),
      ),
    );
  }
}