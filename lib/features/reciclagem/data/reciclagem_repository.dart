import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/json_parsing.dart';
import '../../../core/models/pagina.dart';
import '../../../core/models/reciclagem.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final reciclagemRepositoryProvider = Provider<ReciclagemRepository>((ref) {
  return ReciclagemRepository(ref.watch(apiClientProvider));
});

/// Filtros da vitrine de sinalizações do parceiro. [materiais] são os ids
/// separados por vírgula (texto, para o filtro servir de chave de provider).
typedef FiltroOfertas = ({
  String materiais,
  double? distanciaKm,
  DateTime? de,
  DateTime? ate,
  int pagina,
});

/// Sinalizações de material reciclável e coletas agendadas.
class ReciclagemRepository {
  ReciclagemRepository(this._api);

  final ApiClient _api;

  /// Tipos de material (lista pública).
  Future<List<MaterialReciclavel>> materiais() async {
    return parseList(
      await _api.get('/materiais', auth: false),
      MaterialReciclavel.fromJson,
    );
  }

  /// Quem entrega (cliente ou caçambeiro) sinaliza material disponível.
  ///
  /// [assinaturaBase64] é o PNG desenhado pelo cliente; o caçambeiro não
  /// envia (a API usa a assinatura cadastrada da empresa).
  Future<OfertaColeta> criarOferta({
    required List<String> materiaisIds,
    required String descricao,
    required String quantidadeEstimada,
    required String enderecoId,
    required DateTime janelaInicio,
    required DateTime janelaFim,
    String? observacoes,
    String? assinaturaBase64,
  }) async {
    final data = await _api.post(
      '/ofertas-coleta',
      data: {
        'materiais_ids': materiaisIds,
        'descricao': descricao.trim(),
        'quantidade_estimada': quantidadeEstimada.trim(),
        'endereco_id': enderecoId,
        'janela_inicio': janelaInicio.toUtc().toIso8601String(),
        'janela_fim': janelaFim.toUtc().toIso8601String(),
        if (observacoes != null && observacoes.trim().isNotEmpty)
          'observacoes': observacoes.trim(),
        'aceite_termos': true,
        'assinatura_base64': ?assinaturaBase64,
      },
    );

    return OfertaColeta.fromJson(parseMap(data) ?? const {});
  }

  Future<List<OfertaColeta>> minhasOfertas() async {
    return parseList(
      await _api.get('/ofertas-coleta/minhas'),
      OfertaColeta.fromJson,
    );
  }

  Future<OfertaColeta> cancelarOferta(String id) async {
    final data = await _api.patch('/ofertas-coleta/$id/cancelar');
    return OfertaColeta.fromJson(parseMap(data) ?? const {});
  }

  /// Vitrine do parceiro. Sem filtro, traz tudo que ainda dá tempo de
  /// agendar.
  Future<({Pagina<OfertaDisponivel> pagina, bool areaDefinida})>
  ofertasDisponiveis(FiltroOfertas filtro) async {
    final data = await _api.get(
      '/ofertas-coleta',
      query: {
        'page': filtro.pagina,
        if (filtro.materiais.isNotEmpty) 'materiais': filtro.materiais,
        'distancia_km': ?filtro.distanciaKm,
        if (filtro.de != null) 'de': filtro.de!.toUtc().toIso8601String(),
        if (filtro.ate != null) 'ate': filtro.ate!.toUtc().toIso8601String(),
      },
    );

    return (
      pagina: Pagina.fromJson(data, OfertaDisponivel.fromJson),
      areaDefinida: parseBool(parseMap(data)?['area_definida']),
    );
  }

  Future<OfertaDisponivel> detalheOferta(String id) async {
    final data = await _api.get('/ofertas-coleta/$id');
    return OfertaDisponivel.fromJson(parseMap(data) ?? const {});
  }

  /// O parceiro agenda a retirada. A API exige [dataAgendada] com pelo
  /// menos 24 horas de antecedência e dentro da janela da sinalização.
  Future<Coleta> agendar({
    required String ofertaId,
    required DateTime dataAgendada,
    String? observacoes,
  }) async {
    final data = await _api.post(
      '/coletas',
      data: {
        'oferta_id': ofertaId,
        'data_agendada': dataAgendada.toUtc().toIso8601String(),
        if (observacoes != null && observacoes.trim().isNotEmpty)
          'observacoes': observacoes.trim(),
      },
    );

    return Coleta.fromJson(parseMap(data) ?? const {});
  }

  Future<Pagina<Coleta>> coletas({StatusColeta? status, int pagina = 1}) async {
    final data = await _api.get(
      '/coletas',
      query: {'page': pagina, 'status': ?status?.apiValue},
    );

    return Pagina.fromJson(data, Coleta.fromJson);
  }

  Future<Coleta> detalheColeta(String id) async {
    final data = await _api.get('/coletas/$id');
    return Coleta.fromJson(parseMap(data) ?? const {});
  }

  /// [encerrarSinalizacao] (só para quem entrega) cancela também a
  /// sinalização; sem ele, ela volta para a vitrine.
  Future<Coleta> cancelarColeta(
    String id, {
    String? motivo,
    bool encerrarSinalizacao = false,
  }) async {
    final data = await _api.patch(
      '/coletas/$id/cancelar',
      data: {
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
        if (encerrarSinalizacao) 'encerrar_sinalizacao': true,
      },
    );

    return Coleta.fromJson(parseMap(data) ?? const {});
  }

  Future<Coleta> concluirColeta(String id, {double? pesoRealKg}) async {
    final data = await _api.patch(
      '/coletas/$id/concluir',
      data: {'peso_real_kg': ?pesoRealKg},
    );

    return Coleta.fromJson(parseMap(data) ?? const {});
  }

  /// PDF do documento de coleta (com as 3 assinaturas).
  Future<Uint8List> documento(String id) =>
      _api.getBytes('/coletas/$id/documento');

  Future<ResumoColetas> resumo() async {
    final data = await _api.get('/coletas/resumo');
    return ResumoColetas.fromJson(parseMap(data) ?? const {});
  }
}
