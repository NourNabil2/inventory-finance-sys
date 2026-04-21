// lib/features/suppliers/presentation/widgets/supplier_record_payment_dialog.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/app_dialog_shell.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_invoice_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SupplierRecordPaymentDialog extends StatefulWidget {
  final SupplierInvoiceEntity invoice;
  final String                supplierId;

  const SupplierRecordPaymentDialog({
    super.key,
    required this.invoice,
    required this.supplierId,
  });

  @override
  State<SupplierRecordPaymentDialog> createState() =>
      _SupplierRecordPaymentDialogState();
}

class _SupplierRecordPaymentDialogState
    extends State<SupplierRecordPaymentDialog> {
  final _ctrl   = TextEditingController();
  String _method = 'safe';
  bool   _loading = false;
  String? _error;

  double get _remaining => widget.invoice.remaining;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _validate(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'أدخل مبلغاً صحيحاً';
    if (amt > _remaining) {
      return 'المبلغ أكبر من المتبقي (${_remaining.toStringAsFixed(0)})';
    }
    return null;
  }

  Future<void> _submit() async {
    final err = _validate(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _loading = true;
      _error   = null;
    });

    final cubit = context.read<SuppliersCubit>();
    await cubit.recordPayment(
      invoiceId:  widget.invoice.id,
      supplierId: widget.supplierId,
      amount:     double.parse(_ctrl.text),
      method:     _method,
    );

    if (!mounted) return;
    final state = cubit.state;
    // 🚨 نفس الحماية، لو مفيش إيرور نقفل الديالوج 🚨
    if (state.hasError) {
      setState(() {
        _loading = false;
        _error   = state.errorMessage;
      });
    } else {
      context.showSuccess('تم تسجيل الدفعة بنجاح');
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = 'dashboard.currency'.tr();

    return AppDialogShell(
      title:     'تسجيل دفعة للمورد',
      saveLabel: 'تأكيد الدفع',
      isLoading: _loading,
      onSave:    _submit,
      onClose:   _loading ? null : () => Navigator.of(context).pop(),
      maxWidth:  440,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Remaining banner ──
          AppCard(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            color:   ColorsManager.warningSurface,
            variant: AppCardVariant.flat,
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16.r, color: ColorsManager.warningText),
                SizedBox(width: 8.w),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize:   12.sp,
                          color:      ColorsManager.warningText,
                          fontWeight: FontWeight.w500),
                      children: [
                        const TextSpan(text: 'المبلغ المتبقي: '),
                        TextSpan(
                          text: '$cur ${_remaining.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // ── Amount field ──
          TextFormField(
            controller:  _ctrl,
            autofocus:   true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText:  'المبلغ',
              suffixText: cur,
              border:     OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r)),
              errorText: _error,
            ),
            onChanged: (v) => setState(() => _error = _validate(v)),
          ),
          SizedBox(height: 14.h),

          // ── Method selector ──
          Text('طريقة الدفع',
              style: TextStyle(
                  fontSize:   13.sp,
                  fontWeight: FontWeight.w600,
                  color:      Theme.of(context).textTheme.titleSmall?.color)),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: _MethodOption(
                  label:      'كاش',
                  icon:       Icons.account_balance_wallet_outlined,
                  isSelected: _method == 'safe',
                  onTap:      () => setState(() => _method = 'safe'),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _MethodOption(
                  label:      'بنك',
                  icon:       Icons.account_balance_outlined,
                  isSelected: _method == 'bank',
                  onTap:      () => setState(() => _method = 'bank'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodOption extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isSelected;
  final VoidCallback onTap;

  const _MethodOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AppCard(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      color:   isSelected
          ? ColorsManager.primaryColor.withOpacity(0.08)
          : Theme.of(context).scaffoldBackgroundColor,
      variant: isSelected
          ? AppCardVariant.highlighted
          : AppCardVariant.outlined,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size:  16.r,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary),
          SizedBox(width: 6.w),
          Text(label,
              style: TextStyle(
                  fontSize:   13.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color:      isSelected
                      ? ColorsManager.primaryColor
                      : ColorsManager.defaultTextSecondary)),
        ],
      ),
    ),
  );
}