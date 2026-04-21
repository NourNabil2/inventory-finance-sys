// lib/core/widgets/app_card.dart
//
// A single, theme-aware card used across the entire app.
// Replaces every hand-rolled Container(decoration: BoxDecoration(...)) card.
//
// Usage:
//   AppCard(child: Text('hello'))
//   AppCard.highlighted(child: ...)          // primary-tinted border
//   AppCard.flat(child: ...)                 // no border (elevation only)
//   AppCard(padding: EdgeInsets.zero, ...)   // custom padding (e.g. for tables)
// ─────────────────────────────────────────────────────────────────────────────
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

enum AppCardVariant {
  /// Default: card background + 1 px divider border.
  outlined,

  /// Primary-tinted fill + primary-tinted border. Use for "hero" totals.
  highlighted,

  /// No border. Card colour only (suits inner/nested cards).
  flat,
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final AppCardVariant variant;
  final Color? color;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.variant = AppCardVariant.outlined,
    this.color,
    this.borderRadius,
  });

  /// Shorthand for [AppCardVariant.highlighted].
  const AppCard.highlighted({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
  }) : variant = AppCardVariant.highlighted;

  /// Shorthand for [AppCardVariant.flat].
  const AppCard.flat({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.borderRadius,
  }) : variant = AppCardVariant.flat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final r = (borderRadius ?? 8).r;

    final bg = color ??
        (variant == AppCardVariant.highlighted
            ? ColorsManager.primaryColor.withOpacity(0.04)
            : theme.cardColor);

    final borderColor = switch (variant) {
      AppCardVariant.outlined    => theme.dividerColor,
      AppCardVariant.highlighted => ColorsManager.primaryColor.withOpacity(0.2),
      AppCardVariant.flat        => Colors.transparent,
    };

    return Container(
      padding: padding ?? EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(r),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}