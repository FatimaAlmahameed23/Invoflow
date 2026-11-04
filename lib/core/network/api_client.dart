import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_exception.dart';
import '../config/app_config.dart';

class ApiClient {
  Future<T> handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on FunctionException catch (e) {
      final data = _decodeErrorDetails(e.details);

      if (data is Map && data['error'] is Map) {
        final error = data['error'] as Map;

        throw ApiException(
          statusCode: e.status,
          code: error['code']?.toString() ?? 'API_ERROR',
          message: error['message']?.toString() ?? 'Request failed',
        );
      }

      throw ApiException(
        statusCode: e.status,
        code: 'API_ERROR_${e.status}',
        message: _functionErrorMessage(e, data),
      );
    } catch (e, stackTrace) {
      if (e is ApiException) rethrow;

      debugPrint('API request failed: $e\n$stackTrace');
      throw ApiException(code: 'REQUEST_ERROR', message: e.toString());
    }
  }

  dynamic _decodeErrorDetails(dynamic details) {
    if (details is! String) return details;

    try {
      return jsonDecode(details);
    } on FormatException {
      return details;
    }
  }

  String _functionErrorMessage(FunctionException exception, dynamic details) {
    if (details is Map && details['error'] is Map) {
      final error = details['error'] as Map;
      final message = error['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }

    if (details is String && details.isNotEmpty) return details;
    return exception.reasonPhrase ??
        'API request failed with status ${exception.status}.';
  }

  final SupabaseClient _supabase;

  ApiClient(this._supabase);

  String requireAccessToken() {
    final accessToken = _supabase.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException(
        statusCode: 401,
        code: 'SESSION_EXPIRED',
        message: 'Your session has expired. Please sign in again.',
      );
    }
    return accessToken;
  }

  Future<dynamic> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) {
    return handleRequest(() async {
      final response = await _supabase.functions.invoke(
        '${AppConfig.apiFunctionName}/$endpoint',
        method: HttpMethod.get,
        queryParameters: queryParameters,
      );

      return response.data;
    });
  }

  Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) {
    return handleRequest(() async {
      final response = await _supabase.functions.invoke(
        '${AppConfig.apiFunctionName}/$endpoint',
        method: HttpMethod.post,
        body: body,
        headers: headers,
      );

      return response.data;
    });
  }

  Future<dynamic> put(
    String endpoint, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
  }) {
    return handleRequest(() async {
      final response = await _supabase.functions.invoke(
        '${AppConfig.apiFunctionName}/$endpoint',
        method: HttpMethod.put,
        body: body,
        headers: headers,
      );

      return response.data;
    });
  }

  Future<dynamic> patch(String endpoint, {required Map<String, dynamic> body}) {
    return handleRequest(() async {
      final response = await _supabase.functions.invoke(
        '${AppConfig.apiFunctionName}/$endpoint',
        method: HttpMethod.patch,
        body: body,
      );

      return response.data;
    });
  }

  Future<dynamic> delete(
    String endpoint, {
    required Map<String, String> headers,
  }) {
    return handleRequest(() async {
      final response = await _supabase.functions.invoke(
        '${AppConfig.apiFunctionName}/$endpoint',
        method: HttpMethod.delete,
        body: null,
        headers: headers,
      );

      return response.data;
    });
  }
}
