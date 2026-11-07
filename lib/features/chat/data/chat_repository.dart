import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/pagina.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_providers.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

/// Conversas de texto entre cliente, caçambeiro e equipe (`/chat`).
class ChatRepository {
  ChatRepository(this._api);

  final ApiClient _api;

  /// [busca], [denunciadas] e conversas de [TipoConversa.pedido] sem
  /// mensagens só fazem sentido para o admin.
  Future<Pagina<Conversa>> listarConversas({
    TipoConversa? tipo,
    bool? aberta,
    bool denunciadas = false,
    String? busca,
    int pagina = 1,
  }) async {
    final data = await _api.get(
      '/chat/conversas',
      query: {
        'page': pagina,
        'tipo': ?tipo?.apiValue,
        if (aberta != null) 'status': aberta ? 'ABERTA' : 'FECHADA',
        if (denunciadas) 'denunciadas': true,
        if (busca != null && busca.trim().isNotEmpty) 'busca': busca.trim(),
      },
    );

    return Pagina.fromJson(data, Conversa.fromJson);
  }

  Future<NaoLidas> naoLidas() async {
    final data = await _api.get('/chat/nao-lidas');
    return NaoLidas.fromJson(parseMap(data) ?? const {});
  }

  /// Inclui o resumo do pedido vinculado, quando houver.
  Future<Conversa> detalhe(String id) async {
    final data = await _api.get('/chat/conversas/$id');
    return Conversa.fromJson(parseMap(data) ?? const {});
  }

  /// Sem cursor, devolve as mensagens mais recentes. [depois] traz só as
  /// novas (atualização) e [antes] as anteriores. Abrir marca como lidas
  /// as mensagens do outro lado.
  Future<({List<Mensagem> itens, bool temAnteriores})> mensagens(
    String conversaId, {
    int? depois,
    int? antes,
  }) async {
    final data = parseMap(
      await _api.get(
        '/chat/conversas/$conversaId/mensagens',
        query: {'depois': ?depois, 'antes': ?antes},
      ),
    );

    return (
      itens: parseList(data?['items'], Mensagem.fromJson),
      temAnteriores: parseBool(data?['tem_anteriores']),
    );
  }

  Future<Mensagem> enviar(String conversaId, String texto) async {
    final data = await _api.post(
      '/chat/conversas/$conversaId/mensagens',
      data: {'texto': texto.trim()},
    );

    return Mensagem.fromJson(parseMap(data) ?? const {});
  }

  /// Abre (ou cria) a conversa do pedido.
  Future<Conversa> conversaDoPedido(String aluguelId) async {
    final data = await _api.post('/chat/pedidos/$aluguelId/conversa');
    return Conversa.fromJson(parseMap(data) ?? const {});
  }

  /// Lança `CHAMADO_ALREADY_OPEN` se o cliente já tem um aberto.
  Future<Conversa> abrirChamado({
    required String assunto,
    required String mensagem,
    String? aluguelId,
  }) async {
    final data = await _api.post(
      '/chat/chamados',
      data: {
        'assunto': assunto.trim(),
        'mensagem': mensagem.trim(),
        'aluguel_id': ?aluguelId,
      },
    );

    return Conversa.fromJson(parseMap(data) ?? const {});
  }

  Future<Conversa> fecharChamado(String id) async {
    final data = await _api.patch('/chat/chamados/$id/fechar');
    return Conversa.fromJson(parseMap(data) ?? const {});
  }

  /// Avisa os admins por e-mail. Lança `ALREADY_REPORTED` se o usuário
  /// já denunciou a conversa nas últimas 24 horas.
  Future<void> denunciar(String conversaId, {String? motivo}) async {
    await _api.post(
      '/chat/conversas/$conversaId/denunciar',
      data: {if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo},
    );
  }

  /// Admin: marca a denúncia como analisada.
  Future<Conversa> resolverDenuncia(String conversaId) async {
    final data = await _api.patch('/chat/conversas/$conversaId/denuncia');
    return Conversa.fromJson(parseMap(data) ?? const {});
  }
}
