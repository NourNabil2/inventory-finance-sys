// lib/core/widgets/responsive_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Breakpoints
// ─────────────────────────────────────────────────────────────────────────────

/// Breakpoints for responsive design.
///   mobile  : < 600
///   tablet  : 600 – 899
///   desktop : >= 900
class Breakpoints {
  static const double mobile  = 600;
  static const double tablet  = 900;
  static const double desktop = 1200;
}

// ─────────────────────────────────────────────────────────────────────────────
// ResponsiveLayout widget
// ─────────────────────────────────────────────────────────────────────────────

/// Switches between mobile, tablet, and desktop layouts based on screen width.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < Breakpoints.mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= Breakpoints.mobile && w < Breakpoints.tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= Breakpoints.tablet) return desktop;
    if (width >= Breakpoints.mobile) return tablet ?? mobile;
    return mobile;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Responsive context extension
// ─────────────────────────────────────────────────────────────────────────────

extension ResponsiveContext on BuildContext {
  bool get isMobile  => ResponsiveLayout.isMobile(this);
  bool get isTablet  => ResponsiveLayout.isTablet(this);
  bool get isDesktop => ResponsiveLayout.isDesktop(this);
}

// ─────────────────────────────────────────────────────────────────────────────
// Page layout constants
//
// These values drive content width limits and padding across full-page
// content areas (invoices, reports, detail pages). Centralised here so
// every page that needs "max-width + centred padding" reads from one place.
// ─────────────────────────────────────────────────────────────────────────────

/// Cap for wide content areas (invoice, detail pages, etc.).
/// Content wider than this is centred with auto side margins.
const double kContentMaxWidth = 1100;

/// Minimum render width for horizontally-scrollable data tables.
/// Below this value the table scrolls instead of compressing columns.
const double kTableMinWidth = 680;

/// Horizontal page padding that scales with [Breakpoints].
///
/// On very wide screens (≥ [Breakpoints.desktop]) the content is centred
/// inside [kContentMaxWidth]; padding is derived from the remaining space
/// rather than a fixed value so the content never floats off-centre.
double pageHPad(BuildContext context) {
  final w = MediaQuery.sizeOf(context).width;
  if (w >= Breakpoints.desktop) return ((w - 920) / 2).clamp(40.0, 120.0);
  if (w >= Breakpoints.tablet)  return 40.w;
  if (w >= Breakpoints.mobile)  return 24.w;
  return 16.w;
}

/// Wraps [child] in a centred [ConstrainedBox] capped at [kContentMaxWidth].
/// Use inside any scrollable page body that should not stretch on wide screens.
Widget centredContentBox({required Widget child}) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
    child: child,
  ),
);