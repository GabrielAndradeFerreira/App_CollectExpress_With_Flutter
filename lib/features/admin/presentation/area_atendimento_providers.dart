import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_atendimento.dart';
import '../../auth/data/sessao_provider.dart';
import '../data/fornecedor_repository.dart';

/// Cerca virtual atual do fornecedor.
final areaAtendimentoProvider = FutureProvider.autoDispose<AreaAtendimento>((
  ref,
) {
  return ref.watch(fornecedorRepositoryProvider).areaAtendimento();
});

/// Origem das imagens do mapa. `null` usa a rede (OpenStreetMap); os
/// testes trocam por um provedor que não baixa nada.
final mapaTileProviderProvider = Provider<TileProvider?>((ref) => null);

/// Se o aviso de cadastro incompleto já apareceu nesta sessão, para não
/// repetir a cada volta ao painel. Zera quando a pessoa sai da conta.
final avisoPendenciasMostradoProvider =
    NotifierProvider<AvisoPendenciasMostrado, bool>(
      AvisoPendenciasMostrado.new,
    );

class AvisoPendenciasMostrado extends Notifier<bool> {
  @override
  bool build() {
    ref.listen(sessaoProvider.select((sessao) => sessao.value?.id), (_, _) {
      state = false;
    });

    return false;
  }

  void marcar() => state = true;
}
