import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/log_remoto.dart';
import '../../../core/models/usuario.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';
import 'auth_repository.dart';

/// Usuário logado, ou `null` se ninguém estiver logado.
///
/// Ao abrir o app, recupera a sessão salva consultando o perfil na API.
/// Volta para `null` sozinho quando a sessão expira.
final sessaoProvider = AsyncNotifierProvider<SessaoNotifier, Usuario?>(
  SessaoNotifier.new,
);

/// Conta quantas vezes a sessão acabou sozinha (token vencido que não
/// pôde ser renovado). O app observa para levar a pessoa à tela inicial.
final sessaoExpiradaProvider = NotifierProvider<SessaoExpirada, int>(
  SessaoExpirada.new,
);

class SessaoExpirada extends Notifier<int> {
  @override
  int build() => 0;

  void registrar() => state++;
}

class SessaoNotifier extends AsyncNotifier<Usuario?> {
  AuthRepository get _auth => ref.read(authRepositoryProvider);

  @override
  Future<Usuario?> build() async {
    final subscription = ref
        .watch(apiClientProvider)
        .sessionExpired
        .listen((_) => _sessaoExpirou());
    ref.onDispose(subscription.cancel);

    if (!await _auth.temSessao()) return null;

    try {
      return await _auth.perfil();
    } on ApiException catch (error) {
      // 401: sessão expirada. 403: conta pendente ou suspensa.
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _auth.limparSessaoLocal();
        return null;
      }
      rethrow;
    }
  }

  void _sessaoExpirou() {
    // Só conta se havia alguém logado; o resto é um 401 sem importância.
    if (state.value == null) return;

    state = const AsyncData(null);
    ref.read(sessaoExpiradaProvider.notifier).registrar();
    ref
        .read(logRemotoProvider)
        .registrar(
          codigo: 'SESSAO_EXPIRADA',
          mensagem: 'A sessão expirou e não pôde ser renovada.',
          nivel: 'INFO',
        );
  }

  /// Troca o usuário em memória depois de editar o perfil, para o nome
  /// no menu e nas telas mudar sem sair e entrar de novo.
  void atualizarUsuario(Usuario usuario) {
    state = AsyncData(usuario);
  }

  Future<Usuario> entrar({required String email, required String senha}) async {
    final usuario = await _auth.login(email: email, senha: senha);
    state = AsyncData(usuario);
    return usuario;
  }

  Future<void> sair() async {
    await _auth.logout();
    state = const AsyncData(null);
  }
}
