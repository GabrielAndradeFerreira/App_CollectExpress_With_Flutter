import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/aluguel.dart';
import '../../../core/models/cacamba.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/extensao.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';
import '../domain/models/fornecedor_dashboard.dart';

final fornecedorRepositoryProvider = Provider<FornecedorRepository>((ref) {
  return FornecedorRepository(ref.watch(apiClientProvider));
});

/// Área do fornecedor (CACAMBEIRO): painel, caçambas e pedidos recebidos.
class FornecedorRepository {
  FornecedorRepository(this._api);

  final ApiClient _api;

  Future<FornecedorDashboard> dashboard() async {
    final data = await _api.get('/cacambeiros/dashboard');
    return FornecedorDashboard.fromJson(parseMap(data) ?? const {});
  }

  /// Informe [mes] e [ano], ou [dataInicio] e [dataFim] (até 366 dias).
  /// Sem nenhum, usa o mês atual.
  Future<RelatorioFinanceiro> financeiro({
    int? mes,
    int? ano,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    final data = await _api.get(
      '/cacambeiros/financeiro',
      query: {
        'mes': ?mes,
        'ano': ?ano,
        if (dataInicio != null) 'data_inicio': formatApiDate(dataInicio),
        if (dataFim != null) 'data_fim': formatApiDate(dataFim),
      },
    );

    return RelatorioFinanceiro.fromJson(parseMap(data) ?? const {});
  }

  /// Todas as caçambas do fornecedor, inclusive as indisponíveis.
  Future<List<Cacamba>> minhasCacambas() async {
    return parseList(await _api.get('/cacambas/minhas'), Cacamba.fromJson);
  }

  /// [tipoResiduo] precisa ser o nome de uma categoria cadastrada.
  ///
  /// A foto vai em [fotoBase64] (a API grava o arquivo e guarda o
  /// caminho). [fotoUrl] ainda é aceito para links externos.
  /// [permiteExtensao] liga os pedidos de extensão de aluguel.
  Future<Cacamba> criarCacamba({
    required String nome,
    required String tipoResiduo,
    required double tamanhoM3,
    required double precoDiaria,
    String? fotoUrl,
    String? fotoBase64,
    bool permiteExtensao = false,
  }) async {
    final data = await _api.post(
      '/cacambas',
      data: {
        'nome': nome.trim(),
        'tipo_residuo': tipoResiduo,
        'tamanho_m3': tamanhoM3,
        'preco_diaria': precoDiaria,
        'foto_url': ?fotoUrl,
        'foto_base64': ?fotoBase64,
        'permite_extensao': permiteExtensao,
      },
    );

    return Cacamba.fromJson(parseMap(data) ?? const {});
  }

  /// Envia só os campos informados. [removerFoto] apaga a foto atual.
  Future<Cacamba> atualizarCacamba(
    String id, {
    String? nome,
    String? tipoResiduo,
    double? tamanhoM3,
    double? precoDiaria,
    String? fotoUrl,
    String? fotoBase64,
    bool removerFoto = false,
    bool? disponivel,
    bool? permiteExtensao,
  }) async {
    final data = await _api.put(
      '/cacambas/$id',
      data: {
        if (nome != null) 'nome': nome.trim(),
        'tipo_residuo': ?tipoResiduo,
        'tamanho_m3': ?tamanhoM3,
        'preco_diaria': ?precoDiaria,
        if (removerFoto) 'foto_url': null else 'foto_url': ?fotoUrl,
        'foto_base64': ?fotoBase64,
        'disponivel': ?disponivel,
        'permite_extensao': ?permiteExtensao,
      },
    );

    return Cacamba.fromJson(parseMap(data) ?? const {});
  }

  /// Devolve `true` se a caçamba foi apagada, ou `false` se ela tinha
  /// histórico de pedidos e por isso só foi desativada.
  Future<bool> removerCacamba(String id) async {
    final data = parseMap(await _api.delete('/cacambas/$id'));
    return data?['removed'] == true;
  }

  /// Pedidos recebidos, com contato do cliente e endereço de entrega.
  Future<List<Aluguel>> pedidosRecebidos() async {
    return parseList(await _api.get('/alugueis/gestao'), Aluguel.fromJson);
  }

  /// Assinatura padrão da empresa usada nos contratos (PNG), ou `null`
  /// se ainda não foi enviada.
  Future<Uint8List?> assinaturaEmpresa() async {
    try {
      return await _api.getBytes('/cacambeiros/me/assinatura');
    } on ApiException catch (error) {
      if (error.code == 'SIGNATURE_NOT_FOUND') return null;
      rethrow;
    }
  }

  /// PNG em base64 (3:1, de 300x100 a 1200x400 px, até 300 KB).
  Future<void> salvarAssinaturaEmpresa(String assinaturaBase64) async {
    await _api.put(
      '/cacambeiros/me/assinatura',
      data: {'assinatura_base64': assinaturaBase64},
    );
  }

  Future<void> removerAssinaturaEmpresa() async {
    await _api.delete('/cacambeiros/me/assinatura');
  }

  /// Aceita ou recusa um pedido de extensão. Aceitando, o cliente tem
  /// 24 horas para pagar.
  Future<Extensao> responderExtensao(
    String aluguelId,
    String extensaoId, {
    required bool aceitar,
  }) async {
    final data = await _api.patch(
      '/alugueis/$aluguelId/extensoes/$extensaoId',
      data: {'acao': aceitar ? 'ACEITAR' : 'RECUSAR'},
    );

    return Extensao.fromJson(parseMap(data) ?? const {});
  }

  /// Avança o pedido uma etapa por vez:
  /// AGUARDANDO_ENTREGA → EM_USO → AGUARDANDO_RETIRADA → FINALIZADO.
  Future<Aluguel> atualizarStatus(
    String aluguelId,
    StatusAluguel status,
  ) async {
    final data = await _api.patch(
      '/alugueis/$aluguelId/status',
      data: {'status_aluguel': status.apiValue},
    );

    return Aluguel.fromJson(parseMap(data) ?? const {});
  }
}
