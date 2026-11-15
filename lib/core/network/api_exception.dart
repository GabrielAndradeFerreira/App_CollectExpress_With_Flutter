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

  /// Nomes de campo da API como a pessoa entende, para a mensagem de
  /// "Dados inválidos" dizer o que conferir.
  static const _rotulosDosCampos = {
    'endereco_id': 'endereço',
    'data_inicio': 'data de início',
    'assinatura_base64': 'assinatura',
    'aceite_termos': 'aceite dos termos',
    'nome_completo': 'nome',
    'email': 'e-mail',
    'senha': 'senha',
    'telefone': 'telefone',
    'documento': 'documento',
    'cep': 'CEP',
    'logradouro': 'rua',
    'numero': 'número',
    'bairro': 'bairro',
    'cidade_estado': 'cidade',
    'horario_inicio': 'horário de abertura',
    'horario_fim': 'horário de fechamento',
    'taxa_entrega': 'taxa de entrega',
    'quantidade': 'quantidade',
    'dias_aluguel': 'dias de aluguel',
    'cacamba_id': 'caçamba',
    'descricao': 'descrição',
    'quantidade_estimada': 'quantidade estimada',
    'materiais_ids': 'materiais',
    'janela_inicio': 'início da janela',
    'janela_fim': 'fim da janela',
    'data_agendada': 'data da retirada',
    'responsavel_nome': 'responsável',
    'endereco_coleta': 'endereço da empresa',
    'texto': 'mensagem',
  };

  /// Diz quais campos conferir, no lugar de só "Dados inválidos". Com um
  /// campo só, mostra a mensagem dele; sem campos, devolve [message].
  static String _mensagemDeValidacao(
    String message,
    Map<String, String> fields,
  ) {
    if (fields.isEmpty) return message;

    String rotulo(String campo) => _rotulosDosCampos[campo] ?? campo;

    if (fields.length == 1) {
      final entrada = fields.entries.first;

      // A API cita o campo entre aspas simples: troca pelo nome amigável.
      return entrada.value.replaceAll(
        "'${entrada.key}'",
        "'${rotulo(entrada.key)}'",
      );
    }

    return '$message Confira: ${fields.keys.map(rotulo).join(', ')}.';
  }

  /// Mensagem para respostas sem texto da API (ex.: página de erro do
  /// servidor ou do proxy).
  static String _mensagemPorStatus(int? statusCode) {
    return switch (statusCode) {
      429 =>
        'Muitas solicitações em pouco tempo. Aguarde um instante e tente '
            'de novo.',
      502 || 503 || 504 =>
        'O servidor está indisponível no momento. Tente novamente em '
            'instantes.',
      final int status when status >= 500 =>
        'O servidor encontrou um problema. Tente novamente em instantes.',
      _ => _defaultMessage,
    };
  }

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

    final code = json['code']?.toString();
    final apiMessage = json['message']?.toString() ?? json['error']?.toString();

    final String message;

    if (apiMessage == null) {
      message = fields.isNotEmpty
          ? fields.values.first
          : _mensagemPorStatus(statusCode);
    } else if (code == 'VALIDATION_ERROR' && fields.isNotEmpty) {
      message = _mensagemDeValidacao(apiMessage, fields);
    } else {
      message = apiMessage;
    }

    return ApiException(
      message,
      statusCode: statusCode,
      code: code,
      fields: fields,
    );
  }

  @override
  String toString() => message;
}
