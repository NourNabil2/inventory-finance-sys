// lib/features/dashboard/presentation/pages/dashboard_shell.dart

import 'package:bungee_manage_sys/core/utils/assets.dart';
import 'package:bungee_manage_sys/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:bungee_manage_sys/features/alerts/presentation/pages/alerts_page.dart';
import 'package:bungee_manage_sys/features/all_invoices/pagination/presentation/cubit/all_invoices_cubit.dart';
import 'package:bungee_manage_sys/features/all_invoices/pagination/presentation/pages/all_invoices_page.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:bungee_manage_sys/features/customers/presentation/pages/customers_page.dart';
import 'package:bungee_manage_sys/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bungee_manage_sys/features/finance/presentation/pages/finance_page.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/pages/suppliers_page.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/di/injection_container.dart' as di;
import 'package:bungee_manage_sys/core/routes/routes.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/confirmation_dialog.dart';
import 'package:bungee_manage_sys/core/widgets/responsive_layout.dart';
import 'package:bungee_manage_sys/features/auth/domain/repositories/auth_repository.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/pages/inventory_page.dart';

import '../../../../core/widgets/custom_lottie_icon.dart';

// ─── Nav Item Model ───────────────────────────────────────────────────────────

class NavItem {
  final IconData icon;
  final String labelKey;
  final int index;

  const NavItem({
    required this.icon,
    required this.labelKey,
    required this.index,
  });
}

const List<NavItem> kNavItems = [
  NavItem(icon: Icons.dashboard_outlined,              labelKey: 'dashboard.nav_home',          index: 0),
  NavItem(icon: Icons.videocam_outlined,               labelKey: 'dashboard.nav_inventory',     index: 1),
  NavItem(icon: Icons.people_outline,                  labelKey: 'dashboard.nav_customers',     index: 2),
  NavItem(icon: Icons.all_inbox,                       labelKey: 'dashboard.nav_all_invoices',  index: 3),
  NavItem(icon: Icons.account_balance_wallet_outlined, labelKey: 'dashboard.nav_finance',       index: 4),
  NavItem(icon: Icons.local_shipping_outlined,         labelKey: 'dashboard.nav_suppliers',     index: 5),
  NavItem(icon: Icons.notifications_none_outlined,     labelKey: 'dashboard.nav_alert',         index: 6),

];

// ─── Shell ────────────────────────────────────────────────────────────────────

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  // ── Navigation ────────────────────────────────────────────

  void _onItemSelected(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  // ── Logout ────────────────────────────────────────────────

  Future<void> _onLogout() async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'dashboard.logout_title'.tr(),
      message: 'dashboard.logout_message'.tr(),
      confirmText: 'dashboard.logout_confirm'.tr(),
      cancelText: 'dashboard.logout_cancel'.tr(),
      icon: Icons.logout,
      isDangerous: true,
    );

    if (confirmed == true && mounted) {
      await di.sl<AuthRepository>().logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.auth);
      }
    }
  }
  late final List<dynamic> _cubits;
  @override
  void initState() {
    super.initState();
    _cubits = [
      di.sl<DashboardCubit>()..load(),            // Index 0
      di.sl<InventoryCubit>()..fetchItems(),      // Index 1
      di.sl<CustomersCubit>()..fetchCustomers(),  // Index 2
      di.sl<AllInvoicesCubit>()..loadInvoices(),  // Index 3
      di.sl<FinanceCubit>()..loadSummary(),       // Index 4
      di.sl<SuppliersCubit>()..fetchSuppliers(),  // Index 5
      di.sl<AlertsCubit>()..fetchAlerts(),        // Index 6

      null, // Suppliers
    ];
  }

  // ── Content Builder ───────────────────────────────────────

  Widget _buildCurrentPage() {
    return switch (_selectedIndex) {
      0 => BlocProvider.value(
        value: _cubits[0] as DashboardCubit,
        child: const DashboardPage(),
      ),
      1 => BlocProvider.value(
        value: _cubits[1] as InventoryCubit,
        child: const InventoryPage(),
      ),
      2 => MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _cubits[2] as CustomersCubit),
          BlocProvider(create: (_) => di.sl<InvoicesCubit>()),
        ],
        child: const CustomersPage(),
      ),
      3 => BlocProvider.value(value: _cubits[3] as AllInvoicesCubit, child: const AllInvoicesPage()),
      4 => BlocProvider.value(
        value: _cubits[4] as FinanceCubit,
        child: const FinancePage(),
      ),
      5 => BlocProvider.value(
        value: _cubits[5] as SuppliersCubit,
        child: const SuppliersPage(),
      ),
      6 => BlocProvider.value(value: _cubits[6] as AlertsCubit, child: const AlertsPage()),

      _ => _ComingSoonPage(index: _selectedIndex),
    };
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final content = _buildCurrentPage();

    return ResponsiveLayout(
      mobile: _MobileLayout(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
        onLogout: _onLogout,
        content: content,
      ),
      desktop: _DesktopLayout(
        selectedIndex: _selectedIndex,
        sidebarExpanded: _sidebarExpanded,
        onItemSelected: _onItemSelected,
        onToggleSidebar: () =>
            setState(() => _sidebarExpanded = !_sidebarExpanded),
        onLogout: _onLogout,
        content: content,
      ),
    );
  }
}

// ─── Mobile Layout ────────────────────────────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final Widget content;

  const _MobileLayout({
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: onItemSelected,
        type: BottomNavigationBarType.fixed,
        items: kNavItems
            .map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          label: item.labelKey.tr(),
        ))
            .toList(),
      ),
    );
  }
}

// ─── Desktop Layout ───────────────────────────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final int selectedIndex;
  final bool sidebarExpanded;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleSidebar;
  final VoidCallback onLogout;
  final Widget content;

  const _DesktopLayout({
    required this.selectedIndex,
    required this.sidebarExpanded,
    required this.onItemSelected,
    required this.onToggleSidebar,
    required this.onLogout,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    const collapsedWidth = 85.0;
    const expandedWidth = 200.0;
    final sidebarWidth = sidebarExpanded ? expandedWidth.w : collapsedWidth;

    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: sidebarWidth,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                left: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: ClipRect(
              child: Column(
                children: [
                  _ToggleButton(
                    expanded: sidebarExpanded,
                    onTap: onToggleSidebar,
                  ),
                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  SizedBox(height: 8.h),

                  Expanded(
                    child: ListView.builder(

                      itemCount: kNavItems.length,
                      itemBuilder: (_, i) => _NavTile(
                        item: kNavItems[i],
                        isSelected: selectedIndex == i,
                        expanded: sidebarExpanded,
                        onTap: () => onItemSelected(i),
                      ),
                    ),
                  ),

                  Divider(color: Theme.of(context).dividerColor, height: 1),
                  _LogoutTile(
                    expanded: sidebarExpanded,
                    onTap: onLogout,
                  ),
                ],
              ),
            ),
          ),

          Expanded(child: content),
        ],
      ),
    );
  }
}

// ─── Sidebar Widgets ──────────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _ToggleButton({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment: expanded
            ? MainAxisAlignment.end
            : MainAxisAlignment.center,
        children: [
          if (expanded)
            Flexible(
              child: InkWell(
                  onTap: onTap,
                  child: Image.asset(Assets.logoApp, width: 300.w, height: 120.h, fit: BoxFit.contain)),
            ),
          if (!expanded)
            Flexible(
              child: InkWell(
                  onTap: onTap,
                  child: Image.asset(Assets.sLogoApp, width: 300.w, height: 100.h, fit: BoxFit.contain)),
            ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final bool expanded;
  final VoidCallback onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : Theme.of(context).iconTheme.color,
              size: 25.r,
            ),
            // AnimatedSize لعمل تأثير تمدد وانكماش للنص
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: expanded
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: 10.w),
                  // ✅ الحل هنا: الـ Flexible هو الأب المباشر للـ Row
                  Flexible(
                    child: AnimatedOpacity( // ✅ والـ AnimatedOpacity جواه
                      duration: const Duration(milliseconds: 250),
                      opacity: expanded ? 1.0 : 0.0,
                      child: Text(
                        item.labelKey.tr(),
                        style: TextStyle(
                          color: isSelected
                              ? ColorsManager.primaryColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ),
                ],
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _LogoutTile({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.logout, color: ColorsManager.errorFill, size: 20.r),
            if (expanded) ...[
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  'dashboard.nav_logout'.tr(),
                  style: TextStyle(
                    color: ColorsManager.errorFill,
                    fontSize: 13.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Coming Soon ──────────────────────────────────────────────────────────────

class _ComingSoonPage extends StatelessWidget {
  final int index;

  const _ComingSoonPage({required this.index});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 64.r,
            color: Theme.of(context).disabledColor,
          ),
          SizedBox(height: 16.h),
          Text(
            'common.coming_soon'.tr(),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8.h),
          Text(
            kNavItems[index].labelKey.tr(),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}