import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/chat.dart';
import '../../../core/models/pagina.dart';
import '../../auth/data/sessao_provider.dart';
import '../data/chat_repository.dart';

/// De quanto em quanto tempo o total de não lidas é consultado.
const intervaloNaoLidas = Duration(seconds: 30);

/// Total de conversas e mensagens não lidas, para as bolhas da aba.
///
/// Consulta a API enquanto algum widget observa (as barras de navegação)
/// e para sozinho depois. Sem login, o total é zero e a API não é usada.
/// Para atualizar na hora, use `ref.invalidate(naoLidasProvider)`.
final naoLidasProvider = StreamProvider.autoDispose<NaoLidas>((ref) {
  final usuarioId = ref.watch(sessaoProvider.select((s) => s.value?.id));
  final controle = StreamController<NaoLidas>();

  ref.onDispose(controle.close);

  if (usuarioId == null) {
    controle.add(NaoLidas.zero);
    return controle.stream;
  }

  final repositorio = ref.watch(chatRepositoryProvider);

  Future<void> consultar() async {
    try {
      final total = await repositorio.naoLidas();
      if (!controle.isClosed) controle.add(total);
    } catch (_) {
      // Sem rede: mantém o último valor em vez de apagar a bolha.
    }
  }

  consultar();

  final relogio = Timer.periodic(intervaloNaoLidas, (_) => consultar());
  ref.onDispose(relogio.cancel);

  return controle.stream;
});

/// Filtros da lista de conversas.
typedef FiltroConversas = ({
  TipoConversa? tipo,
  bool? aberta,
  bool denunciadas,
  String busca,
  int pagina,
});

/// Uma página da lista de conversas para cada filtro.
final conversasProvider = FutureProvider.autoDispose
    .family<Pagina<Conversa>, FiltroConversas>((ref, filtro) {
      return ref
          .watch(chatRepositoryProvider)
          .listarConversas(
            tipo: filtro.tipo,
            aberta: filtro.aberta,
            denunciadas: filtro.denunciadas,
            busca: filtro.busca,
            pagina: filtro.pagina,
          );
    });
