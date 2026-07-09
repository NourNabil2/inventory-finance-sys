// lib/features/finance/presentation/pages/finance_page.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/theme/text_theme.dart';
import 'package:bungee_manage_sys/core/utils/extension.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/app_card.dart';
import 'package:bungee_manage_sys/core/widgets/page_header.dart';
import 'package:bungee_manage_sys/features/finance/domain/entities/financial_transaction_entity.dart';
import 'package:bungee_manage_sys/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bungee_manage_sys/features/finance/presentation/widgets/export_report_dialog.dart';
import 'package:bungee_manage_sys/features/finance/presentation/widgets/transaction_form_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../customers/presentation/cubit/customers_cubit.dart';

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<FinanceCubit, FinanceState>(
      listener: (context, state) {
        if (state is FinanceError) {
          context.showError(state.message);
        }
      },
      builder: (context, state) {
        final isProcessing = state is FinanceLoading;
        return Column(
          children: [
            PageHeader(
              titleKey: 'finance.title',
              actionWidget: Padding(
                padding: EdgeInsetsDirectional.only(end: 12.w),
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : () {
                    showDialog(
                      context: context,
                      builder: (_) => BlocProvider.value(
                        value: context.read<FinanceCubit>(),
                        child: const ExportReportDialog(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorsManager.successText,
                    side: const BorderSide(color: ColorsManager.successText),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                  ),
                  icon: isProcessing
                      ? SizedBox(width: 16.r, height: 16.r, child: const CircularProgressIndicator(strokeWidth: 2, color: ColorsManager.successText))
                      : const Icon(Icons.file_download_outlined),
                  label: Text(
                    isProcessing ? 'common.loading'.tr() : 'finance.export_excel'.tr(),
                    style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              actionButton: PageHeaderAction(
                textKey: 'finance.add_transaction',
                icon: Icons.add,
                onPressed: () => _showTransactionDialog(context),
              ),
            ),
            Expanded(child: _buildContent(context, state)),
          ],
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, FinanceState state) {
    if (state is FinanceInitial || state is FinanceLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is FinanceError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.r, color: ColorsManager.errorFill),
            SizedBox(height: 16.h),
            Text('errors.loadFailed'.tr(), style: TextStyle(fontSize: 16.sp, color: ColorsManager.defaultTextSecondary)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.read<FinanceCubit>().loadSummary(),
              child: Text('common.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is FinanceLoaded) {
      return _FinanceContent(summary: state.summary);
    }

    return const SizedBox.shrink();
  }

  void _showTransactionDialog(BuildContext context) {
    final financeCubit = context.read<FinanceCubit>();

    showDialog(
      context: context,
      builder: (dialogContext) =>
          MultiBlocProvider(
            providers: [
              BlocProvider.value(value: financeCubit),
              BlocProvider(
                create: (_) =>
                di.sl<CustomersCubit>()
                  ..fetchCustomers(),
              ),
            ],
            child: const TransactionFormDialog(),
          ),
    );
  }
}

class _FinanceContent extends StatelessWidget {
  final FinancialSummaryEntity summary;
  const _FinanceContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BalanceCards(summary: summary),
          SizedBox(height: 16.h),
          _QuickStats(summary: summary),
          SizedBox(height: 24.h),
          _RecentTransactions(transactions: summary.recentTransactions),
        ],
      ),
    );
  }
}

class _BalanceCards extends StatelessWidget {
  final FinancialSummaryEntity summary;
  const _BalanceCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    final currency = 'dashboard.currency'.tr();

    return Row(
      children: [
        Expanded(
          child: _BalanceCard(
            title: 'finance.cash_balance'.tr(),
            amount: summary.cashBalance,
            icon: Icons.account_balance_wallet_outlined,
            color: ColorsManager.successFill,
            currency: currency,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _BalanceCard(
            title: 'finance.bank_balance'.tr(),
            amount: summary.bankBalance,
            icon: Icons.account_balance_outlined,
            color: ColorsManager.primaryColor,
            currency: currency,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _BalanceCard(
            title: 'finance.total_balance'.tr(),
            amount: summary.totalBalance,
            icon: Icons.calculate_outlined,
            color: ColorsManager.warningFill,
            currency: currency,
            isHighlighted: true,
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final String currency;
  final bool isHighlighted;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.currency,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: isHighlighted ? AppCardVariant.highlighted : AppCardVariant.outlined,
      color: isHighlighted ? color.withOpacity(0.05) : null,
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8.r)),
                child: Icon(icon, color: color, size: 24.r),
              ),
              const Spacer(),
              Icon(amount >= 0 ? Icons.trending_up : Icons.trending_down, color: amount >= 0 ? ColorsManager.successFill : ColorsManager.errorFill, size: 20.r),
            ],
          ),
          SizedBox(height: 16.h),
          Text(title, style: TextStyle(fontSize: 14.sp, color: ColorsManager.defaultTextSecondary)),
          SizedBox(height: 8.h),
          Text(
            // 🚨 استخدام الاكستنشن الجديد هنا 🚨
            amount.toMoney(currency),
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: amount >= 0 ? color : ColorsManager.errorFill),
          ),
        ],
      ),
    );
  }
}

class _RecentTransactions extends StatefulWidget {
  final List<FinancialTransactionEntity> transactions;
  const _RecentTransactions({required this.transactions});

  @override
  State<_RecentTransactions> createState() => _RecentTransactionsState();
}

class _RecentTransactionsState extends State<_RecentTransactions> {
  int _displayLimit = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasMore = widget.transactions.length > _displayLimit;
    final displayedTransactions = widget.transactions.take(_displayLimit).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 8.h),
          child: Text(
            'finance.recent_transactions'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 8.h),

        if (widget.transactions.isEmpty)
          AppCard(
            padding: EdgeInsets.all(32.r),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48.r, color: ColorsManager.defaultTextSecondary),
                  SizedBox(height: 16.h),
                  Text(
                    'finance.no_transactions'.tr(),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          )
        else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayedTransactions.length,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _TransactionTile(transaction: displayedTransactions[index]),
            ),
          ),

          if (hasMore) ...[
            SizedBox(height: 8.h),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _displayLimit += 5;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                ),
                child: Text(
                  'common.load_more'.tr(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: ColorsManager.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ]
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinancialTransactionEntity transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = 'dashboard.currency'.tr();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    final isIncome = transaction.isIncome;
    final amountColor = isIncome ? ColorsManager.successText : ColorsManager.errorText;
    final sign = isIncome ? '+' : '-';
    String subtitleText = '${transaction.methodDisplayName} • ${dateFormat.format(transaction.createdAt)}';

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                    color: amountColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10.r)
                ),
                child: Icon(
                    isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: amountColor,
                    size: 22.r
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.categoryDisplayName,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 4.h),
                    if (transaction.customerName != null && transaction.customerName!.isNotEmpty) ...[
                      Text(
                        'العميل: ${transaction.customerName}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: ColorsManager.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                    ],
                    Text(
                      subtitleText,
                      style: theme.textTheme.labelSmall?.copyWith(color: ColorsManager.defaultTextSecondary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '$sign${transaction.amount.toMoney(currency)}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: AppTextTheme.fontFamily,
                  color: amountColor,
                ),
              ),
            ],
          ),

          if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
            SizedBox(height: 14.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? const Color(0xFF161622)
                    : const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                      Icons.format_quote_rounded,
                      size: 16.r,
                      color: ColorsManager.defaultTextSecondary.withOpacity(0.6)
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      transaction.notes!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ColorsManager.defaultTextSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  final FinancialSummaryEntity summary;
  const _QuickStats({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            title: 'finance.stats_today'.tr(),
            income: summary.todayIncome,
            expense: summary.todayExpense,
            icon: Icons.today_outlined,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: _StatBox(
            title: 'finance.stats_week'.tr(),
            income: summary.weekIncome,
            expense: summary.weekExpense,
            icon: Icons.date_range_outlined,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final double income;
  final double expense;
  final IconData icon;

  const _StatBox({
    required this.title,
    required this.income,
    required this.expense,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final successStyle = isDark ? AppTextTheme.successTextDark : AppTextTheme.successTextLight;
    final errorStyle = isDark ? AppTextTheme.errorTextDark : AppTextTheme.errorTextLight;

    return AppCard(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18.r,
                color: theme.textTheme.bodySmall?.color,
              ),
              SizedBox(width: 8.w),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.income'.tr(),
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 12.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      // 🚨 استخدام الاكستنشن الجديد هنا 🚨
                      '+${income.toFormattedString()}',
                      style: successStyle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 30.h,
                color: theme.dividerColor,
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'finance.expense'.tr(),
                      style: theme.textTheme.labelSmall?.copyWith(fontSize: 12.sp),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      // 🚨 استخدام الاكستنشن الجديد هنا 🚨
                      '-${expense.toFormattedString()}',
                      style: errorStyle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}