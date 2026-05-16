// lib/features/inventory/presentation/widgets/inventory_filter_bar.dart

import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/app_text_feild.dart';
import 'package:bungee_manage_sys/features/inventory/domain/entities/item_entity.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';

class InventoryFilterBar extends StatefulWidget {
  const InventoryFilterBar({super.key});

  @override
  State<InventoryFilterBar> createState() => _InventoryFilterBarState();
}

class _InventoryFilterBarState extends State<InventoryFilterBar> {
  final _searchCtrl = TextEditingController();
  ItemStatus? _selectedStatus;
  String? _selectedCategoryId;

  final _h = AppSizeHorizontal.instance;
  final _v = AppSizeVertical.instance;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _statusLabel(ItemStatus? s) => switch (s) {
    null                   => 'inventory.filter_all',
    ItemStatus.available   => 'inventory.filter_available',
    ItemStatus.rented      => 'inventory.filter_rented',
    ItemStatus.maintenance => 'inventory.filter_maintenance',
    ItemStatus.reserved    => 'inventory.filter_reserved',
  };

  @override
  Widget build(BuildContext context) {
    final categories = switch (context.watch<InventoryCubit>().state) {
      InventoryLoaded(:final categories) => categories,
      _ => <ItemCategoryEntity>[],
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: _h.s20, vertical: _v.s12),
      child: Row(
        children: [
          // ── Search ──────────────────────────────────────
          Expanded(
            child: AppTextFieldFactory.search(
              controller: _searchCtrl,
              hintText: 'inventory.search_hint'.tr(),
              onChanged: (v) => context.read<InventoryCubit>().search(v),
            ),
          ),

          SizedBox(width: _h.s12),

          // ── Category Filter ──────────────────────────────
          if (categories.isNotEmpty)
            _FilterDropdown<String?>(
              value: _selectedCategoryId,
              items: [
                DropdownMenuItem(
                    value: null,
                    child: Text('inventory.filter_all'.tr())),
                ...categories.map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )),
              ],
              onChanged: (val) {
                setState(() => _selectedCategoryId = val);
                context.read<InventoryCubit>().filterByCategory(val);
              },
            ),

          SizedBox(width: _h.s8),

          // ── Status Filter ────────────────────────────────
          _FilterDropdown<ItemStatus?>(
            value: _selectedStatus,
            items: [null, ...ItemStatus.values]
                .map((s) => DropdownMenuItem(
              value: s,
              child: Text(_statusLabel(s).tr()),
            ))
                .toList(),
            onChanged: (val) {
              setState(() => _selectedStatus = val);
              context.read<InventoryCubit>().filterByStatus(val);
            },
          ),

          SizedBox(width: _h.s8),

          // ── Reset ────────────────────────────────────────
          IconButton(
            onPressed: () {
              _searchCtrl.clear();
              setState(() {
                _selectedStatus     = null;
                _selectedCategoryId = null;
              });
              context.read<InventoryCubit>().fetchItems();
            },
            icon: const Icon(Icons.refresh,
                color: ColorsManager.primaryColor, size: 20),
            tooltip: 'common.retry'.tr(),
          ),
        ],
      ),
    );
  }
}

// ─── Reusable filter dropdown ─────────────────────────────────────────────────

class _FilterDropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _FilterDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final h = AppSizeHorizontal.instance;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: h.s12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(h.s12),
        color: Theme.of(context).cardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          icon: Icon(Icons.filter_list,
              color: ColorsManager.primaryColor, size: 18),
          style: Theme.of(context).textTheme.bodySmall,
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}