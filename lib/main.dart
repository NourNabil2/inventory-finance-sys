// lib/main.dart
import 'package:bungee_manage_sys/features/user_data/user_cubit.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/injection_container.dart' as sl;
import 'core/routes/app_routes.dart';
import 'core/routes/routes.dart';
import 'core/service/app_initializer.dart';
import 'core/theme/app_theme.dart';
import 'features/user_data/user_repo.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Init (Supabase → languages → DI) ────────────────────
  await AppInitializer.init();

  // ── Restore user session from secure storage ─────────────
  await UserRepository().loadUser();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 600;
    return MultiBlocProvider(
      providers: [
        // ── Global: current user ──────────────────────────────
        BlocProvider<UserCubit>(
          create: (_) => UserCubit(sl.sl<UserRepository>()),
        ),
        // ── Global: theme + language ──────────────────────────
      //   BlocProvider<SettingsCubit>(
      //     create: (_) => SettingsCubit()..loadSettings(),
      //   ),
       ],
     child: ScreenUtilInit(
       designSize: isDesktop ? const Size(1440, 900) : const Size(375, 812),
       minTextAdapt: true,
       splitScreenMode: true,
       builder: (context, child) {
         return MaterialApp(
           navigatorKey: AppRouter.navigatorKey,
           theme: AppTheme.light,
           darkTheme: AppTheme.dark,
           themeMode: ThemeMode.dark,
           localizationsDelegates: context.localizationDelegates,
           supportedLocales: context.supportedLocales,
           locale: context.locale,
           initialRoute:
           UserRepository().currentUser != null ? Routes.dashBoard : Routes.auth,
           onGenerateRoute: AppRouter.onGenerateRoute,
         );
       },
     )
    );

  }
}

// child: BlocBuilder<SettingsCubit, SettingsState>(
// buildWhen: (prev, curr) => prev.themeMode != curr.themeMode,
// builder: (context, settings) {
// return ScreenUtilInit(
// designSize: const Size(375, 812),
// minTextAdapt: true,
// splitScreenMode: true,
// builder: (context, child) {
// return MaterialApp(
// navigatorKey: AppRouter.navigatorKey,
// theme: AppTheme.light,
// darkTheme: AppTheme.dark,
// themeMode: settings.themeMode,
// localizationsDelegates: context.localizationDelegates,
// supportedLocales: context.supportedLocales,
// locale: context.locale,
// initialRoute: UserRepository().isLoggedIn
// ? Routes.dashBoard
//     : Routes.auth,
// onGenerateRoute: AppRouter.onGenerateRoute,
// );
// },
// );
// },
// ),