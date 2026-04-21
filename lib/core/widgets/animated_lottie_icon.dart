// lib/core/widgets/animated_lottie_icon.dart

import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// A reusable widget for animated Lottie icons
/// Plays animation forward on tap, and resets to first frame on second tap
class AnimatedLottieIcon extends StatefulWidget {
  /// Path to the Lottie animation file
  final String assetPath;

  /// Size of the icon
  final double size;

  /// Whether the icon is in active state (e.g., favorited)
  final bool isActive;

  /// Callback when animation state changes
  final VoidCallback? onTap;

  /// Background color of the container
  final Color? backgroundColor;

  /// Border radius of the container
  final BorderRadius? borderRadius;

  /// Whether to show circular shape
  final bool isCircular;

  /// Whether to show shadow
  final bool showShadow;

  /// Custom decoration for the container
  final BoxDecoration? decoration;

  const AnimatedLottieIcon({
    super.key,
    required this.assetPath,
    required this.size,
    required this.isActive,
    this.onTap,
    this.backgroundColor,
    this.borderRadius,
    this.isCircular = true,
    this.showShadow = true,
    this.decoration,
  });

  @override
  State<AnimatedLottieIcon> createState() => _AnimatedLottieIconState();
}

class _AnimatedLottieIconState extends State<AnimatedLottieIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Set initial state based on isActive
    if (widget.isActive) {
      _controller.value = 1.0; // Show last frame if active
    } else {
      _controller.value = 0.0; // Show first frame if inactive
    }
  }

  @override
  void didUpdateWidget(AnimatedLottieIcon oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle state changes from parent
    if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        // Play forward animation
        _controller.forward();
      } else {
        // Reset to first frame
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        decoration: widget.decoration ??
            BoxDecoration(
              color: widget.backgroundColor ?? ColorsManager.defaultSurface,
              shape: widget.isCircular ? BoxShape.circle : BoxShape.rectangle,
            ),
        child: Lottie.asset(
          widget.assetPath,
          controller: _controller,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          onLoaded: (composition) {
            // Set animation duration based on the composition
            _controller.duration = composition.duration;
          },
        ),
      ),
    );
  }
}

