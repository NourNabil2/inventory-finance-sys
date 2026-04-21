// lib/features/finance/presentation/widgets/transaction_form_dialog.dart
//
// Finance → New Transaction dialog.
//
// Flow:
//   Income + customerDeposit  →  customer picker required
//                              →  calls FinanceCubit.depositToWallet()
//                              →  cash lands in safe/bank + customer wallet++
//
//   Income + rental (old)     →  normal createTransaction (no wallet link)
//   Expense                   →  normal createTransaction

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/app_dropdown.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bungee_manage_sys/features/finance/domain/entities/financial_transaction_entity.dart';
import 'package:bungee_manage_sys/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TransactionFormDialog extends StatefulWidget {
  const TransactionFormDialog({super.key});

  @override
  State<TransactionFormDialog> createState() => _TransactionFormDialogState();
}

class _TransactionFormDialogState extends State<TransactionFormDialog> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _notesCtrl  = TextEditingController();

  TransactionType     _type     = TransactionType.expense;
  PaymentMethod       _method   = PaymentMethod.cash;
  TransactionCategory _category = TransactionCategory.generalExpense;
  CustomerEntity?     _selectedCustomer;
  bool                _isSubmitting = false;

  // ── Computed helpers ───────────────────────────────────────────────────────

  /// Income categories available to the user
  List<TransactionCategory> get _incomeCategories => [
    TransactionCategory.customerDeposit, // إيداع رصيد عميل  ← first = default
    TransactionCategory.rental,          // إيراد تأجير عادي
  ];

  List<TransactionCategory> get _expenseCategories => [
    TransactionCategory.generalExpense,
    TransactionCategory.adminExpense,
    TransactionCategory.operationExpense,
    TransactionCategory.supplierPayment,
  ];

  List<TransactionCategory> get _categories =>
      _type == TransactionType.income ? _incomeCategories : _expenseCategories;

  /// Wallet-deposit mode: income + customerDeposit
  bool get _isWalletDeposit =>
      _type == TransactionType.income &&
          _category == TransactionCategory.customerDeposit;

  /// Whether a customer picker must be shown
  bool get _needsCustomer => _isWalletDeposit;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_needsCustomer && _selectedCustomer == null) {
      context.showError('برجاء اختيار العميل');
      return;
    }

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) return;

    setState(() => _isSubmitting = true);

    final financeCubit = context.read<FinanceCubit>();

    if (_isWalletDeposit) {
      // ── Wallet deposit path ─────────────────────────────────────────────
      // Cash goes to safe/bank AND customer wallet is credited.
      await financeCubit.depositToWallet(
        customerId: _selectedCustomer!.id,
        amount:     amount,
        method:     _method, // cash or bank — never wallet
        notes:      _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    } else {
      // ── Normal transaction path ─────────────────────────────────────────
      await financeCubit.createTransaction(
        amount:      amount,
        type:        _type,
        method:      _method,
        category:    _category,
        referenceId: null,
        notes:       _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Container(
        width: 520.w,
        padding: EdgeInsets.all(24.r),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      'finance.new_transaction'.tr(),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: ColorsManager.defaultText,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                SizedBox(height: 24.h),

                // ── Type selector ────────────────────────────────────────────
                _buildTypeSelector(),
                SizedBox(height: 16.h),

                // ── Amount ───────────────────────────────────────────────────
                _buildAmountField(),
                SizedBox(height: 16.h),

                // ── Method (safe / bank) — always shown ──────────────────────
                _buildMethodSelector(),
                SizedBox(height: 16.h),

                // ── Category ─────────────────────────────────────────────────
                _buildCategorySelector(),
                SizedBox(height: 16.h),

                // ── Customer picker (wallet deposit only) ─────────────────────
                if (_needsCustomer) ...[
                  _buildCustomerSelector(),
                  SizedBox(height: 8.h),
                  // Wallet balance hint
                  if (_selectedCustomer != null)
                    _WalletBadge(customer: _selectedCustomer!),
                  SizedBox(height: 16.h),
                ],

                // ── Notes ────────────────────────────────────────────────────
                _buildNotesField(),
                SizedBox(height: 24.h),

                // ── Submit ───────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _type == TransactionType.income
                          ? ColorsManager.successFill
                          : ColorsManager.errorFill,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                      width:  20.r,
                      height: 20.r,
                      child: const CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                        : Text(
                      _isWalletDeposit
                          ? 'إيداع في رصيد العميل'
                          : _type == TransactionType.income
                          ? 'finance.record_income'.tr()
                          : 'finance.record_expense'.tr(),
                      style: TextStyle(
                          fontSize: 16.sp, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Builders ───────────────────────────────────────────────────────────────

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'finance.transaction_type'.tr(),
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.defaultText),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _TypeButton(
                label: 'finance.income'.tr(),
                icon:  Icons.arrow_downward,
                color: ColorsManager.successFill,
                isSelected: _type == TransactionType.income,
                onTap: () => setState(() {
                  _type             = TransactionType.income;
                  _category         = _incomeCategories.first;
                  _selectedCustomer = null;
                }),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _TypeButton(
                label: 'finance.expense'.tr(),
                icon:  Icons.arrow_upward,
                color: ColorsManager.errorFill,
                isSelected: _type == TransactionType.expense,
                onTap: () => setState(() {
                  _type             = TransactionType.expense;
                  _category         = _expenseCategories.first;
                  _selectedCustomer = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmountField() => TextFormField(
    controller:   _amountCtrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText:   'finance.amount'.tr(),
      prefixIcon:  const Icon(Icons.attach_money),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
    ),
    validator: (v) {
      final a = double.tryParse(v ?? '');
      if (a == null || a <= 0) return 'finance.invalid_amount'.tr();
      return null;
    },
  );

  Widget _buildMethodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'finance.payment_method'.tr(),
          style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: ColorsManager.defaultText),
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _MethodButton(
                label:      'finance.cash'.tr(),
                icon:       Icons.account_balance_wallet_outlined,
                isSelected: _method == PaymentMethod.cash,
                onTap:      () => setState(() => _method = PaymentMethod.cash),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: _MethodButton(
                label:      'finance.bank'.tr(),
                icon:       Icons.account_balance_outlined,
                isSelected: _method == PaymentMethod.bank,
                onTap:      () => setState(() => _method = PaymentMethod.bank),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    // Guard: keep _category valid when type switches
    if (!_categories.contains(_category)) {
      _category = _categories.first;
    }

    return AppDropdown<TransactionCategory>(
      title: 'finance.category'.tr(),
      value: _category,
      items: _categories
          .map((c) => DropdownMenuItem(
        value: c,
        child: Text(_categoryLabel(c)),
      ))
          .toList(),
      onChanged: (v) {
        if (v != null) {
          setState(() {
            _category = v;
            if (!_needsCustomer) _selectedCustomer = null;
          });
        }
      },
    );
  }

  Widget _buildCustomerSelector() {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {
        if (state.status == CustomersStatus.loading ||
            state.status == CustomersStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }

        final customers = state.customers;

        return AppDropdown<CustomerEntity?>(
          title: 'العميل',
          value: _selectedCustomer,
          items: [
            const DropdownMenuItem(value: null, child: Text('— اختر عميل —')),
            ...customers.map(
                  (c) => DropdownMenuItem(
                value: c,
                child: Text(c.name),
              ),
            ),
          ],
          onChanged: (v) => setState(() => _selectedCustomer = v),
        );
      },
    );
  }

  Widget _buildNotesField() => TextFormField(
    controller: _notesCtrl,
    maxLines:   2,
    decoration: InputDecoration(
      labelText:  'finance.notes'.tr(),
      prefixIcon: const Icon(Icons.notes_outlined),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      hintText:   'finance.notes_hint'.tr(),
    ),
  );

  String _categoryLabel(TransactionCategory c) => switch (c) {
    TransactionCategory.customerDeposit  => 'إيداع رصيد عميل',
    TransactionCategory.rental           => 'finance.category_rental'.tr(),
    TransactionCategory.adminExpense     => 'finance.category_admin'.tr(),
    TransactionCategory.operationExpense => 'finance.category_operation'.tr(),
    TransactionCategory.generalExpense   => 'finance.category_general'.tr(),
    TransactionCategory.supplierPayment  => 'finance.category_supplier'.tr(),
  };
}

// ── Wallet balance badge ───────────────────────────────────────────────────────

class _WalletBadge extends StatelessWidget {
  final CustomerEntity customer;
  const _WalletBadge({required this.customer});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      color:   ColorsManager.primaryColor.withOpacity(0.06),
      variant: AppCardVariant.highlighted,
      child: Row(
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 16.r, color: ColorsManager.primaryColor),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'رصيد ${customer.name} الحالي',
              style: TextStyle(
                  fontSize: 12.sp, color: ColorsManager.defaultTextSecondary),
            ),
          ),
          Text(
            '${customer.walletBalance.toStringAsFixed(0)} ${'dashboard.currency'.tr()}',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: ColorsManager.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

// ── _TypeButton ────────────────────────────────────────────────────────────────

class _TypeButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final Color    color;
  final bool     isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withOpacity(0.1)
            : ColorsManager.backgroundSurface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected ? color : ColorsManager.inputBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon,
              color: isSelected ? color : ColorsManager.defaultTextSecondary),
          SizedBox(height: 8.h),
          Text(
            label,
            style: TextStyle(
              fontSize:   14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color:      isSelected ? color : ColorsManager.defaultTextSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}

// ── _MethodButton ──────────────────────────────────────────────────────────────

class _MethodButton extends StatelessWidget {
  final String   label;
  final IconData icon;
  final bool     isSelected;
  final VoidCallback onTap;

  const _MethodButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: isSelected
            ? ColorsManager.primaryColor.withOpacity(0.1)
            : ColorsManager.backgroundSurface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected
              ? ColorsManager.primaryColor
              : ColorsManager.inputBorder,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              size: 18.r,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize:   14.sp,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : ColorsManager.defaultTextSecondary,
            ),
          ),
        ],
      ),
    ),
  );
}