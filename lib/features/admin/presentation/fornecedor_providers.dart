import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/aluguel.dart';
import '../../../core/models/cacamba.dart';
import '../../../core/models/usuario.dart';
import '../../auth/data/auth_repository.dart';
import '../../pedidos/data/pedidos_repository.dart';
import '../data/fornecedor_repository.dart';
import '../domain/models/fornecedor_dashboard.dart';

// Dados das telas do fornecedor (CACAMBEIRO).

final fornecedorDashboardProvider =
    FutureProvider.autoDispose<FornecedorDashboard>((ref) {
      return ref.watch(fornecedorRepositoryProvider).dashboard();
    });

/// Dados da conta do fornecedor (nome, telefone, horário, taxa), lidos do
/// servidor a cada abertura do perfil da loja.
final perfilFornecedorProvider = FutureProvider.autoDispose<Usuario>((ref) {
  return ref.watch(authRepositoryProvider).perfil();
});

final minhasCacambasProvider = FutureProvider.autoDispose<List<Cacamba>>((ref) {
  return ref.watch(fornecedorRepositoryProvider).minhasCacambas();
});

final pedidosRecebidosProvider = FutureProvider.autoDispose<List<Aluguel>>((
  ref,
) {
  return ref.watch(fornecedorRepositoryProvider).pedidosRecebidos();
});

final detalhePedidoFornecedorProvider = FutureProvider.autoDispose
    .family<Aluguel, String>((ref, id) {
      return ref.watch(pedidosRepositoryProvider).detalhe(id);
    });
