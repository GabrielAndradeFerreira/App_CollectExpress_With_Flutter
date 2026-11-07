import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_atendimento.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final localizacaoRepositoryProvider = Provider<LocalizacaoRepository>((ref) {
  return LocalizacaoRepository(ref.watch(apiClientProvider));
});

/// Resolve um CEP em endereço e coordenadas, pela API (que consulta
/// serviços gratuitos de CEP e de mapa).
class LocalizacaoRepository {
  LocalizacaoRepository(this._api);

  final ApiClient _api;

  /// Lança [ApiException] com `INVALID_CEP`, `CEP_NOT_FOUND` ou
  /// `GEOCODING_UNAVAILABLE`. Devolve `null` se o CEP existe mas não
  /// foi possível localizá-lo no mapa.
  Future<LocalEntrega?> buscarCep(String cep) async {
    final digitos = cep.replaceAll(RegExp(r'\D'), '');
    final data = await _api.get('/localizacao/cep/$digitos', auth: false);

    return LocalEntrega.fromCepJson(parseMap(data) ?? const {});
  }
}
