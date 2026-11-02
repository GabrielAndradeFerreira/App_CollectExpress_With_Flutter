import 'dart:convert';

import 'package:dio/dio.dart';

/// Erro único para qualquer falha ao falar com a API.
///
/// As telas só precisam mostrar [message]. [fields] traz os erros de
/// validação por campo (ex.: `{'email': 'Email já cadastrado'}`).
class ApiException implements Exception {
  final String message;

  /// `null` quando a requisição nem chegou à API (sem rede, timeout...).
  final int? statusCode;

  /// Código de erro da API (ex.: `USER_INACTIVE`), quando ela envia.
  final String? code;

  final Map<String, String> fields;

  const ApiException(
    this.message, {
    this.statusCode,
    this.code,
    this.fields = const {},
  });

  static const _defaultMessage = 'Não foi possível concluir a solicitação.';

  bool get isUnauthorized => statusCode == 401;

  bool get isNetworkError => statusCode == null;

  factory ApiException.fromDioException(DioException error) {
    final cause = error.error;
    if (cause is ApiException) return cause;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'A solicitação demorou muito. Tente novamente.',
        );
      case DioExceptionType.badResponse:
        return ApiException.fromResponse(
          error.response?.statusCode,
          error.response?.data,
        );
      case DioExceptionType.cancel:
        return const ApiException('A solicitação foi cancelada.');
      default:
        return const ApiException('Não foi possível conectar ao servidor.');
    }
  }

  /// Lê os dois formatos de erro da API:
  /// - novo: `{success: false, message, code, fields: {campo: mensagem}}`
  /// - antigo: `{error}` ou `{errors: [{campo, mensagem}]}`
  factory ApiException.fromResponse(int? statusCode, dynamic body) {
    // Downloads (ResponseType.bytes) trazem o erro JSON como bytes.
    if (body is List<int>) {
      try {
        body = jsonDecode(utf8.decode(body));
      } on FormatException {
        body = null;
      }
    }

    final Map json = body is Map ? body : const {};
    final fields = <String, String>{};

    final rawFields = json['fields'];
    if (rawFields is Map) {
      rawFields.forEach((field, message) => fields['$field'] = '$message');
    }

    final errors = json['errors'];
    if (errors is List) {
      for (final error in errors) {
        if (error is Map && error['campo'] != null) {
          fields['${error['campo']}'] = '${error['mensagem']}';
        }
      }
    }

    final message =
        json['message']?.toString() ??
        json['error']?.toString() ??
        (fields.isNotEmpty ? fields.values.first : _defaultMessage);

    return ApiException(
      message,
      statusCode: statusCode,
      code: json['code']?.toString(),
      fields: fields,
    );
  }

  @override
  String toString() => message;
}
