// lib/features/customers/presentation/widgets/customer_form_dialog.dart

import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/utils/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:bungee_manage_sys/core/widgets/app_dialog_shell.dart';
import 'package:bungee_manage_sys/core/widgets/app_text_feild.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/customers/domain/entities/customer_entity.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/customers_cubit.dart';

void showCustomerFormDialog(
    BuildContext context, {
      CustomerEntity? initialCustomer,
    }) {
  // اصطياد الـ Cubit قبل فتح الـ Dialog لضمان استقرار الـ Context
  final cubit = context.read<CustomersCubit>();

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _CustomerFormDialog(initialCustomer: initialCustomer),
    ),
  );
}

class _CustomerFormDialog extends StatefulWidget {
  final CustomerEntity? initialCustomer;

  const _CustomerFormDialog({this.initialCustomer});

  @override
  State<_CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends State<_CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  bool get _isEdit => widget.initialCustomer != null;

  @override
  void initState() {
    super.initState();
    // تهيئة الـ Controllers بشكل نظيف في سطر واحد
    _nameCtrl = TextEditingController(text: widget.initialCustomer?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.initialCustomer?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final customer = CustomerEntity(
      id: widget.initialCustomer?.id ?? const Uuid().v4(),
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      totalPaid: widget.initialCustomer?.totalPaid ?? 0,
      totalDebt: widget.initialCustomer?.totalDebt ?? 0,
      createdAt: widget.initialCustomer?.createdAt ?? DateTime.now(),
    );
    context.read<CustomersCubit>().saveCustomer(customer);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomersCubit, CustomersState>(
      listenWhen: (previous, current) => previous.formStatus != current.formStatus,
      listener: (context, state) {
        if (state.formStatus == CustomerFormStatus.submitted) {
          Navigator.of(context).pop();
          context.showSuccess('customers.saved'.tr());
        } else if (state.formStatus == CustomerFormStatus.error) {
          context.showError(state.errorMessage ?? 'common.error'.tr());
        }
      },
      builder: (context, state) {
        final isLoading = state.formStatus == CustomerFormStatus.submitting;

        return AppDialogShell(
          title: (_isEdit ? 'customers.edit_customer' : 'customers.add_customer').tr(),
          saveLabel: 'common.save'.tr(),
          isLoading: isLoading,
          onClose: isLoading ? null : () => Navigator.of(context).pop(),
          onSave: _submit,
          content: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _nameCtrl,
                  title: 'customers.name'.tr(),
                  hintText: 'customers.name_hint'.tr(),
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'validation.nameRequired'.tr()
                      : null,
                ),
                SizedBox(height: AppSizeVertical.instance.s12),
                AppTextField(
                  controller: _phoneCtrl,
                  title: 'customers.phone'.tr(),
                  hintText: 'customers.phone_hint'.tr(),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'validation.phoneRequired'.tr()
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}