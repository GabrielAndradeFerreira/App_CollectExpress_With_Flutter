import 'package:dio/dio.dart';

/// Repete consultas (GET) que falharam por motivo passageiro: servidor
/// acordando (o plano gratuito do Render hiberna), queda curta de rede ou
/// resposta 502/503/504. Só GET: repetir um POST poderia duplicar um
/// pedido ou uma mensagem.
class RetryInterceptor extends Interceptor {
  RetryInterceptor({
    required this._dio,
    required this._atrasos,
    Future<void> Function(Duration)? esperar,
  }) : _esperar = esperar ?? Future<void>.delayed;

  final Dio _dio;

  /// Espera antes de cada nova tentativa; o tamanho da lista é o número
  /// de tentativas extras.
  final List<Duration> _atrasos;

  final Future<void> Function(Duration) _esperar;

  static const _tentativa = 'retryTentativa';

  static bool _passageiro(DioException erro) {
    switch (erro.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return true;
      case DioExceptionType.badResponse:
        final status = erro.response?.statusCode;
        return status == 502 || status == 503 || status == 504;
      default:
        return false;
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final opcoes = err.requestOptions;
    final tentativa = (opcoes.extra[_tentativa] as int?) ?? 0;

    if (opcoes.method.toUpperCase() != 'GET' ||
        tentativa >= _atrasos.length ||
        !_passageiro(err)) {
      return handler.next(err);
    }

    await _esperar(_atrasos[tentativa]);

    opcoes.extra[_tentativa] = tentativa + 1;

    try {
      handler.resolve(await _dio.fetch<dynamic>(opcoes));
    } on DioException catch (novoErro) {
      handler.next(novoErro);
    }
  }
}
