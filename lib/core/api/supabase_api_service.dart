// lib/core/api/supabase_api_service.dart
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' hide HttpMethod;
import 'base_api_services.dart';
import 'endpoints.dart' show Endpoints;
import 'model/http_method.dart';

class SupabaseApiService extends BaseApiServices {
  final SupabaseClient _supabase;

  SupabaseApiService(this._supabase);

  @override
  Future<dynamic> request({
    required HttpMethod method,
    required String url,
    dynamic body,
    Map<String, Object>? queryParams,
    Map<String, String>? headers,
    String columns = '*',
    String? orderBy,
    bool ascending = false,
  }) async {
    try {
      final table = _supabase.from(url);
      var query;

      switch (method) {
        case HttpMethod.get:
          query = table.select(columns);
          if (queryParams?.isNotEmpty == true) query = query.match(queryParams!);
          if (orderBy != null) query = query.order(orderBy, ascending: ascending);
          return await query;

        case HttpMethod.post:
          return await table.insert(body).select(columns);

        case HttpMethod.put:
        case HttpMethod.patch:
          if (queryParams == null || queryParams.isEmpty) {
            throw ArgumentError('update requires queryParams to identify the row');
          }
          return await table.update(body).match(queryParams).select(columns);

        case HttpMethod.delete:
          if (queryParams == null || queryParams.isEmpty) {
            throw ArgumentError('delete requires queryParams to identify the row');
          }
          return await table.delete().match(queryParams).select();
      }
    } catch (e, stackTrace) {
      log('Supabase error [$method] table: $url', error: e, stackTrace: stackTrace);
      rethrow;
    }
  }

@override
Future<String> uploadFile({
  required String bucket,
  required String path,
  required File file,
}) async {
  try {
    final ext = file.path.split('.').last.toLowerCase();
    final bytes = await file.readAsBytes();
    final token = _supabase.auth.currentSession?.accessToken
        ?? Endpoints.anonKey;

    final uri = Uri.parse(
      '${Endpoints.storageUrl}/object/$bucket/$path',
    );

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'apikey': Endpoints.anonKey,
        'Content-Type': 'image/$ext',
        'x-upsert': 'true',
      },
      body: bytes,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return '${Endpoints.storageUrl}/object/public/$bucket/$path';
    }
    throw Exception('Upload failed: ${response.body}');
  } catch (e, st) {
    log('Storage error [uploadFile] bucket: $bucket', error: e, stackTrace: st);
    rethrow;
  }
}

  @override
  Future<void> upsert({
    required String url,
    required Map<String, dynamic> body,
  }) async {
    try {
      await _supabase.from(url).upsert(body);
    } catch (e, st) {
      log('Supabase error [upsert] table: $url', error: e, stackTrace: st);
      rethrow;
    }
  }
}