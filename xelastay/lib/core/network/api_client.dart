import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.code,
    required this.message,
  });

  final int statusCode;
  final String code;
  final String message;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({String? baseUrl, http.Client? client})
    : baseUrl = (baseUrl ?? _defaultBaseUrl).replaceFirst(RegExp(r'/$'), ''),
      _client = client ?? http.Client();

  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static final String _defaultBaseUrl = _configuredBaseUrl.isNotEmpty
      ? _configuredBaseUrl
      : kDebugMode
      ? (kIsWeb
            ? 'http://127.0.0.1:3000/api/v1'
            : defaultTargetPlatform == TargetPlatform.android
            ? 'http://10.0.2.2:3000/api/v1'
            : 'http://127.0.0.1:3000/api/v1')
      : throw StateError('Configura API_BASE_URL para builds de producción.');

  final String baseUrl;
  final http.Client _client;

  Future<Map<String, dynamic>> get(String path, {String? token}) =>
      _send('GET', path, token: token);

  Future<Map<String, dynamic>> post(
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) => _send('POST', path, token: token, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.Request(method, uri)
      ..headers['Accept'] = 'application/json';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 15));
      final response = await http.Response.fromStream(streamedResponse)
          .timeout(const Duration(seconds: 20));
      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          throw ApiException(
            statusCode: response.statusCode,
            code: error['code']?.toString() ?? 'REQUEST_FAILED',
            message:
                error['message']?.toString() ??
                'No se pudo completar la solicitud.',
          );
        }
        throw ApiException(
          statusCode: response.statusCode,
          code: 'REQUEST_FAILED',
          message:
              decoded['message']?.toString() ??
              'No se pudo completar la solicitud.',
        );
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        code: 'TIMEOUT',
        message:
            'La solicitud tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK_UNAVAILABLE',
        message: 'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        code: 'INVALID_RESPONSE',
        message: 'No pudimos leer la información. Inténtalo de nuevo.',
      );
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('API request failed: $error\n$stackTrace');
      }
      rethrow;
    }
  }
}
