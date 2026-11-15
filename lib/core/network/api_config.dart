import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuração da conexão com a CollectExpressAPI.
///
/// A URL vem, nesta ordem, de:
/// 1. `flutter run --dart-define=API_URL=https://minha-api.com/api`
///    (builds de produção; `API_BASE_URL` também é aceito);
/// 2. `API_URL` do arquivo `.env` (carregado no `main`);
/// 3. a API local na porta 3001.
abstract final class ApiConfig {
  static const _apiUrlDefine = String.fromEnvironment(
    'API_URL',
    defaultValue: String.fromEnvironment('API_BASE_URL'),
  );

  static const _apiUrlPadrao = 'http://localhost:3001/api';

  static String get baseUrl {
    if (_apiUrlDefine.isNotEmpty) return _apiUrlDefine;

    final doEnv = dotenv.isInitialized ? dotenv.env['API_URL'] : null;
    if (doEnv != null && doEnv.isNotEmpty) return doEnv;

    return _apiUrlPadrao;
  }

  /// O plano gratuito do Render hiberna e leva até ~50 s para acordar:
  /// 15 s derrubava a primeira chamada do dia.
  static const Duration timeout = Duration(seconds: 30);

  /// Esperas antes de repetir um GET que falhou por motivo passageiro.
  static const List<Duration> retryDelays = [
    Duration(seconds: 2),
    Duration(seconds: 5),
  ];
}
