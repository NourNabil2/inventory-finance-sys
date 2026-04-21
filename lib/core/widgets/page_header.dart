import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/widgets/app_buton.dart';

/// A reusable page header widget that can be used across multiple pages.
///
/// Features:
/// - Title and subtitle display
/// - Optional action button
/// - Responsive padding
/// - Consistent styling
///
/// Example usage:
/// ```dart
/// PageHeader(
///   titleKey: 'inventory.title',
///   subtitleKey: 'inventory.subtitle',
///   actionButton: PageHeaderAction(
///     textKey: 'inventory.add_item',
///     icon: Icons.add,
///     onPressed: () => _showAddItemDialog(),
///   ),
/// )
/// ```
class PageHeader extends StatelessWidget {
  /// Translation key for the title
  final String titleKey;

  /// Optional translation key for the subtitle
  final String? subtitleKey;

  /// Optional action button configuration
  final PageHeaderAction? actionButton;

  /// Custom widget to display instead of action button
  final Widget? actionWidget;

  /// Background color, defaults to theme card color
  final Color? backgroundColor;

  /// Padding override
  final EdgeInsets? padding;

  const PageHeader({
    super.key,
    required this.titleKey,
    this.subtitleKey,
    this.actionButton,
    this.actionWidget,
    this.backgroundColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      color: backgroundColor ?? Theme.of(context).cardColor,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titleKey.tr(),
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitleKey != null) ...[
                  SizedBox(height: 2.h),
                  Text(
                    subtitleKey!.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (actionWidget != null) actionWidget!,
          if (actionButton != null)
            SizedBox(
              width: actionButton!.width ?? 160.w,
              child: AppButton(
                text: actionButton!.textKey.tr(),
                leadingIcon: actionButton!.icon,
                horizontalPadding: actionButton!.horizontalPadding ?? 0,
                verticalPadding: actionButton!.verticalPadding ?? 0,
                onPressed: actionButton!.onPressed,
              ),
            ),
        ],
      ),
    );
  }
}

/// Configuration class for page header action button
class PageHeaderAction {
  /// Translation key for button text
  final String textKey;

  /// Icon to display before text
  final IconData? icon;

  /// Callback when button is pressed
  final VoidCallback onPressed;

  /// Button width
  final double? width;

  /// Horizontal padding
  final double? horizontalPadding;

  /// Vertical padding
  final double? verticalPadding;

  const PageHeaderAction({
    required this.textKey,
    required this.onPressed,
    this.icon,
    this.width,
    this.horizontalPadding,
    this.verticalPadding,
  });
}

/// A simplified page header with just title and optional back button
class SimplePageHeader extends StatelessWidget {
  final String titleKey;
  final bool showBackButton;
  final List<Widget>? actions;

  const SimplePageHeader({
    super.key,
    required this.titleKey,
    this.showBackButton = false,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      color: Theme.of(context).cardColor,
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            SizedBox(width: 8.w),
          ],
          Expanded(
            child: Text(
              titleKey.tr(),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (actions != null) ...actions!,
        ],
      ),
    );
  }
}