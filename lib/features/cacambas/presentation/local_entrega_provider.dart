import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/area_atendimento.dart';
import '../../auth/data/sessao_provider.dart';
import '../../perfil/data/enderecos_repository.dart';

/// Local onde o cliente quer receber a caçamba. O catálogo só mostra as
/// caçambas dos fornecedores que atendem esse local.
///
/// Fica só em memória: vale enquanto o app estiver aberto e é descartado
/// quando a pessoa sai da conta.
final localEntregaProvider =
    NotifierProvider<LocalEntregaNotifier, LocalEntrega?>(
      LocalEntregaNotifier.new,
    );

class LocalEntregaNotifier extends Notifier<LocalEntrega?> {
  @override
  LocalEntrega? build() {
    ref.listen(sessaoProvider.select((sessao) => sessao.value?.id), (
      anterior,
      atual,
    ) {
      if (anterior != null && atual == null) state = null;
    });

    return null;
  }

  void definir(LocalEntrega? local) => state = local;

  /// Usa o primeiro endereço salvo que já tem coordenadas, se o cliente
  /// ainda não escolheu um local. Falhas são ignoradas: nesse caso a
  /// pessoa informa o CEP.
  Future<void> usarEnderecoSalvo() async {
    if (state != null) return;

    try {
      final local = await _primeiroEnderecoLocalizado();

      if (local != null && state == null) state = local;
    } catch (_) {
      // Sem endereço utilizável: o catálogo pede o CEP.
    }
  }

  Future<LocalEntrega?> _primeiroEnderecoLocalizado() async {
    final enderecos = await ref.read(enderecosRepositoryProvider).listar();

    for (final endereco in enderecos) {
      final local = LocalEntrega.fromEndereco(endereco);
      if (local != null) return local;
    }

    return null;
  }
}

/// Endereços salvos do cliente que têm coordenadas, para escolher o
/// local de entrega com um toque.
final enderecosLocalizadosProvider =
    FutureProvider.autoDispose<List<LocalEntrega>>((ref) async {
      final enderecos = await ref.watch(enderecosRepositoryProvider).listar();

      return [
        for (final endereco in enderecos) ?LocalEntrega.fromEndereco(endereco),
      ];
    });
