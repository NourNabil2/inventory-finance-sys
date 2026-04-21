// lib/core/widgets/empty_state_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'app_buton.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double iconSize;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  // ✅ لما تكون standalone page فيها back button
  // ✅ لما تكون جزء من page موجودة → false
  final bool isFullPage;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconSize = 80,
    this.onActionPressed,
    this.actionLabel,
    this.isFullPage = false,    // default: embedded — مش standalone
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final body = Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: iconSize.r,
              color: Theme.of(context).disabledColor,
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onActionPressed != null && actionLabel != null) ...[
              SizedBox(height: 24.h),
              AppButton(
                text: actionLabel!,
                onPressed: onActionPressed,
                horizontalPadding: 40.w,
                verticalPadding: 0,
              ),
            ],
          ],
        ),
      ),
    );

    // لو standalone page → wrap في Scaffold مع back button
    if (isFullPage) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: AppBarButton(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: body,
      );
    }

    // لو embedded → بس الـ body من غير scaffold
    return body;
  }
}