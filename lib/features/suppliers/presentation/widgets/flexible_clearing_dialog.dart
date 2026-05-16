// lib/features/suppliers/presentation/widgets/flexible_clearing_dialog.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ── Entry point ───────────────────────────────────────────────

Future<bool> showFlexibleClearingDialog({
  required BuildContext   context,
  required SupplierEntity supplier,
}) async {
  final cubit  = context.read<SuppliersCubit>();
  final result = await showDialog<bool>(
    context:            context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: FlexibleClearingDialog(supplier: supplier),
    ),
  );
  return result ?? false;
}

// ── Tab enum ──────────────────────────────────────────────────

enum _ClearingTab {
  offset('مقاصة بالتقاص', Icons.swap_horiz_rounded,        'offset'),
  cashTo('كاش → للمورد',  Icons.arrow_circle_down_outlined, 'cash_to_supplier'),
  cashFrom('كاش ← منه',  Icons.arrow_circle_up_outlined,   'cash_from_supplier'),
  mixed('مختلط',          Icons.compare_arrows_rounded,     'mixed');

  final String label;
  final IconData icon;
  final String apiKey;
  const _ClearingTab(this.label, this.icon, this.apiKey);
}

// ── Main dialog ───────────────────────────────────────────────

class FlexibleClearingDialog extends StatefulWidget {
  final SupplierEntity supplier;
  const FlexibleClearingDialog({super.key, required this.supplier});

  @override
  State<FlexibleClearingDialog> createState() => _FlexibleClearingDialogState();
}

class _FlexibleClearingDialogState extends State<FlexibleClearingDialog> {
  _ClearingTab _tab        = _ClearingTab.offset;
  String       _cashMethod = 'safe';

  final _offsetCtrl = TextEditingController();
  final _cashCtrl   = TextEditingController();
  final _notesCtrl  = TextEditingController();

  String? _offsetError;
  String? _cashError;

  SupplierEntity get _s  => widget.supplier;
  double get _balance    => _s.balance;
  double get _debt       => _s.serviceDebt;
  double get _maxOffset  => _s.maxClearable;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  void _prefill() {
    _offsetCtrl.text = _maxOffset.toStringAsFixed(0);
    _cashCtrl.text   = '';
  }

  void _onTabChange(_ClearingTab t) {
    setState(() {
      _tab         = t;
      _offsetError = null;
      _cashError   = null;
      _prefill();
    });
  }

  // ── Validation ────────────────────────────────────────────

  String? _validateOffset(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0)    return 'أدخل مبلغاً صحيحاً';
    if (amt > _balance)             return 'يتجاوز مديونيتنا له (${_balance.toStringAsFixed(0)})';
    if (amt > _debt)                return 'يتجاوز مديونيته لنا (${_debt.toStringAsFixed(0)})';
    return null;
  }

  String? _validateCashTo(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'أدخل مبلغاً صحيحاً';
    if (amt > _balance)          return 'يتجاوز مديونيتنا له (${_balance.toStringAsFixed(0)})';
    return null;
  }

  String? _validateCashFrom(String? v) {
    final amt = double.tryParse(v ?? '');
    if (amt == null || amt <= 0) return 'أدخل مبلغاً صحيحاً';
    if (amt > _debt)             return 'يتجاوز مديونيته لنا (${_debt.toStringAsFixed(0)})';
    return null;
  }

  String? _validateMixedOffset(String? v) {
    final off  = double.tryParse(v ?? '') ?? 0;
    final cash = double.tryParse(_cashCtrl.text) ?? 0;
    if (off < 0)              return 'لا يمكن أن يكون سالباً';
    if (off > _maxOffset)     return 'الحد الأقصى للتقاص: ${_maxOffset.toStringAsFixed(0)}';
    if (off + cash <= 0)      return 'يجب أن يكون هناك مبلغ';
    return null;
  }

  String? _validateMixedCash(String? v) {
    final cash = double.tryParse(v ?? '') ?? 0;
    final off  = double.tryParse(_offsetCtrl.text) ?? 0;
    if (cash < 0)             return 'لا يمكن أن يكون سالباً';
    if (cash > (_balance - off).clamp(0, double.infinity))
      return 'يتجاوز ما تبقى من مديونيتنا';
    if (off + cash <= 0)      return 'يجب أن يكون هناك مبلغ';
    return null;
  }

  bool get _canSubmit {
    switch (_tab) {
      case _ClearingTab.offset:
        return _validateOffset(_offsetCtrl.text) == null;
      case _ClearingTab.cashTo:
        return _validateCashTo(_cashCtrl.text) == null;
      case _ClearingTab.cashFrom:
        return _validateCashFrom(_cashCtrl.text) == null;
      case _ClearingTab.mixed:
        return _validateMixedOffset(_offsetCtrl.text) == null &&
            _validateMixedCash(_cashCtrl.text) == null;
    }
  }

  // ── Preview ───────────────────────────────────────────────

  ({double newBalance, double newDebt, double totalCleared}) get _preview {
    double nb = _balance, nd = _debt, total = 0;
    final off  = double.tryParse(_offsetCtrl.text) ?? 0;
    final cash = double.tryParse(_cashCtrl.text)   ?? 0;

    switch (_tab) {
      case _ClearingTab.offset:
        final a = _validateOffset(_offsetCtrl.text) == null ? off : 0.0;
        nb -= a; nd -= a; total = a;
      case _ClearingTab.cashTo:
        final a = _validateCashTo(_cashCtrl.text) == null ? cash : 0.0;
        nb -= a; total = a;
      case _ClearingTab.cashFrom:
        final a = _validateCashFrom(_cashCtrl.text) == null ? cash : 0.0;
        nd -= a; total = a;
      case _ClearingTab.mixed:
        final o = _validateMixedOffset(_offsetCtrl.text) == null ? off  : 0.0;
        final c = _validateMixedCash(_cashCtrl.text)     == null ? cash : 0.0;
        nb -= (o + c); nd -= o; total = o + c;
    }
    return (newBalance: nb.clamp(0, double.infinity),
    newDebt:    nd.clamp(0, double.infinity),
    totalCleared: total);
  }

  // ── Submit ────────────────────────────────────────────────

  void _submit(BuildContext ctx) {
    String? offErr, cashErr;
    switch (_tab) {
      case _ClearingTab.offset:
        offErr = _validateOffset(_offsetCtrl.text);
      case _ClearingTab.cashTo:
        cashErr = _validateCashTo(_cashCtrl.text);
      case _ClearingTab.cashFrom:
        cashErr = _validateCashFrom(_cashCtrl.text);
      case _ClearingTab.mixed:
        offErr  = _validateMixedOffset(_offsetCtrl.text);
        cashErr = _validateMixedCash(_cashCtrl.text);
    }
    setState(() { _offsetError = offErr; _cashError = cashErr; });
    if (offErr != null || cashErr != null) return;

    ctx.read<SuppliersCubit>().executeFlexibleClearing(
      supplierId:   _s.id,
      clearingType: _tab.apiKey,
      offsetAmount: double.tryParse(_offsetCtrl.text) ?? 0,
      cashAmount:   double.tryParse(_cashCtrl.text)   ?? 0,
      cashMethod:   _cashMethod,
      notes:        _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );
  }

  @override
  void dispose() {
    _offsetCtrl.dispose();
    _cashCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
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
          ctx.showSuccess('تمت التسوية: ${res?.clearedAmount.toStringAsFixed(0) ?? ''} $cur');
          Navigator.of(ctx).pop(true);
        } else if (state.clearingStatus == ClearingStatus.failure) {
          ctx.showError(state.errorMessage ?? 'حدث خطأ');
        }
      },
      builder: (ctx, state) {
        final isLoading = state.isClearingInProgress;
        final prev      = _preview;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Header ────────────────────────────────
                  Row(children: [
                    Container(
                      width: 40.r, height: 40.r,
                      decoration: BoxDecoration(
                        color:        ColorsManager.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.compare_arrows_rounded,
                          size: 22.r, color: ColorsManager.primaryColor),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('تسوية الحساب',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700,
                                color: theme.textTheme.titleSmall?.color)),
                        Text(_s.name,
                            style: TextStyle(fontSize: 11.sp,
                                color: ColorsManager.defaultTextSecondary)),
                      ]),
                    ),
                    IconButton(
                      icon:      Icon(Icons.close, size: 18.r),
                      onPressed: isLoading ? null : () => Navigator.of(context).pop(false),
                    ),
                  ]),

                  SizedBox(height: 16.h),

                  // ── Balance summary ───────────────────────
                  Row(children: [
                    Expanded(child: _BalancePill(
                      label:  'مديونيتنا له',
                      amount: _balance,
                      cur:    cur,
                      color:  ColorsManager.errorText,
                    )),
                    SizedBox(width: 8.w),
                    Expanded(child: _BalancePill(
                      label:  'مديونيته لنا',
                      amount: _debt,
                      cur:    cur,
                      color:  ColorsManager.successText,
                    )),
                  ]),

                  SizedBox(height: 14.h),

                  // ── Tab selector ──────────────────────────
                  _TabSelector(
                    current:  _tab,
                    onSelect: _onTabChange,
                    disabled: isLoading,
                  ),

                  SizedBox(height: 14.h),

                  // ── Fields per tab ────────────────────────
                  _TabFields(
                    tab:         _tab,
                    offsetCtrl:  _offsetCtrl,
                    cashCtrl:    _cashCtrl,
                    offsetError: _offsetError,
                    cashError:   _cashError,
                    maxOffset:   _maxOffset,
                    balance:     _balance,
                    debt:        _debt,
                    cur:         cur,
                    enabled:     !isLoading,
                    onOffsetChanged: (v) => setState(() {
                      _offsetError = _tab == _ClearingTab.offset
                          ? _validateOffset(v)
                          : _validateMixedOffset(v);
                    }),
                    onCashChanged: (v) => setState(() {
                      _cashError = _tab == _ClearingTab.cashTo
                          ? _validateCashTo(v)
                          : _tab == _ClearingTab.cashFrom
                          ? _validateCashFrom(v)
                          : _validateMixedCash(v);
                    }),
                  ),

                  // ── Cash method (shown when cash is involved) ─
                  if (_tab != _ClearingTab.offset) ...[
                    SizedBox(height: 12.h),
                    Text('طريقة الدفع',
                        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleSmall?.color)),
                    SizedBox(height: 6.h),
                    Row(children: [
                      Expanded(child: _MethodBtn(
                        label:      'كاش',
                        icon:       Icons.account_balance_wallet_outlined,
                        isSelected: _cashMethod == 'safe',
                        onTap:      () => setState(() => _cashMethod = 'safe'),
                      )),
                      SizedBox(width: 8.w),
                      Expanded(child: _MethodBtn(
                        label:      'بنك',
                        icon:       Icons.account_balance_outlined,
                        isSelected: _cashMethod == 'bank',
                        onTap:      () => setState(() => _cashMethod = 'bank'),
                      )),
                    ]),
                  ],

                  SizedBox(height: 12.h),

                  // ── Notes ─────────────────────────────────
                  TextFormField(
                    controller: _notesCtrl,
                    enabled:    !isLoading,
                    maxLines:   2,
                    style:      TextStyle(fontSize: 12.sp),
                    decoration: InputDecoration(
                      hintText:  'ملاحظات (اختياري)',
                      hintStyle: TextStyle(fontSize: 12.sp,
                          color: ColorsManager.defaultTextSecondary),
                      isDense: true,
                      border:        OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: BorderSide(color: theme.dividerColor)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.r),
                          borderSide: const BorderSide(
                              color: ColorsManager.primaryColor, width: 1.5)),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 8.h),
                    ),
                  ),

                  SizedBox(height: 14.h),

                  // ── Preview card ──────────────────────────
                  _PreviewCard(
                    totalCleared: prev.totalCleared,
                    newBalance:   prev.newBalance,
                    newDebt:      prev.newDebt,
                    cur:          cur,
                  ),

                  SizedBox(height: 16.h),

                  // ── Confirm button ────────────────────────
                  SizedBox(
                    width:  double.infinity,
                    height: 46.h,
                    child: ElevatedButton.icon(
                      onPressed: (isLoading || !_canSubmit)
                          ? null
                          : () => _submit(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorsManager.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                        ColorsManager.primaryColor.withOpacity(0.4),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.r)),
                      ),
                      icon: isLoading
                          ? SizedBox(width: 18.r, height: 18.r,
                          child: const CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                          : Icon(Icons.check_circle_outline, size: 18.r),
                      label: Text(
                        isLoading ? 'جاري التنفيذ...' : 'تأكيد التسوية',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w700),
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

// ── Tab selector ─────────────────────────────────────────────

class _TabSelector extends StatelessWidget {
  final _ClearingTab     current;
  final void Function(_ClearingTab) onSelect;
  final bool disabled;

  const _TabSelector({
    required this.current,
    required this.onSelect,
    required this.disabled,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing:    8.w,
      runSpacing: 6.h,
      children: _ClearingTab.values.map((t) {
        final isSelected = t == current;
        return GestureDetector(
          onTap: disabled ? null : () => onSelect(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? ColorsManager.primaryColor
                  : ColorsManager.primaryColor.withOpacity(0.07),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: isSelected
                    ? ColorsManager.primaryColor
                    : ColorsManager.primaryColor.withOpacity(0.2),
              ),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t.icon,
                  size: 14.r,
                  color: isSelected
                      ? Colors.white
                      : ColorsManager.primaryColor),
              SizedBox(width: 4.w),
              Text(t.label,
                  style: TextStyle(
                      fontSize:   11.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : ColorsManager.primaryColor)),
            ]),
          ),
        );
      }).toList(),
    );
  }
}

// ── Fields per tab ────────────────────────────────────────────

class _TabFields extends StatelessWidget {
  final _ClearingTab tab;
  final TextEditingController offsetCtrl;
  final TextEditingController cashCtrl;
  final String? offsetError;
  final String? cashError;
  final double maxOffset;
  final double balance;
  final double debt;
  final String cur;
  final bool   enabled;
  final void Function(String) onOffsetChanged;
  final void Function(String) onCashChanged;

  const _TabFields({
    required this.tab,
    required this.offsetCtrl,
    required this.cashCtrl,
    required this.offsetError,
    required this.cashError,
    required this.maxOffset,
    required this.balance,
    required this.debt,
    required this.cur,
    required this.enabled,
    required this.onOffsetChanged,
    required this.onCashChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget amountField({
      required TextEditingController ctrl,
      required String label,
      required String? error,
      required void Function(String) onChange,
      required double maxAmt,
      required VoidCallback onMax,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleSmall?.color)),
              GestureDetector(
                onTap: enabled ? onMax : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color:        ColorsManager.primaryColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text('الحد الأقصى: $cur ${maxAmt.toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 10.sp,
                          color: ColorsManager.primaryColor,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          TextFormField(
            controller:   ctrl,
            enabled:      enabled,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style:        TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700,
                color: ColorsManager.primaryColor),
            textAlign: TextAlign.center,
            onChanged:  onChange,
            decoration: InputDecoration(
              prefixText:  '$cur ',
              prefixStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500,
                  color: ColorsManager.defaultTextSecondary),
              errorText: error,
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide(
                      color: error != null ? ColorsManager.errorText : theme.dividerColor)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: const BorderSide(
                      color: ColorsManager.primaryColor, width: 1.5)),
            ),
          ),
        ],
      );
    }

    switch (tab) {
      case _ClearingTab.offset:
        return amountField(
          ctrl:      offsetCtrl,
          label:     'مبلغ التقاص',
          error:     offsetError,
          onChange:  onOffsetChanged,
          maxAmt:    maxOffset,
          onMax:     () {
            offsetCtrl.text = maxOffset.toStringAsFixed(0);
            onOffsetChanged(offsetCtrl.text);
          },
        );

      case _ClearingTab.cashTo:
        return amountField(
          ctrl:      cashCtrl,
          label:     'المبلغ الذي ستدفعه للمورد',
          error:     cashError,
          onChange:  onCashChanged,
          maxAmt:    balance,
          onMax:     () {
            cashCtrl.text = balance.toStringAsFixed(0);
            onCashChanged(cashCtrl.text);
          },
        );

      case _ClearingTab.cashFrom:
        return amountField(
          ctrl:      cashCtrl,
          label:     'المبلغ الذي ستستلمه من المورد',
          error:     cashError,
          onChange:  onCashChanged,
          maxAmt:    debt,
          onMax:     () {
            cashCtrl.text = debt.toStringAsFixed(0);
            onCashChanged(cashCtrl.text);
          },
        );

      case _ClearingTab.mixed:
        return Column(children: [
          amountField(
            ctrl:      offsetCtrl,
            label:     'جزء التقاص (offset)',
            error:     offsetError,
            onChange:  onOffsetChanged,
            maxAmt:    maxOffset,
            onMax:     () {
              offsetCtrl.text = maxOffset.toStringAsFixed(0);
              onOffsetChanged(offsetCtrl.text);
            },
          ),
          SizedBox(height: 10.h),
          amountField(
            ctrl:      cashCtrl,
            label:     'جزء الكاش (ندفع للمورد)',
            error:     cashError,
            onChange:  onCashChanged,
            maxAmt:    (balance - (double.tryParse(offsetCtrl.text) ?? 0))
                .clamp(0, double.infinity),
            onMax:     () {
              final remaining = (balance - (double.tryParse(offsetCtrl.text) ?? 0))
                  .clamp(0.0, double.infinity);
              cashCtrl.text = remaining.toStringAsFixed(0);
              onCashChanged(cashCtrl.text);
            },
          ),
        ]);
    }
  }
}

// ── Preview card ──────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final double totalCleared;
  final double newBalance;
  final double newDebt;
  final String cur;

  const _PreviewCard({
    required this.totalCleared,
    required this.newBalance,
    required this.newDebt,
    required this.cur,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      color:   ColorsManager.primaryColor.withOpacity(0.05),
      variant: AppCardVariant.flat,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.preview_outlined, size: 13.r, color: ColorsManager.primaryColor),
            SizedBox(width: 6.w),
            Text('معاينة النتيجة',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600,
                    color: ColorsManager.primaryColor)),
          ]),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _PreviewItem(
                label:  'إجمالي التسوية',
                value:  '$cur ${totalCleared.toStringAsFixed(0)}',
                color:  ColorsManager.primaryColor,
              ),
              _PreviewItem(
                label: 'رصيده سيصبح',
                value: '$cur ${newBalance.toStringAsFixed(0)}',
                color: ColorsManager.errorText,
              ),
              _PreviewItem(
                label: 'دينه سيصبح',
                value: '$cur ${newDebt.toStringAsFixed(0)}',
                color: ColorsManager.successText,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewItem extends StatelessWidget {
  final String label;
  final String value;
  final Color  color;

  const _PreviewItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label,
          style: TextStyle(fontSize: 9.sp,
              color: ColorsManager.defaultTextSecondary)),
      SizedBox(height: 2.h),
      Text(value,
          style: TextStyle(fontSize: 12.sp,
              fontWeight: FontWeight.w700, color: color)),
    ],
  );
}

// ── Balance pill ──────────────────────────────────────────────

class _BalancePill extends StatelessWidget {
  final String label;
  final double amount;
  final String cur;
  final Color  color;

  const _BalancePill({
    required this.label,
    required this.amount,
    required this.cur,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
    decoration: BoxDecoration(
      color:        color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(8.r),
      border:       Border.all(color: color.withOpacity(0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 9.sp, color: color,
                fontWeight: FontWeight.w600)),
        SizedBox(height: 2.h),
        Text('$cur ${amount.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 13.sp,
                fontWeight: FontWeight.w800, color: color)),
      ],
    ),
  );
}

// ── Method button ─────────────────────────────────────────────

class _MethodBtn extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isSelected;
  final VoidCallback onTap;

  const _MethodBtn({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: isSelected
            ? ColorsManager.primaryColor.withOpacity(0.09)
            : Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected
              ? ColorsManager.primaryColor
              : Theme.of(context).dividerColor,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15.r,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary),
          SizedBox(width: 5.w),
          Text(label,
              style: TextStyle(
                  fontSize:   12.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected
                      ? ColorsManager.primaryColor
                      : ColorsManager.defaultTextSecondary)),
        ],
      ),
    ),
  );
}