// lib/core/widgets/app_info_row.dart
//
// A single widget that covers every label → value display pattern used
// throughout the invoice (and any other) feature:
//
//   • _TRow  in InvoiceTotalsCard
//   • _PillStat in InvoicePaymentCard
//   • InvoiceTotalLine in invoice_widgets.dart
//
// Variants
// ────────
//   AppInfoRow(label, value)                      → inline label + value
//   AppInfoRow.stacked(label, value)              → label above value (pill style)
//   AppInfoRow.bold(label, value)                 → emphasised total line
// ─────────────────────────────────────────────────────────────────────────────
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum _InfoRowLayout { inline, stacked }

class AppInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final _InfoRowLayout _layout;

  const AppInfoRow(
      this.label,
      this.value, {
        super.key,
        this.valueColor,
        this.bold = false,
      }) : _layout = _InfoRowLayout.inline;

  /// Label sits above the value — mirrors the old _PillStat widget.
  const AppInfoRow.stacked(
      this.label,
      this.value, {
        super.key,
        this.valueColor,
        this.bold = false,
      }) : _layout = _InfoRowLayout.stacked;

  /// Bold total-line variant — mirrors the old _TRow(bold: true).
  const AppInfoRow.bold(
      this.label,
      this.value, {
        super.key,
        this.valueColor,
      })  : bold = true,
        _layout = _InfoRowLayout.inline;

  @override
  Widget build(BuildContext context) {
    return _layout == _InfoRowLayout.stacked
        ? _buildStacked(context)
        : _buildInline(context);
  }

  Widget _buildInline(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 14.sp : 13.sp,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: ColorsManager.defaultTextSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16.sp : 13.sp,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStacked(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: ColorsManager.defaultTextSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? theme.textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}