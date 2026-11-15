import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_atendimento.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/reciclagem.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';

final parceiroRepositoryProvider = Provider<ParceiroRepository>((ref) {
  return ParceiroRepository(ref.watch(apiClientProvider));
});

/// Perfil do parceiro de reciclagem (usuário PARCEIRO).
class ParceiroRepository {
  ParceiroRepository(this._api);

  final ApiClient _api;

  Future<PerfilParceiro> perfil() async {
    final data = await _api.get('/parceiros/me');
    return PerfilParceiro.fromJson(parseMap(data) ?? const {});
  }

  /// Envia só o que for informado. [materiaisIds] substitui a lista.
  Future<PerfilParceiro> atualizar({
    String? responsavelNome,
    String? enderecoColeta,
    double? capacidadeDiariaKg,
    bool? disponivel,
    List<String>? materiaisIds,
  }) async {
    final data = await _api.put(
      '/parceiros/me',
      data: {
        'responsavel_nome': ?responsavelNome?.trim(),
        'endereco_coleta': ?enderecoColeta?.trim(),
        'capacidade_diaria_kg': ?capacidadeDiariaKg,
        'disponivel': ?disponivel,
        'materiais_ids': ?materiaisIds,
      },
    );

    return PerfilParceiro.fromJson(parseMap(data) ?? const {});
  }

  Future<AreaAtendimento> area() async {
    final data = await _api.get('/parceiros/me/area');
    return AreaAtendimento.fromJson(parseMap(data) ?? const {});
  }

  Future<AreaAtendimento> salvarArea({
    required double latitude,
    required double longitude,
    required double raioKm,
  }) async {
    final data = await _api.put(
      '/parceiros/me/area',
      data: {'latitude': latitude, 'longitude': longitude, 'raio_km': raioKm},
    );

    return AreaAtendimento.fromJson(parseMap(data) ?? const {});
  }

  Future<List<PendenciaParceiro>> pendencias() async {
    final data = await _api.get('/parceiros/me/pendencias');
    return pendenciasDoParceiro(parseMap(data)?['pendencias']);
  }

  /// Assinatura da empresa (PNG), ou `null` se ainda não foi enviada.
  Future<Uint8List?> assinatura() async {
    try {
      return await _api.getBytes('/parceiros/me/assinatura');
    } on ApiException catch (error) {
      if (error.code == 'SIGNATURE_NOT_FOUND') return null;
      rethrow;
    }
  }

  Future<void> salvarAssinatura(String assinaturaBase64) async {
    await _api.put(
      '/parceiros/me/assinatura',
      data: {'assinatura_base64': assinaturaBase64},
    );
  }

  Future<void> removerAssinatura() async {
    await _api.delete('/parceiros/me/assinatura');
  }
}
