
import 'package:bungee_manage_sys/core/utils/assets.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'custom_lottie_icon.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholder;
  final String? errorImage;
  final Color? backgroundColor;
  final Widget? customPlaceholder;
  final Widget? customErrorWidget;
  final Duration? fadeInDuration;
  final Duration? placeholderFadeInDuration;
  final bool showLoadingIndicator;
  final Color? loadingIndicatorColor;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorImage,
    this.backgroundColor,
    this.customPlaceholder,
    this.customErrorWidget,
    this.fadeInDuration,
    this.placeholderFadeInDuration,
    this.showLoadingIndicator = true,
    this.loadingIndicatorColor,
  });

  /// ✅ Factory constructor for circular avatar
  factory CustomNetworkImage.avatar({
    required String imageUrl,
    required double size,
    String? placeholder,
    String? errorImage,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
    Color? loadingIndicatorColor,
  }) {
    return CustomNetworkImage(
      imageUrl: imageUrl ?? '',
      width: size,
      height: size,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(size / 2),
      placeholder: placeholder,
      errorImage: errorImage,
      backgroundColor: backgroundColor,
      showLoadingIndicator: showLoadingIndicator,
      loadingIndicatorColor: loadingIndicatorColor,
    );
  }

  /// ✅ Factory constructor for rounded rectangle
  factory CustomNetworkImage.rounded({
    required String imageUrl,
    required double width,
    required double height,
    double borderRadius = 8.0,
    BoxFit fit = BoxFit.cover,
    String? placeholder,
    String? errorImage,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
    Color? loadingIndicatorColor,
  }) {
    return CustomNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      borderRadius: BorderRadius.circular(borderRadius),
      placeholder: placeholder,
      errorImage: errorImage,
      backgroundColor: backgroundColor,
      showLoadingIndicator: showLoadingIndicator,
      loadingIndicatorColor: loadingIndicatorColor,
    );
  }

  /// ✅ Factory constructor for square image
  factory CustomNetworkImage.square({
    required String imageUrl,
    required double size,
    BoxFit fit = BoxFit.cover,
    double borderRadius = 0.0,
    String? placeholder,
    String? errorImage,
    Color? backgroundColor,
    bool showLoadingIndicator = true,
    Color? loadingIndicatorColor,
  }) {
    return CustomNetworkImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      borderRadius: borderRadius > 0 ? BorderRadius.circular(borderRadius) : null,
      placeholder: placeholder,
      errorImage: errorImage,
      backgroundColor: backgroundColor,
      showLoadingIndicator: showLoadingIndicator,
      loadingIndicatorColor: loadingIndicatorColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: CachedNetworkImage(
          imageUrl: imageUrl ?? '',
          width: width,
          height: height,
          fit: fit,

          fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 300),
          placeholderFadeInDuration: placeholderFadeInDuration ?? const Duration(milliseconds: 100),
          placeholder: (context, url) =>
              Container(color: Colors.grey.shade800),
          errorWidget: (context, url, error) =>
          _buildPlaceholder(context)
          // memCacheWidth: width?.toInt(),
          // memCacheHeight: height?.toInt(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    if (customPlaceholder != null) {
      return customPlaceholder!;
    }

    if (placeholder != null) {
      return Image.asset(
        placeholder!,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.asset(
      Assets.placeholderIcon,
      width: width,
      height: height,
      fit: BoxFit.scaleDown,
    );
  }

}
