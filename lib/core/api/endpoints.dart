// lib/core/constants/endpoints.dart

class Endpoints {
  static const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const storageUrl = '$url/storage/v1';

  // ── Tables ──────────────────────────────────────────────
  static const items           = 'items';
  static const itemCategories  = 'item_categories';
  static const invoices        = 'invoices';
  static const invoiceItems    = 'invoice_items';
  static const customers       = 'customers';
  static const suppliers       = 'suppliers';
  static const checks          = 'checks';
  static const users           = 'users';
  static const transactions    = 'financial_transactions';

  // ── Storage Buckets ─────────────────────────────────────
  static const itemImagesBucket = 'item-images';
  static const itemImagesPath   = 'items';
}