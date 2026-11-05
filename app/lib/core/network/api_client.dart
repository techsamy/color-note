import 'package:dio/dio.dart';

/// Error from the API envelope `{error: {code, message, fields}}`
/// (docs/05 §1), or `NETWORK` when the server wasn't reached.
final class ApiException implements Exception {
  const new({
    required this.code,
    required this.message,
    this.status,
    this.fields = const {},
  });

  final String code;
  final String message;
  final int? status;
  final Map<String, List<String>> fields;

  bool get isNetwork => code == 'NETWORK';

  String? firstFieldError() =>
      fields.values.expand((e) => e).firstOrNull ??
      (isNetwork ? null : message);

  @override
  String toString() => 'ApiException($status $code: $message)';
}

/// Thin JSON client: auth + device headers, error mapping. No retries here;
/// the sync engine decides when to try again.
class ApiClient {
  new({
    required String baseUrl,
    required this._token,
    required String deviceId,
    required String appVersion,
    HttpClientAdapter? adapter,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 10),
           receiveTimeout: const Duration(seconds: 30),
           headers: {
             'Accept': 'application/json',
             'X-Device-Id': deviceId,
             'X-App-Version': appVersion,
           },
         ),
       ) {
    if (adapter != null) _dio.httpClientAdapter = adapter;
  }

  final Dio _dio;
  final Future<String?> Function() _token;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
  }) => _send('GET', path, query: query);

  Future<Map<String, dynamic>> post(String path, [Object? body]) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> put(String path, [Object? body]) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> patch(String path, [Object? body]) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> delete(String path, [Object? body]) =>
      _send('DELETE', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
  }) async {
    final token = await _token();
    try {
      final res = await _dio.request<Object?>(
        path,
        data: body,
        queryParameters: query,
        options: Options(
          method: method,
          headers: {'Authorization': ?(token == null ? null : 'Bearer $token')},
        ),
      );
      final data = res.data;
      return data is Map<String, dynamic> ? data : const {};
    } on DioException catch (e) {
      throw _map(e);
    }
  }

  static ApiException _map(DioException e) {
    final res = e.response;
    if (res == null) {
      return ApiException(
        code: 'NETWORK',
        message: e.message ?? 'Network error',
      );
    }
    final body = res.data;
    final error = body is Map<String, dynamic> ? body['error'] : null;
    if (error is Map<String, dynamic>) {
      final rawFields = error['fields'];
      return ApiException(
        status: res.statusCode,
        code: error['code'] as String? ?? 'HTTP_ERROR',
        message: error['message'] as String? ?? 'Error',
        fields: rawFields is Map<String, dynamic>
            ? {
                for (final e in rawFields.entries)
                  e.key: [for (final m in e.value as List<dynamic>) '$m'],
              }
            : const {},
      );
    }
    return ApiException(
      status: res.statusCode,
      code: 'HTTP_ERROR',
      message: 'HTTP ${res.statusCode}',
    );
  }
}
