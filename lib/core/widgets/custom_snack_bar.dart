// lib/core/widgets/custom_snackbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';

enum SnackBarType { success, error, warning, info }

/// SnackBar متجاوب يدعم Desktop وMobile مع UI حديث
class CustomSnackBar {
  static OverlayEntry? _currentEntry;

  static void show(
      BuildContext context, {
        required String message,
        SnackBarType type = SnackBarType.success,
        Duration duration = const Duration(seconds: 4),
        String? actionLabel,
        VoidCallback? onActionPressed,
        bool showCloseButton = true,
      }) {
    // إزالة أي SnackBar سابق
    _currentEntry?.remove();

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackBarWidget(
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        showCloseButton: showCloseButton,
        onDismiss: () {
          if (_currentEntry == overlayEntry) {
            _currentEntry = null;
          }
          overlayEntry.remove();
        },
      ),
    );

    _currentEntry = overlayEntry;
    overlay.insert(overlayEntry);
  }

  /// إخفاء أي SnackBar نشط
  static void hide() {
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _CustomSnackBarWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showCloseButton;
  final VoidCallback onDismiss;

  const _CustomSnackBarWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onActionPressed,
    required this.showCloseButton,
    required this.onDismiss,
  });

  @override
  State<_CustomSnackBarWidget> createState() => _CustomSnackBarWidgetState();
}

class _CustomSnackBarWidgetState extends State<_CustomSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  double _dragOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _controller.forward();
    _scheduleDismiss();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  void _scheduleDismiss() {
    Future.delayed(widget.duration, _dismiss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismiss() async {
    if (mounted) {
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.primaryDelta ?? 0;
      _dragOffset = _dragOffset.clamp(-300.0, 0.0);
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset < -80 || details.velocity.pixelsPerSecond.dy < -300) {
      _dismiss();
    } else {
      setState(() => _dragOffset = 0.0);
    }
  }

  // ═══ COLORS ═══

  Color get _backgroundColor {
    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF059669);
      case SnackBarType.error:
        return const Color(0xFFDC2626);
      case SnackBarType.warning:
        return const Color(0xFFD97706);
      case SnackBarType.info:
        return const Color(0xFF2563EB);
    }
  }

  Color get _iconBackgroundColor {
    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF047857);
      case SnackBarType.error:
        return const Color(0xFFB91C1C);
      case SnackBarType.warning:
        return const Color(0xFFB45309);
      case SnackBarType.info:
        return const Color(0xFF1D4ED8);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  String get _defaultActionLabel {
    switch (widget.type) {
      case SnackBarType.success:
        return 'common.ok'.tr();
      case SnackBarType.error:
        return 'common.retry'.tr();
      case SnackBarType.warning:
        return 'common.understood'.tr();
      case SnackBarType.info:
        return 'common.details'.tr();
    }
  }

  // ═══ BUILD ═══

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;

    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + (isDesktop ? 24.h : 12.h),
      left: isDesktop ? null : 16.w,
      right: isDesktop ? 16.w : null,
      child: isDesktop
          ? _buildDesktopSnackBar(context)
          : _buildMobileSnackBar(context),
    );
  }

  Widget _buildDesktopSnackBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final snackBarWidth = screenWidth > 1200 ? 500.w : 450.w;

    return Center(
      child: GestureDetector(
        onVerticalDragUpdate: _handleDragUpdate,
        onVerticalDragEnd: _handleDragEnd,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Transform.translate(
              offset: Offset(0, _dragOffset),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _dragOffset < -50 ? 0.5 : 1.0,
                child: Container(
                  width: snackBarWidth,
                  constraints: BoxConstraints(maxWidth: 600.w),
                  child: _SnackBarContent(
                    type: widget.type,
                    message: widget.message,
                    icon: _icon,
                    backgroundColor: _backgroundColor,
                    iconBackgroundColor: _iconBackgroundColor,
                    actionLabel: widget.actionLabel ?? _defaultActionLabel,
                    onActionPressed: widget.onActionPressed,
                    showCloseButton: widget.showCloseButton,
                    onDismiss: _dismiss,
                    isDesktop: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSnackBar(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: _handleDragUpdate,
      onVerticalDragEnd: _handleDragEnd,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Transform.translate(
            offset: Offset(0, _dragOffset),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: _dragOffset < -50 ? 0.5 : 1.0,
              child: _SnackBarContent(
                type: widget.type,
                message: widget.message,
                icon: _icon,
                backgroundColor: _backgroundColor,
                iconBackgroundColor: _iconBackgroundColor,
                actionLabel: widget.actionLabel ?? _defaultActionLabel,
                onActionPressed: widget.onActionPressed,
                showCloseButton: widget.showCloseButton,
                onDismiss: _dismiss,
                isDesktop: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SNACKBAR CONTENT
// ═══════════════════════════════════════════════════════════════════════════════

class _SnackBarContent extends StatelessWidget {
  final SnackBarType type;
  final String message;
  final IconData icon;
  final Color backgroundColor;
  final Color iconBackgroundColor;
  final String actionLabel;
  final VoidCallback? onActionPressed;
  final bool showCloseButton;
  final VoidCallback onDismiss;
  final bool isDesktop;

  const _SnackBarContent({
    required this.type,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.iconBackgroundColor,
    required this.actionLabel,
    this.onActionPressed,
    required this.showCloseButton,
    required this.onDismiss,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: isDesktop ? 12 : 8,
      shadowColor: backgroundColor.withOpacity(0.4),
      borderRadius: BorderRadius.circular(isDesktop ? 20.r : 16.r),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(isDesktop ? 20.r : 16.r),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: isDesktop ? 24 : 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isDesktop ? 20.r : 16.r),
          child: Stack(
            children: [
              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Drag indicator
              Positioned(
                top: isDesktop ? 10.h : 8.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: isDesktop ? 40.w : 32.w,
                    height: isDesktop ? 5.h : 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24.w : 16.w,
                  isDesktop ? 24.h : 20.h,
                  isDesktop ? 24.w : 16.w,
                  isDesktop ? 24.h : 16.h,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      width: isDesktop ? 48.w : 40.w,
                      height: isDesktop ? 48.w : 40.w,
                      decoration: BoxDecoration(
                        color: iconBackgroundColor,
                        borderRadius: BorderRadius.circular(isDesktop ? 14.r : 12.r),
                      ),
                      child: Icon(
                        icon,
                        color: Colors.white,
                        size: isDesktop ? 28.sp : 24.sp,
                      ),
                    ),

                    SizedBox(width: isDesktop ? 16.w : 12.w),

                    // Message
                    Expanded(
                      child: Text(
                        message,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop ? 16.sp : 15.sp,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Action Button
                    if (onActionPressed != null || actionLabel.isNotEmpty) ...[
                      SizedBox(width: isDesktop ? 16.w : 12.w),
                      _ActionButton(
                        label: actionLabel,
                        onPressed: onActionPressed ?? onDismiss,
                        isDesktop: isDesktop,
                      ),
                    ],

                    // Close Button
                    if (showCloseButton) ...[
                      SizedBox(width: isDesktop ? 12.w : 8.w),
                      _CloseButton(
                        onPressed: onDismiss,
                        isDesktop: isDesktop,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// BUTTONS
// ═══════════════════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isDesktop;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isDesktop ? 12.r : 10.r),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 20.w : 16.w,
            vertical: isDesktop ? 12.h : 10.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.25),
            borderRadius: BorderRadius.circular(isDesktop ? 12.r : 10.r),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 15.sp : 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isDesktop;

  const _CloseButton({
    required this.onPressed,
    required this.isDesktop,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(isDesktop ? 12.r : 10.r),
        child: Container(
          width: isDesktop ? 40.w : 36.w,
          height: isDesktop ? 40.w : 36.w,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(isDesktop ? 12.r : 10.r),
          ),
          child: Icon(
            Icons.close_rounded,
            color: Colors.white,
            size: isDesktop ? 22.sp : 20.sp,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// EXTENSION
// ═══════════════════════════════════════════════════════════════════════════════

extension CustomSnackBarExtension on BuildContext {
  void showSuccess(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(
      this,
      message: message,
      type: SnackBarType.success,
      actionLabel: actionLabel,
      onActionPressed: onAction,
    );
  }

  void showError(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(
      this,
      message: message,
      type: SnackBarType.error,
      actionLabel: actionLabel ?? 'common.retry'.tr(),
      onActionPressed: onAction,
    );
  }

  void showWarning(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(
      this,
      message: message,
      type: SnackBarType.warning,
      actionLabel: actionLabel,
      onActionPressed: onAction,
    );
  }

  void showInfo(String message, {String? actionLabel, VoidCallback? onAction}) {
    CustomSnackBar.show(
      this,
      message: message,
      type: SnackBarType.info,
      actionLabel: actionLabel,
      onActionPressed: onAction,
    );
  }
}