// lib/features/customers/presentation/cubit/customers_state.dart
part of 'customers_cubit.dart';



final class CustomersState extends Equatable {
  final CustomersStatus status;
  final CustomerFormStatus formStatus;
  final List<CustomerEntity> customers;
  final List<CustomerEntity> filtered;
  final CustomerEntity? selectedCustomer;
  final String? errorMessage;
  final String searchQuery;
  final bool isFormOpen;
  final bool isEditMode;

  const CustomersState({
    this.status = CustomersStatus.initial,
    this.formStatus = CustomerFormStatus.idle,
    this.customers = const [],
    this.filtered = const [],
    this.selectedCustomer,
    this.errorMessage,
    this.searchQuery = '',
    this.isFormOpen = false,
    this.isEditMode = false,
  });

  CustomersState copyWith({
    CustomersStatus? status,
    CustomerFormStatus? formStatus,
    List<CustomerEntity>? customers,
    List<CustomerEntity>? filtered,
    CustomerEntity? selectedCustomer,
    String? errorMessage,
    String? searchQuery,
    bool? isFormOpen,
    bool? isEditMode,
    bool clearSelected = false,
    bool clearError = false,
  }) {
    return CustomersState(
      status: status ?? this.status,
      formStatus: formStatus ?? this.formStatus,
      customers: customers ?? this.customers,
      filtered: filtered ?? this.filtered,
      selectedCustomer:
      clearSelected ? null : selectedCustomer ?? this.selectedCustomer,
      errorMessage:
      clearError ? null : errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      isFormOpen: isFormOpen ?? this.isFormOpen,
      isEditMode: isEditMode ?? this.isEditMode,
    );
  }

  bool get isLoading => status == CustomersStatus.loading;
  bool get hasError => status == CustomersStatus.failure;
  bool get hasCustomers => filtered.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    formStatus,
    customers,
    filtered,
    selectedCustomer,
    errorMessage,
    searchQuery,
    isFormOpen,
    isEditMode,
  ];
}