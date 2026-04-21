// lib/core/widgets/app_image_picker.dart

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/custom_network_image.dart';

class AppImagePicker extends StatelessWidget {
  final File? pickedImage;
  final String? existingUrl;
  final VoidCallback? onTap;     // null = disabled
  final double height;

  const AppImagePicker({
    super.key,
    this.pickedImage,
    this.existingUrl,
    this.onTap,
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;
    final hasImage = pickedImage != null || existingUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(h.s12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: hasImage
            ? ClipRRect(
          borderRadius: BorderRadius.circular(h.s12),
          child: pickedImage != null
              ? Image.file(pickedImage!,
              fit: BoxFit.cover, width: double.infinity)
              : CustomNetworkImage(
            imageUrl: existingUrl,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: AppSizeHorizontal.instance.s32,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: v.s8),
            Text(
              'inventory.pick_image'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}