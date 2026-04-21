// lib/core/utils/validators.dart
import 'package:easy_localization/easy_localization.dart';

class Validators {
  // ── Auth ──────────────────────────────────────────────────

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.nameRequired'.tr();
    }
    if (value.trim().length < 2) return 'validation.nameTooShort'.tr();
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.emailRequired'.tr();
    }
    if (!RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(value.trim())) {
      return 'validation.emailInvalid'.tr();
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.phoneRequired'.tr();
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'validation.passwordRequired'.tr();
    }
    if (value.length < 6) return 'validation.passwordMinLength'.tr();
    return null;
  }

  static String? Function(String?) validateConfirmPassword(
      String? Function() getPassword,
      ) {
    return (value) {
      if (value != getPassword()) return 'validation.passwordMismatch'.tr();
      return null;
    };
  }

  // ── General ───────────────────────────────────────────────

  static String? validateRequired(String? value, {String? fieldKey}) {
    if (value == null || value.trim().isEmpty) {
      return fieldKey != null
          ? 'validation.fieldRequired'.tr(args: [fieldKey.tr()])
          : 'validation.required'.tr();
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) return 'validation.ageRequired'.tr();
    final age = int.tryParse(value);
    if (age == null || age < 1 || age > 120) {
      return 'validation.ageInvalid'.tr();
    }
    return null;
  }

  static String? validatePositiveNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.required'.tr();
    }
    final n = num.tryParse(value.trim());
    if (n == null || n <= 0) return 'validation.positiveNumberRequired'.tr();
    return null;
  }

  static String? validateNonNegativeNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'validation.required'.tr();
    }
    final n = num.tryParse(value.trim());
    if (n == null || n < 0) return 'validation.nonNegativeRequired'.tr();
    return null;
  }
}