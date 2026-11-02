import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'api_config.dart';
import 'api_exception.dart';
import 'api_response.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'token_storage.dart';

/// Cliente HTTP único do app para a CollectExpressAPI.
///
/// Os métodos devolvem o conteúdo de `data` da resposta e lançam
/// [ApiException] em qualquer erro. Use pelo `apiClientProvider`.
class ApiClient {
  ApiClient({
    required TokenStorage storage,
    String? baseUrl,
    HttpClientAdapter? adapter,
  }) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    );

    final refreshClient = Dio(options.copyWith());
    _dio = Dio(options);

    if (adapter != null) {
      _dio.httpClientAdapter = adapter;
      refreshClient.httpClientAdapter = adapter;
    }

    _dio.interceptors.addAll([
      AuthInterceptor(
        storage: storage,
        refreshClient: refreshClient,
        onSessionExpired: () => _sessionExpired.add(null),
      ),
      ErrorInterceptor(),
    ]);
  }

  late final Dio _dio;
  final _sessionExpired = StreamController<void>.broadcast();

  /// Emite quando o token expirou e não foi possível renovar a sessão.
  /// Os tokens já foram apagados; o app deve voltar para o login.
  Stream<void> get sessionExpired => _sessionExpired.stream;

  /// [auth] = false para rotas públicas que não devem levar o token.
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) {
    return _send('GET', path, query: query, auth: auth);
  }

  /// Baixa um arquivo que exige login (ex.: PDF do contrato) e devolve
  /// os bytes. Lança [ApiException] como os outros métodos.
  Future<Uint8List> getBytes(String path) async {
    try {
      final response = await _dio.get<List<int>>(
        path,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': '*/*'},
        ),
      );

      return Uint8List.fromList(response.data ?? const []);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  Future<dynamic> post(String path, {Object? data, bool auth = true}) {
    return _send('POST', path, data: data, auth: auth);
  }

  Future<dynamic> put(String path, {Object? data}) {
    return _send('PUT', path, data: data);
  }

  Future<dynamic> patch(String path, {Object? data}) {
    return _send('PATCH', path, data: data);
  }

  Future<dynamic> delete(String path, {Object? data}) {
    return _send('DELETE', path, data: data);
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? query,
    bool auth = true,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: query,
        options: Options(
          method: method,
          extra: {if (!auth) AuthInterceptor.skipAuth: true},
        ),
      );

      return unwrapData(response.data);
    } on DioException catch (error) {
      throw ApiException.fromDioException(error);
    }
  }

  void dispose() {
    _dio.close();
    _sessionExpired.close();
  }
}
