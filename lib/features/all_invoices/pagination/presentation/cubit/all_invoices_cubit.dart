// lib/features/all_invoices/presentation/cubit/all_invoices_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/entities/all_invoices_entity.dart';
import 'package:bungee_manage_sys/features/all_invoices/domain/usecases/get_all_invoices_usecase.dart';
import 'package:equatable/equatable.dart';

part 'all_invoices_state.dart';

class AllInvoicesCubit extends Cubit<AllInvoicesState> {
  final GetAllInvoicesUseCase _getAllInvoicesUseCase;

  static const int _defaultPageSize = 10;

  AllInvoicesCubit(this._getAllInvoicesUseCase) : super(AllInvoicesInitial());

  // ── Load first page (or reload with new filters) ─────────────────────────

  Future<void> loadInvoices({
    InvoiceFilterParams? filters,
  }) async {
    final activeFilters = filters ?? const InvoiceFilterParams();

    emit(AllInvoicesLoading());

    final result = await _getAllInvoicesUseCase(
      GetAllInvoicesParams(
        filters:  activeFilters,
        page:     1,
        pageSize: _defaultPageSize,
      ),
    );

    result.fold(
      (failure) => emit(AllInvoicesError(failure.message)),
      (paginated) => emit(AllInvoicesLoaded(
        invoices:    paginated.invoices,
        totalCount:  paginated.totalCount,
        currentPage: paginated.currentPage,
        pageSize:    paginated.pageSize,
        filters:     activeFilters,
      )),
    );
  }

  // ── Go to specific page ───────────────────────────────────────────────────

  Future<void> goToPage(int page) async {
    final current = state;
    if (current is! AllInvoicesLoaded) return;
    if (page < 1 || page > current.totalPages) return;

    // Show paginating state (keeps current list visible)
    emit(AllInvoicesPaginating(
      currentInvoices: current.invoices,
      currentPage:     current.currentPage,
      totalCount:      current.totalCount,
      filters:         current.filters,
    ));

    final result = await _getAllInvoicesUseCase(
      GetAllInvoicesParams(
        filters:  current.filters,
        page:     page,
        pageSize: current.pageSize,
      ),
    );

    result.fold(
      (failure) => emit(AllInvoicesError(failure.message)),
      (paginated) => emit(AllInvoicesLoaded(
        invoices:    paginated.invoices,
        totalCount:  paginated.totalCount,
        currentPage: paginated.currentPage,
        pageSize:    paginated.pageSize,
        filters:     current.filters,
      )),
    );
  }

  // ── Next / previous helpers ───────────────────────────────────────────────

  Future<void> nextPage() async {
    final current = state;
    if (current is! AllInvoicesLoaded) return;
    if (!current.hasNextPage) return;
    await goToPage(current.currentPage + 1);
  }

  Future<void> previousPage() async {
    final current = state;
    if (current is! AllInvoicesLoaded) return;
    if (!current.hasPreviousPage) return;
    await goToPage(current.currentPage - 1);
  }

  // ── Apply / clear filters ─────────────────────────────────────────────────

  Future<void> applyFilters(InvoiceFilterParams filters) async {
    await loadInvoices(filters: filters);
  }

  Future<void> clearFilters() async {
    await loadInvoices(filters: const InvoiceFilterParams());
  }

  // ── Update search query (debounce handled by the UI layer) ────────────────

  Future<void> search(String query) async {
    final current = state;
    final currentFilters = current is AllInvoicesLoaded
        ? current.filters
        : const InvoiceFilterParams();

    await loadInvoices(
      filters: currentFilters.copyWith(searchQuery: query),
    );
  }


  // ── Fetch all for Export ──────────────────────────────────────────────────
  /// ميثود مخصصة لجلب البيانات لغرض التصدير فقط دون التأثير على ما يعرض في الشاشة
  Future<List<AllInvoiceEntity>> fetchAllForExport({
    required InvoiceStatusFilter statusFilter,
    required PaymentStatusFilter paymentFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    // جلب نص البحث الحالي لو موجود في الـ State عشان التصدير يكون دقيق
    String? currentSearch;
    if (state is AllInvoicesLoaded) {
      currentSearch = (state as AllInvoicesLoaded).filters.searchQuery;
    }

    // تجهيز البارامترز بناءً على اختيارات المستخدم من الـ Dialog
    final exportParams = GetAllInvoicesParams(
      filters: InvoiceFilterParams(
        statusFilter: statusFilter,
        paymentFilter: paymentFilter,
        startDate: startDate,
        endDate: endDate,
        searchQuery: currentSearch ?? '',
      ),
      page: 1,
      pageSize: 2000, // نضع رقم كبير لضمان جلب كافة السجلات المفلترة في طلب واحد
    );

    final result = await _getAllInvoicesUseCase(exportParams);

    return result.fold(
          (failure) => throw Exception(failure.message),
          (paginated) => paginated.invoices,
    );
  }
}
