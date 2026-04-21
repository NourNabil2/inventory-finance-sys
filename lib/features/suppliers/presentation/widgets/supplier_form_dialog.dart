// lib/features/suppliers/presentation/widgets/supplier_form_dialog.dart

import 'package:bungee_manage_sys/core/utils/app_size.dart';
import 'package:bungee_manage_sys/core/widgets/app_dialog_shell.dart';
import 'package:bungee_manage_sys/core/widgets/app_text_feild.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/entities/supplier_entity.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

void showSupplierFormDialog(
    BuildContext context, {
      SupplierEntity? initialSupplier,
    }) {
  final cubit = context.read<SuppliersCubit>();
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: _SupplierFormDialog(initialSupplier: initialSupplier),
    ),
  );
}

class _SupplierFormDialog extends StatefulWidget {
  final SupplierEntity? initialSupplier;
  const _SupplierFormDialog({this.initialSupplier});

  @override
  State<_SupplierFormDialog> createState() => _SupplierFormDialogState();
}

class _SupplierFormDialogState extends State<_SupplierFormDialog> {
  final _formKey  = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;

  bool get _isEdit => widget.initialSupplier != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.initialSupplier?.name  ?? '');
    _phoneCtrl = TextEditingController(text: widget.initialSupplier?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final supplier = SupplierEntity(
      id:        widget.initialSupplier?.id ?? const Uuid().v4(),
      name:      _nameCtrl.text.trim(),
      phone:     _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      balance:   widget.initialSupplier?.balance   ?? 0,
      createdAt: widget.initialSupplier?.createdAt ?? DateTime.now(),
    );
    context.read<SuppliersCubit>().saveSupplier(supplier);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SuppliersCubit, SuppliersState>(
      listenWhen: (p, c) => p.formStatus != c.formStatus,
      listener: (context, state) {
        if (state.formStatus == SupplierFormStatus.submitted) {
          Navigator.of(context).pop();
          context.showSuccess(
              _isEdit ? 'تم تحديث المورد بنجاح' : 'تم إضافة المورد بنجاح');
        } else if (state.formStatus == SupplierFormStatus.error) {
          context.showError(state.errorMessage ?? 'حدث خطأ');
        }
      },
      builder: (context, state) {
        final isLoading = state.formStatus == SupplierFormStatus.submitting;
        return AppDialogShell(
          title:     _isEdit ? 'تعديل المورد' : 'إضافة مورد',
          saveLabel: 'حفظ',
          isLoading: isLoading,
          onClose:   isLoading ? null : () => Navigator.of(context).pop(),
          onSave:    _submit,
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: _nameCtrl,
                  title:      'اسم المورد',
                  hintText:   'أدخل اسم المورد',
                  keyboardType:    TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                ),
                SizedBox(height: AppSizeVertical.instance.s12),
                AppTextField(
                  controller: _phoneCtrl,
                  title:      'رقم الهاتف (اختياري)',
                  hintText:   'أدخل رقم الهاتف',
                  keyboardType:    TextInputType.phone,
                  textInputAction: TextInputAction.done,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}