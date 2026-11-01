import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_exception.dart';
import '../config/app_config.dart';

class ApiClient {
  Future<T> handleRequest<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on FunctionException catch (e) {
      final data = e.details;

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
        code: 'API_ERROR',
        message: e.reasonPhrase ?? 'Request failed',
      );
    } catch (e) {
      if (e is ApiException) rethrow;

      throw ApiException(
        code: 'NETWORK_ERROR',
        message: 'Something went wrong. Please try again.',
      );
    }
  }

  final SupabaseClient _supabase;

  ApiClient(this._supabase);

  Future<dynamic> get(String endpoint) {
    return handleRequest(() async {
      final response = await _supabase.functions.invoke(
        '${AppConfig.apiFunctionName}/$endpoint',
        method: HttpMethod.get,
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
}
