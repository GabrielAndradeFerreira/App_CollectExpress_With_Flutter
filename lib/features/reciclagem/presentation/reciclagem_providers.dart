import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_atendimento.dart';
import '../../../core/models/pagina.dart';
import '../../../core/models/reciclagem.dart';
import '../data/parceiro_repository.dart';
import '../data/reciclagem_repository.dart';

// Dados das telas de reciclagem (parceiro, cliente e caçambeiro).

/// Catálogo de materiais, para os filtros e formulários.
final materiaisReciclaveisProvider =
    FutureProvider.autoDispose<List<MaterialReciclavel>>((ref) {
      return ref.watch(reciclagemRepositoryProvider).materiais();
    });

/// Sinalizações de quem entrega o material (cliente ou caçambeiro).
final minhasOfertasProvider = FutureProvider.autoDispose<List<OfertaColeta>>((
  ref,
) {
  return ref.watch(reciclagemRepositoryProvider).minhasOfertas();
});

typedef VitrineDeOfertas = ({
  Pagina<OfertaDisponivel> pagina,
  bool areaDefinida,
});

/// Uma página da vitrine do parceiro para cada filtro.
final ofertasDisponiveisProvider = FutureProvider.autoDispose
    .family<VitrineDeOfertas, FiltroOfertas>((ref, filtro) {
      return ref.watch(reciclagemRepositoryProvider).ofertasDisponiveis(filtro);
    });

final ofertaDisponivelProvider = FutureProvider.autoDispose
    .family<OfertaDisponivel, String>((ref, id) {
      return ref.watch(reciclagemRepositoryProvider).detalheOferta(id);
    });

typedef FiltroColetas = ({StatusColeta? status, int pagina});

/// Uma página de coletas (do parceiro ou de quem entrega) por filtro.
final coletasProvider = FutureProvider.autoDispose
    .family<Pagina<Coleta>, FiltroColetas>((ref, filtro) {
      return ref
          .watch(reciclagemRepositoryProvider)
          .coletas(status: filtro.status, pagina: filtro.pagina);
    });

final coletaProvider = FutureProvider.autoDispose.family<Coleta, String>((
  ref,
  id,
) {
  return ref.watch(reciclagemRepositoryProvider).detalheColeta(id);
});

final resumoColetasProvider = FutureProvider.autoDispose<ResumoColetas>((ref) {
  return ref.watch(reciclagemRepositoryProvider).resumo();
});

// Perfil do parceiro.

final perfilParceiroProvider = FutureProvider.autoDispose<PerfilParceiro>((
  ref,
) {
  return ref.watch(parceiroRepositoryProvider).perfil();
});

final pendenciasParceiroProvider =
    FutureProvider.autoDispose<List<PendenciaParceiro>>((ref) {
      return ref.watch(parceiroRepositoryProvider).pendencias();
    });

/// Área de atuação do parceiro (círculo no mapa).
final areaParceiroProvider = FutureProvider.autoDispose<AreaAtendimento>((ref) {
  return ref.watch(parceiroRepositoryProvider).area();
});

/// Assinatura do parceiro, ou `null` se ainda não foi enviada.
final assinaturaParceiroProvider = FutureProvider.autoDispose<Uint8List?>((
  ref,
) {
  return ref.watch(parceiroRepositoryProvider).assinatura();
});
