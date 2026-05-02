// lib/core/di/injection_container.dart

import 'package:bungee_manage_sys/features/alerts/data/datasources/alerts_remote_datasource.dart';
import 'package:bungee_manage_sys/features/alerts/data/repositories/alerts_repository_impl.dart';
import 'package:bungee_manage_sys/features/alerts/domain/repositories/alerts_repository.dart';
import 'package:bungee_manage_sys/features/alerts/domain/usecases/dismiss_alert_usecase.dart';
import 'package:bungee_manage_sys/features/alerts/domain/usecases/get_alerts_usecase.dart';
import 'package:bungee_manage_sys/features/alerts/presentation/cubit/alerts_cubit.dart';
import 'package:bungee_manage_sys/features/all_invoices/data/datasources/all_invoices_remote_datasource.dart';
import 'package:bungee_manage_sys/features/all_invoices/data/repositories/all_invoices_repository_impl.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/repositories/all_invoices_repository.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/usecases/get_all_invoices_usecase.dart';
import 'package:bungee_manage_sys/features/all_invoices/pagination/presentation/cubit/all_invoices_cubit.dart';
import 'package:bungee_manage_sys/features/auth/presentation/cubit/login_cubit.dart';
import 'package:bungee_manage_sys/features/customers/data/datasources/customers_remote_datasource.dart';
import 'package:bungee_manage_sys/features/customers/data/datasources/invoices_remote_datasource.dart';
import 'package:bungee_manage_sys/features/customers/data/repositories/customers_repository_impl.dart';
import 'package:bungee_manage_sys/features/customers/data/repositories/invoices_repository_impl.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/customers_repository.dart';
import 'package:bungee_manage_sys/features/customers/domain/repositories/invoices_repository.dart';
import 'package:bungee_manage_sys/features/customers/domain/usecases/create_invoice_with_payment_usecase.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:bungee_manage_sys/features/customers/presentation/cubit/invoices_cubit.dart';
import 'package:bungee_manage_sys/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:bungee_manage_sys/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:bungee_manage_sys/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:bungee_manage_sys/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:bungee_manage_sys/features/finance/data/datasources/finance_remote_datasource.dart';
import 'package:bungee_manage_sys/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:bungee_manage_sys/features/finance/domain/repositories/finance_repository.dart';
import 'package:bungee_manage_sys/features/finance/presentation/cubit/finance_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:bungee_manage_sys/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:bungee_manage_sys/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/inventory_cubit.dart';
import 'package:bungee_manage_sys/features/inventory/presentation/cubit/item_form_cubit.dart';
import 'package:bungee_manage_sys/features/suppliers/data/datasources/suppliers_remote_datasource.dart';
import 'package:bungee_manage_sys/features/suppliers/data/repositories/suppliers_repository_impl.dart';
import 'package:bungee_manage_sys/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:bungee_manage_sys/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bungee_manage_sys/core/api/base_api_services.dart';
import 'package:bungee_manage_sys/core/api/supabase_api_service.dart';
import 'package:bungee_manage_sys/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:bungee_manage_sys/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:bungee_manage_sys/features/auth/domain/repositories/auth_repository.dart';
import 'package:bungee_manage_sys/features/user_data/user_repo.dart';

final sl = GetIt.instance;

Future<void> init() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  _setUpSubaBase();
  _setUpAuth();
  _setUpDashboard();
  _setUpInventory();
  _setUpCustomers();
  _setUpSuppliers();
  _setUpInvoices();
  _setUpFinance();
  _setUpAlerts();
  _all_invoices();

  sl.registerLazySingleton(() => UserRepository());
}

void _setUpSubaBase() {
  sl.registerLazySingleton<SupabaseClient>(
        () => Supabase.instance.client,
  );
  sl.registerLazySingleton<BaseApiServices>(() => SupabaseApiService(sl()));
}

void _setUpAuth() {
  sl.registerFactory(() => LoginCubit(sl<AuthRepository>()));

  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(sl<AuthRemoteDataSource>()),
  );
}

void _setUpDashboard() {
  sl.registerFactory(() => DashboardCubit(sl<DashboardRepository>()));

  sl.registerLazySingleton<DashboardRemoteDataSource>(
        () => DashboardRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<DashboardRepository>(
        () => DashboardRepositoryImpl(sl<DashboardRemoteDataSource>()),
  );
}

void _setUpInventory() {
  sl.registerFactory(() => InventoryCubit(sl<InventoryRepository>()));
  sl.registerLazySingleton<InventoryRemoteDataSource>(
        () => InventoryRemoteDataSourceImpl(sl<BaseApiServices>()),
  );
  sl.registerLazySingleton<InventoryRepository>(
        () => InventoryRepositoryImpl(sl<InventoryRemoteDataSource>()),
  );
  sl.registerFactory(() => ItemFormCubit(sl<InventoryRepository>()));
}

void _setUpCustomers() {
  // ─── Customers ────────────────────────────────────────────────────────
  sl.registerLazySingleton<CustomersRemoteDataSource>(
        () => CustomersRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  sl.registerLazySingleton<CustomersRepository>(
        () => CustomersRepositoryImpl(sl<CustomersRemoteDataSource>()),
  );

  sl.registerFactory(() => CustomersCubit(sl<CustomersRepository>()));
}

void _setUpInvoices() {
  // ─── Data Sources ─────────────────────────────────────────────────────
  sl.registerLazySingleton<InvoicesRemoteDataSource>(
        () => InvoicesRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // ─── Repositories ─────────────────────────────────────────────────────
  sl.registerLazySingleton<InvoicesRepository>(
        () => InvoicesRepositoryImpl(sl<InvoicesRemoteDataSource>()),
  );

  // ─── Use Cases ────────────────────────────────────────────────────────
  sl.registerLazySingleton(
        () => CreateInvoiceWithPaymentUseCase(sl<InvoicesRepository>()),
  );

  // ─── Cubit ────────────────────────────────────────────────────────────
  sl.registerFactory(() => InvoicesCubit(
        sl<InvoicesRepository>(),
  ));
}

void _setUpSuppliers() {
  sl.registerFactory(() => SuppliersCubit(sl<SuppliersRepository>()));
  sl.registerLazySingleton<SuppliersRemoteDataSource>(
        () => SuppliersRemoteDataSourceImpl(sl<SupabaseClient>()),
  );
  sl.registerLazySingleton<SuppliersRepository>(
        () => SuppliersRepositoryImpl(sl<SuppliersRemoteDataSource>()),
  );
}

void _setUpFinance() {
  // ─── Data Sources ─────────────────────────────────────────────────────
  sl.registerLazySingleton<FinanceRemoteDataSource>(
        () => FinanceRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // ─── Repositories ─────────────────────────────────────────────────────
  sl.registerLazySingleton<FinanceRepository>(
        () => FinanceRepositoryImpl(sl<FinanceRemoteDataSource>()),
  );

  // ─── Cubit ────────────────────────────────────────────────────────────
  sl.registerFactory(() => FinanceCubit(sl<FinanceRepository>()));
}

void _setUpAlerts() {
  // Data Source
  sl.registerLazySingleton<AlertsRemoteDataSource>(
        () => AlertsRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repository
  sl.registerLazySingleton<AlertsRepository>(
        () => AlertsRepositoryImpl(sl<AlertsRemoteDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAlertsUseCase(sl<AlertsRepository>()));
  sl.registerLazySingleton(() => DismissAlertUseCase(sl<AlertsRepository>()));

  // Cubit
  sl.registerFactory(() => AlertsCubit(
    sl<GetAlertsUseCase>(),
    sl<DismissAlertUseCase>(),
  ));
}

void _all_invoices() {
  // Data Source
  sl.registerLazySingleton<AllInvoicesRemoteDataSource>(
        () => AllInvoicesRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repository
  sl.registerLazySingleton<AllInvoicesRepository>(
        () => AllInvoicesRepositoryImpl(sl<AllInvoicesRemoteDataSource>()),
  );

  // Use Cases
  sl.registerLazySingleton(() => GetAllInvoicesUseCase(sl<AllInvoicesRepository>()));


  // Cubit
  sl.registerFactory(() => AllInvoicesCubit(
    sl<GetAllInvoicesUseCase>(),
  ));
}