import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/aluguel.dart';
import '../../../core/models/avaliacao.dart';
import '../../../core/models/extensao.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/pagamento_pix.dart';
import '../../../core/models/pagina.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final pedidosRepositoryProvider = Provider<PedidosRepository>((ref) {
  return PedidosRepository(ref.watch(apiClientProvider));
});

/// Pedidos do consumidor logado.
class PedidosRepository {
  PedidosRepository(this._api);

  final ApiClient _api;

  /// Transforma o carrinho em pedido e esvazia o carrinho.
  /// [dataInicio] deve estar entre 1 e 60 dias a partir de hoje.
  ///
  /// A resposta não traz os itens; use [detalhe] para vê-los.
  ///
  /// O pedido exige o aceite dos termos e a assinatura desenhada pelo
  /// cliente ([assinaturaBase64]: PNG em base64). A API gera o contrato.
  Future<Aluguel> checkout({
    required String enderecoId,
    required DateTime dataInicio,
    required String assinaturaBase64,
  }) async {
    final data = await _api.post(
      '/alugueis/checkout',
      data: {
        'endereco_id': enderecoId,
        'data_inicio': formatApiDate(dataInicio),
        'aceite_termos': true,
        'assinatura_base64': assinaturaBase64,
      },
    );

    return Aluguel.fromJson(parseMap(data) ?? const {});
  }

  Future<Pagina<Aluguel>> meusPedidos({int pagina = 1}) async {
    final data = await _api.get('/alugueis/meus', query: {'page': pagina});
    return Pagina.fromJson(data, Aluguel.fromJson);
  }

  /// Itens, contatos, endereço, avaliação e etapas do pedido.
  /// Também serve para o fornecedor e o admin.
  Future<Aluguel> detalhe(String id) async {
    return Aluguel.fromJson(
      parseMap(await _api.get('/alugueis/$id')) ?? const {},
    );
  }

  /// PDF do contrato de locação (bytes).
  Future<Uint8List> baixarContrato(String aluguelId) {
    return _api.getBytes('/alugueis/$aluguelId/contrato');
  }

  /// Pede para estender o aluguel por [dias] (1 a 30). O fornecedor é
  /// avisado por e-mail e pode aceitar ou recusar.
  Future<Extensao> solicitarExtensao(String aluguelId, int dias) async {
    final data = await _api.post(
      '/alugueis/$aluguelId/extensoes',
      data: {'dias_adicionais': dias},
    );

    return Extensao.fromJson(parseMap(data) ?? const {});
  }

  /// PIX de uma extensão aceita pelo fornecedor (vale 24 horas).
  Future<PagamentoPix> gerarPixExtensao(
    String aluguelId,
    String extensaoId,
  ) async {
    return PagamentoPix.fromJson(
      parseMap(
            await _api.post('/alugueis/$aluguelId/extensoes/$extensaoId/pix'),
          ) ??
          const {},
    );
  }

  Future<PagamentoPix> consultarPixExtensao(
    String aluguelId,
    String extensaoId,
  ) async {
    return PagamentoPix.fromJson(
      parseMap(
            await _api.get('/alugueis/$aluguelId/extensoes/$extensaoId/pix'),
          ) ??
          const {},
    );
  }

  Future<PagamentoPix> simularPagamentoPixExtensao(
    String aluguelId,
    String extensaoId,
  ) async {
    return PagamentoPix.fromJson(
      parseMap(
            await _api.post(
              '/alugueis/$aluguelId/extensoes/$extensaoId/pix/simular',
            ),
          ) ??
          const {},
    );
  }

  /// Gera o PIX do pedido, ou devolve o que ainda está pendente.
  Future<PagamentoPix> gerarPix(String aluguelId) async {
    return PagamentoPix.fromJson(
      parseMap(await _api.post('/alugueis/$aluguelId/pix')) ?? const {},
    );
  }

  /// Último PIX do pedido. A API confere o pagamento na AbacatePay e,
  /// se ele foi feito, marca o pedido como pago.
  Future<PagamentoPix> consultarPix(String aluguelId) async {
    return PagamentoPix.fromJson(
      parseMap(await _api.get('/alugueis/$aluguelId/pix')) ?? const {},
    );
  }

  /// Simula o pagamento. Só funciona com PIX do modo de teste.
  Future<PagamentoPix> simularPagamentoPix(String aluguelId) async {
    return PagamentoPix.fromJson(
      parseMap(await _api.post('/alugueis/$aluguelId/pix/simular')) ?? const {},
    );
  }

  /// Só pedidos FINALIZADO podem ser avaliados, uma vez cada.
  /// [nota] de 1 a 5.
  Future<Avaliacao> avaliar({
    required String aluguelId,
    required int nota,
    String? comentario,
  }) async {
    final data = await _api.post(
      '/avaliacoes',
      data: {
        'aluguel_id': aluguelId,
        'nota': nota,
        if (comentario != null && comentario.trim().isNotEmpty)
          'comentario': comentario.trim(),
      },
    );

    return Avaliacao.fromJson(parseMap(data) ?? const {});
  }
}
