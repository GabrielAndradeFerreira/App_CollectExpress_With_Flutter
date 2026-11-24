import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/enums.dart';
import '../../../core/models/json_parsing.dart';
import '../../../core/models/reciclagem.dart';
import '../../../core/models/recuperacao_senha.dart';
import '../../../core/models/usuario.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/network/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

/// Login, cadastro e perfil do usuário logado.
class AuthRepository {
  AuthRepository(this._api, this._tokens);

  final ApiClient _api;
  final TokenStorage _tokens;

  /// Entra, guarda os tokens e devolve o usuário logado.
  Future<Usuario> login({required String email, required String senha}) async {
    final data = await _api.post(
      '/auth/login',
      auth: false,
      data: {'email': email.trim().toLowerCase(), 'senha': senha},
    );
    final json = parseMap(data) ?? const {};

    // API nova: access_token + refresh_token. API antiga: só token.
    final accessToken = parseStringOrNull(
      json['access_token'] ?? json['token'],
    );
    if (accessToken == null || accessToken.isEmpty) {
      throw const ApiException('A API não retornou o token de acesso.');
    }

    await _tokens.saveTokens(
      accessToken: accessToken,
      refreshToken: parseStringOrNull(json['refresh_token']),
    );

    return Usuario.fromJson(parseMap(json['usuario']) ?? const {});
  }

  /// Cria uma conta de CONSUMIDOR, CACAMBEIRO ou PARCEIRO. Não faz login: a
  /// conta de fornecedor ou de parceiro fica PENDENTE até ser aprovada.
  ///
  /// Administradores são criados por outro admin (`AdminRepository`).
  Future<Usuario> registrar({
    required String nomeCompleto,
    required String email,
    required String senha,
    required TipoPerfil tipoPerfil,
    required String documento,
    required String telefone,
    DetalhesCacambeiro? detalhesCacambeiro,
    DadosCadastroParceiro? dadosParceiro,
  }) async {
    assert(tipoPerfil != TipoPerfil.admin);
    assert(
      tipoPerfil != TipoPerfil.cacambeiro || detalhesCacambeiro != null,
      'Fornecedores precisam de detalhesCacambeiro',
    );
    assert(
      tipoPerfil != TipoPerfil.parceiro || dadosParceiro != null,
      'Parceiros precisam de dadosParceiro',
    );

    final data = await _api.post(
      '/auth/register',
      auth: false,
      data: {
        'nome_completo': nomeCompleto.trim(),
        'email': email.trim().toLowerCase(),
        'senha': senha,
        'tipo_perfil': tipoPerfil.apiValue,
        'documento': _digits(documento),
        'telefone': _digits(telefone),
        ...?detalhesCacambeiro?.toJson(),
        ...?dadosParceiro?.toJson(),
      },
    );

    return Usuario.fromJson(parseMap(data) ?? const {});
  }

  /// A API ainda não tem cadastro de administrador por convite (está na
  /// lista de pendências dela). Mantido para a tela de cadastro de admin.
  Future<void> registrarAdminPorConvite({
    required String nomeCompleto,
    required String email,
    required String senha,
    required String codigoConvite,
  }) async {
    try {
      await _api.post(
        '/auth/admin/register',
        auth: false,
        data: {
          'nome_completo': nomeCompleto.trim(),
          'email': email.trim().toLowerCase(),
          'senha': senha,
          'codigo_convite': codigoConvite.trim(),
        },
      );
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        throw const ApiException(
          'O cadastro de administrador por convite ainda não está '
          'disponível. Peça a um administrador para criar sua conta.',
          statusCode: 404,
        );
      }
      rethrow;
    }
  }

  /// Pede o código de 6 dígitos para criar uma senha nova. Por enquanto a
  /// API só envia por e-mail.
  Future<PedidoRecuperacaoSenha> solicitarRecuperacaoSenha(String email) async {
    final data = await _api.post(
      '/auth/forgot-password',
      auth: false,
      data: {'identifier': email.trim().toLowerCase(), 'channel': 'EMAIL'},
    );

    return PedidoRecuperacaoSenha.fromJson(parseMap(data) ?? const {});
  }

  /// Troca a senha com o código recebido. A API encerra todas as sessões
  /// abertas da conta.
  Future<void> redefinirSenha({
    required String requestId,
    required String codigo,
    required String novaSenha,
  }) async {
    await _api.post(
      '/auth/reset-password',
      auth: false,
      data: {
        'request_id': requestId,
        'code': codigo.trim(),
        'nova_senha': novaSenha,
      },
    );
  }

  Future<Usuario> perfil() async {
    return Usuario.fromJson(
      parseMap(await _api.get('/usuarios/perfil')) ?? const {},
    );
  }

  Future<Usuario> atualizarPerfil({
    String? nomeCompleto,
    String? telefone,
  }) async {
    final data = await _api.put(
      '/usuarios/perfil',
      data: {
        if (nomeCompleto != null) 'nome_completo': nomeCompleto.trim(),
        if (telefone != null) 'telefone': _digits(telefone),
      },
    );

    return Usuario.fromJson(parseMap(data) ?? const {});
  }

  Future<bool> temSessao() async {
    final token = await _tokens.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Encerra a sessão na API, quando possível, e apaga os tokens locais.
  Future<void> logout() async {
    try {
      if (await temSessao()) {
        final refreshToken = await _tokens.readRefreshToken();
        await _api.post('/auth/logout', data: {'refresh_token': ?refreshToken});
      }
    } on ApiException {
      // Token já expirado ou API fora do ar: encerra a sessão local mesmo assim.
    } finally {
      await _tokens.clear();
    }
  }

  /// Apaga os tokens sem chamar a API.
  Future<void> limparSessaoLocal() => _tokens.clear();

  static String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');
}
