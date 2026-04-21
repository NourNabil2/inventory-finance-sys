/*
// lib/features/dashboard/presentation/widgets/app_sidebar.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/di/injection_container.dart' as di;
import 'package:bungee_manage_sys/core/routes/routes.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/confirmation_dialog.dart';
import 'package:bungee_manage_sys/features/auth/domain/repositories/auth_repository.dart';

// ─── Nav item model ──────────────────────────────────────────────────────────


class _NavItem {
  final IconData icon;
  final String labelKey;
  final String route;

  const _NavItem({
    required this.icon,
    required this.labelKey,
    required this.route,
  });
}

// lib/features/dashboard/presentation/widgets/app_sidebar.dart

// lib/features/dashboard/presentation/widgets/app_sidebar.dart

const _navItems = [
  _NavItem(
    icon: Icons.dashboard_outlined,
    labelKey: 'dashboard.nav_home',
    route: Routes.dashBoard,        // ← أضف route لكل item
  ),
  _NavItem(
    icon: Icons.videocam_outlined,
    labelKey: 'dashboard.nav_inventory',
    route: Routes.inventory,
  ),
  _NavItem(
    icon: Icons.people_outline,
    labelKey: 'dashboard.nav_customers',
    route: Routes.customers,        // TODO: لما تعمل الـ module
  ),
  _NavItem(
    icon: Icons.receipt_outlined,
    labelKey: 'dashboard.nav_invoices',
    route: Routes.invoices,
  ),
  _NavItem(
    icon: Icons.account_balance_wallet_outlined,
    labelKey: 'dashboard.nav_finance',
    route: Routes.finance,
  ),
  _NavItem(
    icon: Icons.bookmark_border_outlined,
    labelKey: 'dashboard.nav_checks',
    route: Routes.checks,
  ),
  _NavItem(
    icon: Icons.local_shipping_outlined,
    labelKey: 'dashboard.nav_suppliers',
    route: Routes.suppliers,
  ),
];
// ─── AppSidebar ──────────────────────────────────────────────────────────────

class AppSidebar extends StatefulWidget {
  final Widget child;

  const AppSidebar({super.key, required this.child});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  bool _expanded = true;
  int _selectedIndex = 0;

  // FIX: لا نستخدم LoginCubit هنا لأنه في route تاني
  // بنستخدم AuthRepository مباشرة من الـ DI
  Future<void> _onLogout(BuildContext context) async {
    final confirmed = await showConfirmationDialog(
      context: context,
      title: 'dashboard.logout_title'.tr(),
      message: 'dashboard.logout_message'.tr(),
      confirmText: 'dashboard.logout_confirm'.tr(),
      cancelText: 'dashboard.logout_cancel'.tr(),
      icon: Icons.logout,
      isDangerous: true,
    );

    if (confirmed == true && context.mounted) {
      await di.sl<AuthRepository>().logout();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(Routes.auth);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: استخدم قيم ثابتة مش .w عشان الـ collapsed width دقيق
    const collapsedWidth = 64.0;
    const expandedWidth = 200.0;
    final sidebarWidth = _expanded ? expandedWidth.w : collapsedWidth;

    return Row(
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
          // FIX: clip عشان لو الـ animation في النص overflow مايبانش
          child: ClipRect(
            child: Column(
              children: [
                // ── Toggle ─────────────────────────────────
                _ToggleButton(
                  expanded: _expanded,
                  onTap: () => setState(() => _expanded = !_expanded),
                ),

                // ── Logo ───────────────────────────────────
                if (_expanded)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      'app.name'.tr(),
                      style: TextStyle(
                        color: ColorsManager.primaryColor,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  )
                else
                  SizedBox(height: 12.h),

                Divider(color: Theme.of(context).dividerColor, height: 1),
                SizedBox(height: 8.h),

                // ── Nav Items ───────────────────────────────
                Expanded(
                  child: ListView.builder(
                    itemCount: _navItems.length,
                    itemBuilder: (_, i) => _NavTile(
                      item: _navItems[i],
                      isSelected: _selectedIndex == i,
                      expanded: _expanded,
                      onTap: () {
                        if (_selectedIndex == i) return;
                        setState(() => _selectedIndex = i);
                        Navigator.of(context).pushReplacementNamed(_navItems[i].route);
                      },
                    ),
                  ),
                ),

                // ── Logout ──────────────────────────────────
                Divider(color: Theme.of(context).dividerColor, height: 1),
                _LogoutTile(
                  expanded: _expanded,
                  onTap: () => _onLogout(context),
                ),
              ],
            ),
          ),
        ),

        // ── Main Content ────────────────────────────────────
        Expanded(child: widget.child),
      ],
    );
  }
}

// ─── Private sub-widgets ─────────────────────────────────────────────────────

class _ToggleButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onTap;

  const _ToggleButton({required this.expanded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: Icon(
          expanded ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
          size: 14.r,
        ),
        onPressed: onTap,
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
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
    final activeColor = ColorsManager.primaryColor;
    final inactiveColor = Theme.of(context).iconTheme.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        // FIX: مش بنستخدم MainAxisSize.max لما يكون collapsed
        // لأن الـ container بيبقى ضيق جداً والـ Row بيـoverflow
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 20.r,
            ),
            // FIX: بنظهر النص بس لو expanded وبنحطه في Flexible
            if (expanded) ...[
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  item.labelKey.tr(),
                  style: TextStyle(
                    color: isSelected ? activeColor : Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 13.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
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
                  style: TextStyle(color: ColorsManager.errorFill, fontSize: 13.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}*/
