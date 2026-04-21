// lib/features/dashboard/presentation/pages/dashboard_page.dart
import 'package:bungee_manage_sys/features/dashboard/presentation/widgets/recent_invoices_table.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/entities/dashboard_entity.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/widgets/debt_chart.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/widgets/revenue_chart.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/widgets/stats_grid.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DashboardCubit, DashboardState>(
      listener: _handleStateChanges,
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<DashboardCubit>().load(),
          child: _buildContent(context, state),
        );
      },
    );
  }

  void _handleStateChanges(BuildContext context, DashboardState state) {}

  Widget _buildContent(BuildContext context, DashboardState state) {
    return switch (state) {
      DashboardInitial() || DashboardLoading() =>
      const Center(child: CircularProgressIndicator()),

      DashboardError(:final message) => _ErrorView(
        message: message,
        onRetry: () => context.read<DashboardCubit>().load(),
      ),

      DashboardLoaded(:final data) => _DashboardContent(data: data),
    };
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateWidget(
      icon: Icons.cloud_off_rounded,
      title: 'errors.loadFailed'.tr(),
      subtitle: message,
      isFullPage: false,
      actionLabel: 'common.retry'.tr(),
      onActionPressed: onRetry,
    );
  }
}

class _DashboardContent extends StatelessWidget {
  final DashboardEntity data;

  const _DashboardContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(20.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header & Refresh Button ───────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'dashboard.title'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    DateFormat('EEEE, d MMMM yyyy', context.locale.languageCode).format(DateTime.now()),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () => context.read<DashboardCubit>().load(),
                icon: Icon(Icons.refresh_rounded, size: 18.r),
                label: Text(
                  'common.update'.tr(),
                  style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyMedium?.color,
                  side: BorderSide(color: theme.dividerColor),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 24.h),
          StatsGrid(data: data),
          SizedBox(height: 20.h),
          isDesktop ? _DesktopCharts(data: data) : _MobileCharts(data: data),
          SizedBox(height: 20.h),
          _RecentInvoicesSection(invoices: data.recentInvoices),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }
}

class _DesktopCharts extends StatelessWidget {
  final DashboardEntity data;
  const _DesktopCharts({required this.data});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: RevenueChart(monthlyRevenues: data.monthlyRevenues)),
          SizedBox(width: 16.w),
          Expanded(flex: 2, child: DebtChart(totalCollectedPercent: data.totalCollectedPercent, totalDebtPercent: data.totalDebtPercent)),
        ],
      ),
    );
  }
}

class _MobileCharts extends StatelessWidget {
  final DashboardEntity data;
  const _MobileCharts({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        RevenueChart(monthlyRevenues: data.monthlyRevenues),
        SizedBox(height: 16.h),
        DebtChart(totalCollectedPercent: data.totalCollectedPercent, totalDebtPercent: data.totalDebtPercent),
      ],
    );
  }
}

class _RecentInvoicesSection extends StatelessWidget {
  final List<RecentInvoiceEntity> invoices;
  const _RecentInvoicesSection({required this.invoices});

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.receipt_long_outlined,
        title: 'invoices.empty_title'.tr(),
        subtitle: 'invoices.empty_sub'.tr(),
        isFullPage: false,
      );
    }
    return RecentInvoicesTable(invoices: invoices);
  }
}