// lib/features/auth/presentation/pages/login_page.dart
import 'dart:developer';

import 'package:bungee_manage_sys/core/utils/assets.dart';
import 'package:bungee_manage_sys/core/widgets/app_buton.dart';
import 'package:bungee_manage_sys/core/widgets/app_text_feild.dart';
import 'package:bungee_manage_sys/core/widgets/custom_lottie_icon.dart';
import 'package:bungee_manage_sys/core/widgets/custom_network_image.dart';
import 'package:bungee_manage_sys/core/widgets/custom_snack_bar.dart';
import 'package:bungee_manage_sys/core/widgets/responsive_layout.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:bungee_manage_sys/core/di/injection_container.dart' as sl;
import 'package:bungee_manage_sys/core/routes/routes.dart';
import 'package:bungee_manage_sys/core/theme/colors.dart';
import 'package:bungee_manage_sys/features/auth/presentation/cubit/login_cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginCubit(sl.sl()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<LoginCubit>().login(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LoginCubit, LoginState>(
        listener: (context, state) {
          if (state is LoginError) {
            log(state.message,);
            context.showError(
              state.message,
              actionLabel: 'common.retry'.tr(),
              onAction: () => _submit(),
            );
          }
          if (state is LoginSuccess) {
            context.showSuccess('auth.loginSuccess'.tr());
            Navigator.of(context).pushReplacementNamed(Routes.dashBoard);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          final form = _LoginForm(
            formKey: _formKey,
            emailController: _emailController,
            passwordController: _passwordController,
            isLoading: isLoading,
            onSubmit: _submit,
          );

          return ResponsiveLayout(
            mobile: _MobileShell(form: form),
            desktop: _DesktopShell(form: form),
          );
        },
      ),
    );
  }
}

// ─── Desktop shell ──────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Container(
            decoration: const BoxDecoration(
              color: ColorsManager.primaryColor,
              image: DecorationImage(
                image: AssetImage(Assets.appBg),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 56.w, vertical: 40.h),
              child: Column(
                children: [
                  CustomLottieIcon(
                    assetPath: Assets.cameraLotti,
                    width: 200.w,
                    height: 200.w,
                    repeat: true,
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: form,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Mobile shell ───────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.form});
  final Widget form;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                SizedBox(height: 56.h),
                // ✅ استبدلنا الـ Container باللوجو بـ Lottie
                CustomLottieIcon(
                  assetPath: Assets.cameraLotti,
                  width: 120.w,
                  height: 120.w,
                  repeat: true,
                ),
                SizedBox(height: 24.h),
                Text('auth.welcome'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center),
                SizedBox(height: 6.h),
                Text('auth.loginSubtitle'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center),
                SizedBox(height: 40.h),
                form,
                SizedBox(height: 48.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared form ────────────────────────────────────────────────────────────

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSubmit,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextFieldFactory.email(
            controller: emailController,
            hintText: 'auth.emailHint'.tr(),
            title: 'auth.email'.tr(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'validation.emailRequired'.tr();
              }
              if (!v.contains('@')) return 'validation.emailInvalid'.tr();
              return null;
            },
          ),
          SizedBox(height: 16.h),
          AppTextFieldFactory.password(
            controller: passwordController,
            hintText: 'auth.passwordHint'.tr(),
            title: 'auth.password'.tr(),
            validator: (v) {
              if (v == null || v.isEmpty) {
                return 'validation.passwordRequired'.tr();
              }
              if (v.length < 6) return 'validation.passwordMinLength'.tr();
              return null;
            },
          ),
          SizedBox(height: 32.h),
          AppButton(
            text: 'auth.login'.tr(),
            isLoading: isLoading,
            active: !isLoading,
            onPressed: onSubmit,
            horizontalPadding: 0,
          ),
        ],
      ),
    );
  }
}