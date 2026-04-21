// lib/core/api/base_api_services.dart
import 'dart:io';
import 'model/http_method.dart';

abstract class BaseApiServices {
  Future<dynamic> request({
    required HttpMethod method,
    required String url,
    dynamic body,
    Map<String, Object>? queryParams,
    Map<String, String>? headers,
    String columns = '*',
    String? orderBy,
    bool ascending = false,
  });

  Future<void> upsert({
    required String url,
    required Map<String, dynamic> body,
  });

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
  });
}