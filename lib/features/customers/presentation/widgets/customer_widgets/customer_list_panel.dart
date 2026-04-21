// lib/features/customers/presentation/widgets/customer_list_panel.dart
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/core/widgets/app_text_feild.dart';
import 'package:bungee_manage_sys/core/widgets/confirmation_dialog.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/empty_state_widget.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'customer_form_dialog.dart';
import 'customer_list_item.dart';


class CustomerListPanel extends StatefulWidget {
  final String? selectedId;
  final ValueChanged<CustomerEntity> onSelect;

  const CustomerListPanel({
    super.key,
    this.selectedId,
    required this.onSelect,
  });

  @override
  State<CustomerListPanel> createState() => _CustomerListPanelState();
}

class _CustomerListPanelState extends State<CustomerListPanel> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CustomersCubit, CustomersState>(
      listener: (context, state) {
        if (state.hasError && state.errorMessage != null) {
          context.showError(state.errorMessage!);
        }
      },
      child: Column(
        children: [
          _SearchBar(
            controller: _searchCtrl,
            onChanged: (q) => context.read<CustomersCubit>().search(q),
          ),
          Expanded(child: _CustomerBody(
            selectedId: widget.selectedId,
            onSelect: widget.onSelect,
          )),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(12.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 🚨 لضمان المحاذاة في النص بالظبط
        children: [
          Expanded(
            child: AppTextFieldFactory.search(
              controller: controller,
              hintText: 'customers.search_hint'.tr(),
              onChanged: onChanged,
            ),
          ),
          SizedBox(width: 10.w), // مسافة أريح للعين

          // 🚨 الزرار المُحسّن (Premium UI) 🚨
          Tooltip(
            message: 'تصدير قائمة العملاء (Excel)',
            child: SizedBox(
              height: 48.h, // توحيد الارتفاع ليتناسب مع مربع البحث (غالباً 48)
              width: 48.h,  // زرار مربع ومضبوط
              child: Material(
                color: ColorsManager.successFill.withOpacity(0.08), // خلفية هادية
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r), // حواف أنعم
                  side: BorderSide(
                    color: ColorsManager.successFill.withOpacity(0.6), // حدود ناعمة
                    width: 1.2,
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    // إخفاء الكيبورد لو مفتوح عشان الشاشة تروق وقت التصدير
                    FocusScope.of(context).unfocus();

                    // استدعاء الدالة
                    context.read<CustomersCubit>().exportCustomersToExcel();
                  },
                  borderRadius: BorderRadius.circular(10.r),
                  splashColor: ColorsManager.successFill.withOpacity(0.2), // تأثير الضغطة (Ripple) هيشتغل بشياكة دلوقتي
                  highlightColor: ColorsManager.successFill.withOpacity(0.1),
                  child: Center(
                    child: Icon(
                      Icons.file_download_outlined,
                      color: ColorsManager.successFill,
                      size: 24.r, // حجم الأيقونة مناسب للمربع
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerBody extends StatelessWidget {
  final String? selectedId;
  final ValueChanged<CustomerEntity> onSelect;

  const _CustomerBody({this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomersCubit, CustomersState>(
      builder: (context, state) {

        // 🚨 الحل السحري للـ Flickering:
        // بنعرض اللودينج فقط لو مفيش أي عملاء أصلاً.
        // لو في عملاء، اللستة هتفضل معروضة وتتحدث في الخلفية بسلاسة!
        if (state.isLoading && state.customers.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.hasError && state.customers.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.cloud_off_rounded,
            title: 'errors.loadFailed'.tr(),
            subtitle: state.errorMessage ?? '',
            isFullPage: false,
            actionLabel: 'common.retry'.tr(),
            onActionPressed: () => context.read<CustomersCubit>().fetchCustomers(),
          );
        }

        if (!state.hasCustomers) {
          return EmptyStateWidget(
            icon: Icons.people_outline,
            title: state.searchQuery.isNotEmpty
                ? 'customers.no_results'.tr()
                : 'customers.empty_title'.tr(),
            subtitle: state.searchQuery.isNotEmpty
                ? ''
                : 'customers.empty_sub'.tr(),
            isFullPage: false,
          );
        }

        return ListView.builder(
          itemCount: state.filtered.length,
          itemBuilder: (context, i) {
            final customer = state.filtered[i];
            return CustomerListItem(
              customer: customer,
              isSelected: selectedId == customer.id,
              onTap: () => onSelect(customer),
              onEdit: () => showCustomerFormDialog(
                context,
                initialCustomer: customer,
              ),
              onDelete: () async {
                final confirmed = await showConfirmationDialog(
                  context: context,
                  title: 'customers.delete_title'.tr(),
                  message: 'customers.delete_confirm'.tr(),
                  confirmText: 'common.confirm'.tr(),
                  cancelText: 'common.cancel'.tr(),
                  icon: Icons.person_remove_outlined,
                  isDangerous: true,
                );
                if (confirmed == true && context.mounted) {
                  context.read<CustomersCubit>().deleteCustomer(customer.id);
                }
              },
            );
          },
        );
      },
    );
  }
}
