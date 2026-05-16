/*
// lib/features/suppliers/presentation/widgets/supplier_clearing_dialog.dart
//
// Self-contained clearing dialog.
// No separate CustomerEntity needed — both sides live on SupplierEntity.

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Future<bool> showSupplierClearingDialog({
  required BuildContext   context,
  required SupplierEntity supplier,
}) async {
  final cubit  = context.read<SuppliersCubit>();
  final result = await showDialog<bool>(
    context:            context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: SupplierClearingDialog(supplier: supplier),
    ),
  );
  return result ?? false;
}

class SupplierClearingDialog extends StatefulWidget {
  final SupplierEntity supplier;
  const SupplierClearingDialog({super.key, required this.supplier});

  @override
  State<SupplierClearingDialog> createState() => _SupplierClearingDialogState();
}

class _SupplierClearingDialogState extends State<SupplierClearingDialog> {
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();
  String? _error;

  double get _balance    => widget.supplier.balance;
  double get _serviceDebt => widget.supplier.serviceDebt;
  double get _maxAmount   => widget.supplier.maxClearable;

  @override
  void initState() {
    super.initState();
    _amountCtrl.text = _maxAmount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'أدخل مبلغاً صحيحاً أكبر من صفر';
    if (amt > _balance)     return 'المبلغ يتجاوز مديونيتنا له (${_balance.toStringAsFixed(0)})';
    if (amt > _serviceDebt) return 'المبلغ يتجاوز مديونيته علينا (${_serviceDebt.toStringAsFixed(0)})';
    return null;
  }

  void _submit(BuildContext ctx) {
    final err = _validate(_amountCtrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() => _error = null);
    ctx.read<SuppliersCubit>().executeSupplierClearing(
      supplierId: widget.supplier.id,
      amount:     double.parse(_amountCtrl.text),
      notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cur   = 'dashboard.currency'.tr();

    return BlocConsumer<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) => p.clearingStatus != c.clearingStatus,
      listener: (ctx, state) {
        if (state.clearingStatus == ClearingStatus.success) {
          final res = state.lastClearingResult;
          ctx.showSuccess(
            'تمت المقاصة: ${res?.clearedAmount.toStringAsFixed(0) ?? ''} $cur',
          );
          Navigator.of(ctx).pop(true);
        } else if (state.clearingStatus == ClearingStatus.failure) {
          ctx.showError(state.errorMessage ?? 'حدث خطأ في المقاصة');
        }
      },
      builder: (ctx, state) {
        final isLoading = state.isClearingInProgress;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize:      MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ──────────────────────────────────────────
                  Row(
                    children: [
                      Container(
                        width: 40.r, height: 40.r,
                        decoration: BoxDecoration(
                          color:        ColorsManager.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.swap_horiz_rounded,
                            size: 22.r, color: ColorsManager.primaryColor),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('إجراء مقاصة',
                                style: TextStyle(
                                    fontSize:   17.sp,
                                    fontWeight: FontWeight.w700,
                                    color:      theme.textTheme.titleSmall?.color)),
                            Text('تسوية الحسابات المتبادلة مع ${widget.supplier.name}',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color:    ColorsManager.defaultTextSecondary)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon:      Icon(Icons.close, size: 18.r),
                        onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // ── Two-sided balance summary ─────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceSide(
                          icon:    Icons.arrow_downward_rounded,
                          label:   'مديونية له\n(نحن ندفع لهم)',
                          amount:  _balance,
                          color:   ColorsManager.errorText,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Column(
                          children: [
                            Icon(Icons.compare_arrows_rounded,
                                size: 28.r, color: ColorsManager.primaryColor),
                            SizedBox(height: 4.h),
                            Text('مقاصة',
                                style: TextStyle(
                                    fontSize:   10.sp,
                                    color:      ColorsManager.primaryColor,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _BalanceSide(
                          icon:    Icons.arrow_upward_rounded,
                          label:   'مديونية عليه\n(يدفعون لنا)',
                          amount:  _serviceDebt,
                          color:   ColorsManager.successText,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Max clearable info banner ──────────────────────
                  AppCard(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    color:   ColorsManager.primaryColor.withOpacity(0.06),
                    variant: AppCardVariant.flat,
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 14.r, color: ColorsManager.primaryColor),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'الحد الأقصى للمقاصة: $cur ${_maxAmount.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize:   12.sp,
                                fontWeight: FontWeight.w600,
                                color:      ColorsManager.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Amount field ──────────────────────────────────
                  Text('مبلغ المقاصة',
                      style: TextStyle(
                          fontSize:   13.sp,
                          fontWeight: FontWeight.w600,
                          color:      theme.textTheme.titleSmall?.color)),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller:   _amountCtrl,
                    enabled:      !isLoading,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                        fontSize:   22.sp,
                        fontWeight: FontWeight.w700,
                        color:      ColorsManager.primaryColor),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      prefixText:  '$cur ',
                      prefixStyle: TextStyle(
                          fontSize:   14.sp,
                          fontWeight: FontWeight.w600,
                          color:      ColorsManager.defaultTextSecondary),
                      border:         OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      enabledBorder:  OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide:   BorderSide(
                              color: _error != null
                                  ? ColorsManager.errorFill
                                  : theme.dividerColor)),
                      focusedBorder:  OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide:   const BorderSide(
                              color: ColorsManager.primaryColor, width: 1.5)),
                      errorText: _error,
                    ),
                    onChanged: (v) => setState(() => _error = _validate(v)),
                  ),

                  // ── Quick-fill chips ───────────────────────────────
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      _QuickChip(
                        label:   'الحد الأقصى',
                        enabled: !isLoading,
                        onTap:   () {
                          _amountCtrl.text = _maxAmount.toStringAsFixed(0);
                          setState(() => _error = null);
                        },
                      ),
                      SizedBox(width: 8.w),
                      _QuickChip(
                        label:   'النصف',
                        enabled: !isLoading,
                        onTap:   () {
                          _amountCtrl.text = (_maxAmount / 2).toStringAsFixed(0);
                          setState(() => _error = null);
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: 14.h),

                  // ── Notes field ───────────────────────────────────
                  Text('ملاحظات (اختياري)',
                      style: TextStyle(
                          fontSize:   13.sp,
                          fontWeight: FontWeight.w600,
                          color:      theme.textTheme.titleSmall?.color)),
                  SizedBox(height: 6.h),
                  TextFormField(
                    controller: _notesCtrl,
                    enabled:    !isLoading,
                    maxLines:   2,
                    decoration: InputDecoration(
                      hintText:  'مثال: تسوية حساب مقابل فاتورة رقم ...',
                      hintStyle: TextStyle(
                          fontSize: 12.sp,
                          color:    ColorsManager.defaultTextSecondary),
                      border:        OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide:   BorderSide(color: theme.dividerColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.r),
                          borderSide:   const BorderSide(
                              color: ColorsManager.primaryColor, width: 1.5)),
                    ),
                  ),

                  SizedBox(height: 22.h),

                  // ── Confirm button ────────────────────────────────
                  SizedBox(
                    width:  double.infinity,
                    height: 48.h,
                    child: ElevatedButton.icon(
                      onPressed: isLoading ? null : () => _submit(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      icon: isLoading
                          ? SizedBox(
                          width: 18.r, height: 18.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.swap_horiz_rounded, size: 20.r),
                      label: Text(
                        isLoading ? 'جاري التنفيذ...' : 'تأكيد المقاصة',
                        style: TextStyle(
                            fontSize: 15.sp, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Balance side card ─────────────────────────────────────────

class _BalanceSide extends StatelessWidget {
  final IconData icon;
  final String   label;
  final double   amount;
  final Color    color;

  const _BalanceSide({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();
    return AppCard(
      padding: EdgeInsets.all(12.w),
      color:   color.withOpacity(0.07),
      variant: AppCardVariant.outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.r, color: color),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(label,
                    style: TextStyle(
                        fontSize: 10.sp,
                        color:    ColorsManager.defaultTextSecondary,
                        height:   1.4)),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            '$cur ${amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize:   16.sp,
                fontWeight: FontWeight.w800,
                color:      color),
          ),
        ],
      ),
    );
  }
}

// ── Quick-fill chip ───────────────────────────────────────────

class _QuickChip extends StatelessWidget {
  final String       label;
  final VoidCallback onTap;
  final bool         enabled;

  const _QuickChip({
    required this.label,
    required this.onTap,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color:        ColorsManager.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6.r),
        border:       Border.all(
            color: ColorsManager.primaryColor.withOpacity(0.25)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize:   11.sp,
              fontWeight: FontWeight.w600,
              color:      ColorsManager.primaryColor)),
    ),
  );
}*/
