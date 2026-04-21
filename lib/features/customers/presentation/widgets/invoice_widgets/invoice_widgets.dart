// lib/features/customers/presentation/widgets/invoice_widgets.dart
//
// Shared micro-widgets used by create, edit, and details pages.
// ─────────────────────────────────────────────────────────────
//
// Layout constants live in responsive_layout.dart (single source of truth):
//   • kContentMaxWidth  — max page content width (1100)
//   • kTableMinWidth    — min scrollable table width (680)
//   • pageHPad()        — responsive horizontal padding
//   • centredContentBox() — centred ConstrainedBox helper
// ─────────────────────────────────────────────────────────────
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/responsive_layout.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─── Form helpers ────────────────────────────────────────────

class InvoiceSectionLabel extends StatelessWidget {
  final String text;
  const InvoiceSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 14.sp,
      color: Theme.of(context).textTheme.titleSmall?.color,
    ),
  );
}

class InvoiceNumCell extends StatelessWidget {
  final TextEditingController ctrl;
  final bool allowDecimal;
  final String? suffix;
  final VoidCallback? onChanged;
  final FormFieldValidator<String>? validator;
  final double width;
  final bool readOnly; // 🚨 1. ضفنا خاصية القفل

  const InvoiceNumCell({
    super.key,
    required this.ctrl,
    this.allowDecimal = false,
    this.suffix,
    this.onChanged,
    this.validator,
    this.width = 70,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width.w,
      child: TextFormField(
        controller: ctrl,
        readOnly: readOnly, // 🚨 3. تطبيق القفل على الحقل
        keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
        textAlign: TextAlign.center,
        style: TextStyle(
            fontSize: 13.sp,
            // 🚨 لون باهت للموظف عشان يفهم إنها مقفولة
            color: readOnly ? ColorsManager.defaultTextSecondary : theme.textTheme.bodyMedium?.color
        ),
        onChanged: (_) => onChanged?.call(),
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          suffixText: suffix,
          suffixStyle: TextStyle(fontSize: 11.sp, color: ColorsManager.defaultTextSecondary),
          filled: true,
          // 🚨 خلفية رمادية لو الحقل مقفول
          fillColor: readOnly ? theme.dividerColor.withOpacity(0.05) : theme.cardColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: ColorsManager.primaryColor),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.r),
            borderSide: BorderSide(color: ColorsManager.errorFill),
          ),
          errorStyle: TextStyle(fontSize: 9.sp, height: 0.8),
        ),
      ),
    );
  }
}

class InvoiceColHdr extends StatelessWidget {
  final String text;
  final TextStyle style;
  final bool end;
  final double width;

  const InvoiceColHdr(
      this.text,
      this.style, {
        super.key,
        this.end = false,
        this.width = 70,
      });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width.w,
    child: Text(text, style: style, textAlign: end ? TextAlign.end : TextAlign.center),
  );
}

class InvoiceAddItemBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const InvoiceAddItemBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: enabled ? ColorsManager.primaryColor : ColorsManager.backgroundSurface,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.r,
            color: enabled ? Colors.white : ColorsManager.defaultTextSecondary,
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: enabled ? Colors.white : ColorsManager.defaultTextSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

class InvoiceSubmitBtn extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  final double? height;
  final EdgeInsets? padding;

  const InvoiceSubmitBtn({
    super.key,
    required this.label,
    required this.loading,
    required this.onTap,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: loading ? null : onTap,
    child: Container(
      height: (height ?? 44).h,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 24.w),
      decoration: BoxDecoration(
        color: loading
            ? ColorsManager.primaryColor.withOpacity(0.6)
            : ColorsManager.primaryColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Center(
        child: loading
            ? SizedBox(
          width: 20.r,
          height: 20.r,
          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : Text(
          label,
          style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

class InvoiceTotalLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const InvoiceTotalLine(
      this.label,
      this.value, {
        super.key,
        this.bold = false,
        this.valueColor,
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: bold ? 13.sp : 12.sp,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
          SizedBox(width: 20.w),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 15.sp : 13.sp,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceEmptyItemsPlaceholder extends StatelessWidget {
  const InvoiceEmptyItemsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 40.h),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32.r, color: ColorsManager.inputBorder),
          SizedBox(height: 8.h),
          Text(
            'invoices.no_items_yet'.tr(),
            style: TextStyle(fontSize: 13.sp, color: ColorsManager.defaultTextSecondary),
          ),
        ],
      ),
    ),
  );
}