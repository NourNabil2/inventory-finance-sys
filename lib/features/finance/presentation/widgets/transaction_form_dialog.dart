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
  DateTime?           _selectedDate;

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
        createdAt:   _selectedDate,
      );
    }

    if (mounted) {
      setState(() => _isSubmitting = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('en', 'GB'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).brightness == Brightness.dark
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
      setState(() => _selectedDate = picked);
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
                _buildSegmentedControl<TransactionType>(
                  value: _type,
                  items: const [TransactionType.income, TransactionType.expense],
                  labelBuilder: (t) => t == TransactionType.income ? 'finance.income'.tr() : 'finance.expense'.tr(),
                  iconBuilder: (t) => t == TransactionType.income ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  colorBuilder: (t) => t == TransactionType.income ? ColorsManager.successFill : ColorsManager.errorFill,
                  onChanged: (t) {
                    setState(() {
                      _type = t;
                      _category = t == TransactionType.income ? _incomeCategories.first : _expenseCategories.first;
                      _selectedCustomer = null;
                    });
                  },
                ),
                SizedBox(height: 20.h),

                // ── Amount & Method (Row) ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildAmountField(),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      flex: 2,
                      child: _buildMethodDropdown(),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // ── Category ─────────────────────────────────────────────────
                _buildCategorySelector(),
                SizedBox(height: 16.h),

                // ── Customer picker (wallet deposit only) ─────────────────────
                if (_needsCustomer) ...[
                  _buildCustomerSelector(),
                  SizedBox(height: 8.h),
                  if (_selectedCustomer != null)
                    _WalletBadge(customer: _selectedCustomer!),
                  SizedBox(height: 16.h),
                ],

                // ── Date & Notes ─────────────────────────────────────────────
                _buildDateSelector(),
                SizedBox(height: 16.h),
                _buildNotesField(),
                SizedBox(height: 28.h),

                // ── Submit ───────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 48.h,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorsManager.primaryColor,
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
                            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isWalletDeposit
                                ? 'إيداع في رصيد العميل'
                                : _type == TransactionType.income
                                    ? 'finance.record_income'.tr()
                                    : 'finance.record_expense'.tr(),
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700),
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

  Widget _buildSegmentedControl<T>({
    required T value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required IconData Function(T) iconBuilder,
    required Color Function(T) colorBuilder,
    required void Function(T) onChanged,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      height: 46.h,
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161622) : const Color(0xFFF1F3F6),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: items.map((item) {
          final isSelected = value == item;
          final color = colorBuilder(item);
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(item),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2C2C3E) : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: isSelected && isDark ? Border.all(color: Colors.white12, width: 1) : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      iconBuilder(item),
                      size: 16.r,
                      color: isSelected ? color : ColorsManager.defaultTextSecondary,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      labelBuilder(item),
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? color : ColorsManager.defaultTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMethodDropdown() {
    return DropdownButtonFormField<PaymentMethod>(
      value: _method,
      decoration: InputDecoration(
        labelText: 'الجهة',
        prefixIcon: Icon(
          _method == PaymentMethod.cash ? Icons.account_balance_wallet_outlined : Icons.account_balance_outlined,
          size: 20.r,
          color: ColorsManager.primaryColor,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      items: [
        DropdownMenuItem(value: PaymentMethod.cash, child: Text('finance.cash'.tr(), style: TextStyle(fontSize: 13.sp))),
        DropdownMenuItem(value: PaymentMethod.bank, child: Text('finance.bank'.tr(), style: TextStyle(fontSize: 13.sp))),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _method = v);
      },
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

  Widget _buildDateSelector() {
    final hasDate = _selectedDate != null;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      key: ValueKey(_selectedDate),
      initialValue: hasDate
          ? 'تاريخ مخصص: ${DateFormat('yyyy/MM/dd').format(_selectedDate!)}'
          : '',
      readOnly: true,
      onTap: _pickDate,
      style: TextStyle(
        fontSize: 14.sp,
        color: hasDate ? ColorsManager.primaryColor : ColorsManager.defaultText,
        fontWeight: hasDate ? FontWeight.w600 : FontWeight.normal,
      ),
      decoration: InputDecoration(
        labelText: 'تاريخ العملية',
        hintText: 'الآن (تلقائي)',
        hintStyle: TextStyle(
          color: isDark ? Colors.white30 : Colors.black38,
          fontSize: 13.sp,
        ),
        prefixIcon: Icon(
          Icons.edit_calendar_outlined,
          color: hasDate ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary.withOpacity(0.5),
        ),
        suffixIcon: hasDate
            ? IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _selectedDate = null),
                color: ColorsManager.primaryColor,
              )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r)),
        enabledBorder: hasDate
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.r),
                borderSide: BorderSide(color: ColorsManager.primaryColor, width: 1.5),
              )
            : null,
        filled: hasDate,
        fillColor: hasDate ? ColorsManager.primaryColor.withOpacity(0.06) : null,
      ),
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