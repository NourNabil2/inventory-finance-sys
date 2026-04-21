// lib/core/widgets/app_dialog_shell.dart

import 'package:flutter/material.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/app_buton.dart';

class AppDialogShell extends StatelessWidget {
  final String title;
  final Widget content;
  final String saveLabel;
  final bool isLoading;
  final VoidCallback onSave;
  final VoidCallback? onClose;
  final double maxWidth;
  final double? maxHeight;

  const AppDialogShell({
    super.key,
    required this.title,
    required this.content,
    required this.saveLabel,
    required this.isLoading,
    required this.onSave,
    this.onClose,
    this.maxWidth = 720,
    this.maxHeight,
  });

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    final size = MediaQuery.of(context).size;
    final dialogMaxHeight = maxHeight ?? size.height * 0.85;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: h.s16,
        vertical: h.s16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(h.s16),
      ),
      child: Container(
        width: maxWidth.clamp(280.0, size.width * 0.9),
        constraints: BoxConstraints(
          maxHeight: dialogMaxHeight.clamp(200.0, size.height * 0.9),
        ),
        padding: EdgeInsets.all(h.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(width: h.s8),
                IconButton(
                  onPressed: onClose,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).iconTheme.color,
                  ),
                ),
              ],
            ),
            SizedBox(height: v.s20),

            // Content
            Flexible(
              child: SingleChildScrollView(
                child: content,
              ),
            ),

            SizedBox(height: v.s24),

            // Save Button
            AppButton(
              text: saveLabel,
              isLoading: isLoading,
              active: !isLoading,
              horizontalPadding: 0,
              verticalPadding: 0,
              onPressed: onSave,
            ),
          ],
        ),
      ),
    );
  }
}