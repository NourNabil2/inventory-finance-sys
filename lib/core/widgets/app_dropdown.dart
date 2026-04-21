// lib/core/widgets/app_dropdown.dart

import 'package:flutter/material.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';

class AppDropdown<T> extends StatelessWidget {
  final String title;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  const AppDropdown({
    super.key,
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;
    final v = AppSizeVertical.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        SizedBox(height: v.s8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: h.s16),
          decoration: BoxDecoration(
            border: Border.all(
              color: enabled
                  ? Theme.of(context).dividerColor
                  : Theme.of(context).disabledColor,
            ),
            borderRadius: BorderRadius.circular(h.s12),
            color: enabled
                ? Theme.of(context).cardColor
                : Theme.of(context).disabledColor.withOpacity(0.05),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: enabled
                    ? ColorsManager.primaryColor
                    : Theme.of(context).disabledColor,
              ),
              style: Theme.of(context).textTheme.bodyMedium,
              onChanged: enabled ? onChanged : null,
              items: items,
            ),
          ),
        ),
      ],
    );
  }
}