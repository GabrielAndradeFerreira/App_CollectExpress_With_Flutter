import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../network/api_providers.dart';

/// Envia à API (`POST /logs/app`) os erros que só o app enxerga: queda de
/// rede, timeout, exceção em tela. A API grava em `logs_erros`.
///
/// Nunca lança erro e nunca bloqueia a tela: se o envio falhar, o relato
/// é descartado.
final logRemotoProvider = Provider<LogRemoto>((ref) {
  return LogRemoto(ref.watch(apiClientProvider));
});

class LogRemoto {
  LogRemoto(this._api);

  final ApiClient _api;

  /// Versão do app. Informe no build com `--dart-define=APP_VERSION=1.2.0`.
  static const versao = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  /// Máximo de relatos por execução do app.
  static const limiteDaSessao = 40;

  /// O mesmo relato não é enviado de novo dentro deste prazo.
  static const prazoDeRepeticao = Duration(seconds: 30);

  static final _ultimos = <String, DateTime>{};
  static int _enviados = 0;

  /// Só para os testes: zera o controle de repetição.
  @visibleForTesting
  static void reiniciar() {
    _ultimos.clear();
    _enviados = 0;
  }

  static String get _plataforma =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

  /// [nivel]: `ERRO`, `AVISO` ou `INFO`.
  Future<void> registrar({
    required String codigo,
    required String mensagem,
    String nivel = 'ERRO',
    String? tela,
    String? rota,
    String? metodo,
    int? statusHttp,
    Map<String, dynamic>? detalhes,
  }) async {
    try {
      final chave = '$codigo|$tela|$mensagem';
      final agora = DateTime.now();
      final anterior = _ultimos[chave];

      if (_enviados >= limiteDaSessao ||
          (anterior != null && agora.difference(anterior) < prazoDeRepeticao)) {
        return;
      }

      _ultimos[chave] = agora;
      _enviados++;

      await _api.post(
        '/logs/app',
        data: {
          'nivel': nivel,
          'codigo': codigo,
          'mensagem': _cortar(mensagem, 1000),
          'tela': ?tela,
          'rota': ?rota,
          'metodo': ?metodo,
          'status_http': ?statusHttp,
          'app_versao': versao,
          'plataforma': _plataforma,
          'detalhes': ?detalhes,
        },
      );
    } catch (_) {
      // Log nunca pode virar outro erro para a pessoa.
    }
  }

  /// Relata uma exceção. Erros da API que a própria API já registrou
  /// (resposta 4xx/5xx) entram com o código e o campo que falhou, para
  /// ligar o erro à tela em que a pessoa estava.
  Future<void> registrarErro(
    Object erro, {
    String? tela,
    String? acao,
    StackTrace? pilha,
  }) {
    if (erro is ApiException) {
      // 401 é a sessão vencendo: esperado e tratado em outro lugar.
      if (erro.isUnauthorized) return Future.value();

      return registrar(
        codigo: erro.code ?? (erro.isNetworkError ? 'APP_REDE' : 'APP_API'),
        mensagem: erro.message,
        nivel: erro.isNetworkError ? 'AVISO' : 'ERRO',
        tela: tela,
        statusHttp: erro.statusCode,
        detalhes: {
          'acao': ?acao,
          if (erro.fields.isNotEmpty) 'campos': erro.fields,
        },
      );
    }

    return registrar(
      codigo: 'APP_EXCECAO',
      mensagem: '${erro.runtimeType}: $erro',
      tela: tela,
      detalhes: {
        'acao': ?acao,
        if (pilha != null) 'pilha': _cortar(pilha.toString(), 1500),
      },
    );
  }

  static String _cortar(String texto, int limite) =>
      texto.length > limite ? '${texto.substring(0, limite - 1)}…' : texto;
}
