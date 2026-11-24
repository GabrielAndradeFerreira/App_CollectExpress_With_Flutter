import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/models/usuario.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_exception.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/auth/data/auth_repository.dart';
import 'package:app_collect_express_with_flutter/features/auth/data/sessao_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

const _usuarioAdmin = {
  'id': 'u1',
  'nome_completo': 'Admin Sistema',
  'email': 'admin@collectexpress.com',
  'tipo_perfil': 'ADMIN',
  'status': 'ATIVO',
};

void main() {
  late InMemoryTokenStorage storage;

  setUp(() => storage = InMemoryTokenStorage());

  AuthRepository repositoryWith(FakeApiAdapter adapter) {
    final api = ApiClient(storage: storage, adapter: adapter);
    return AuthRepository(api, storage);
  }

  group('login', () {
    test('API nova: guarda access e refresh token', () async {
      final adapter = FakeApiAdapter((request) {
        expect(request.path, '/auth/login');
        expect(sentBody(request), {
          'email': 'admin@collectexpress.com',
          'senha': '123456',
        });
        return const FakeResponse(200, {
          'success': true,
          'message': 'Login realizado com sucesso.',
          'data': {
            'access_token': 'jwt',
            'refresh_token': 'refresh',
            'token_type': 'Bearer',
            'expires_in': '15m',
            'usuario': _usuarioAdmin,
          },
        });
      });

      final usuario = await repositoryWith(adapter)
          .login(email: ' Admin@CollectExpress.com ', senha: '123456');

      expect(usuario.isAdmin, isTrue);
      expect(usuario.email, 'admin@collectexpress.com');
      expect(storage.accessToken, 'jwt');
      expect(storage.refreshToken, 'refresh');
    });

    test('API antiga (main): só token', () async {
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(200, {
          'token': 'jwt-antigo',
          'usuario': {
            'id': 'u1',
            'nome_completo': 'Admin Sistema',
            'tipo_perfil': 'ADMIN',
          },
        }),
      );

      final usuario = await repositoryWith(adapter)
          .login(email: 'admin@collectexpress.com', senha: '123456');

      expect(usuario.tipoPerfil, TipoPerfil.admin);
      expect(storage.accessToken, 'jwt-antigo');
      expect(storage.refreshToken, isNull);
    });

    test('credenciais inválidas não guardam nada', () async {
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(401, {
          'success': false,
          'message': 'Credenciais inválidas.',
          'code': 'INVALID_CREDENTIALS',
        }),
      );

      await expectLater(
        repositoryWith(adapter).login(email: 'a@b.com', senha: 'errada'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.code,
            'code',
            'INVALID_CREDENTIALS',
          ),
        ),
      );
      expect(storage.accessToken, isNull);
    });
  });

  test('registrar fornecedor manda só dígitos e os detalhes', () async {
    final adapter = FakeApiAdapter((request) {
      expect(sentBody(request), {
        'nome_completo': 'Fornecedor',
        'email': 'f@teste.com',
        'senha': 'Senha123',
        'tipo_perfil': 'CACAMBEIRO',
        'documento': '12345678000190',
        'telefone': '11999999999',
        'horario_inicio': '08:00',
        'horario_fim': '18:00',
        'raio_entrega_km': 30.0,
        'taxa_entrega': 40.0,
      });
      expect(bearer(request), isNull);
      return const FakeResponse(201, {
        'success': true,
        'data': {
          'id': 'u9',
          'nome_completo': 'Fornecedor',
          'email': 'f@teste.com',
          'tipo_perfil': 'CACAMBEIRO',
          'status': 'PENDENTE',
        },
      });
    });

    final usuario = await repositoryWith(adapter).registrar(
      nomeCompleto: 'Fornecedor',
      email: 'f@teste.com',
      senha: 'Senha123',
      tipoPerfil: TipoPerfil.cacambeiro,
      documento: '12.345.678/0001-90',
      telefone: '(11) 99999-9999',
      detalhesCacambeiro: const DetalhesCacambeiro(
        horarioInicio: '08:00',
        horarioFim: '18:00',
        raioEntregaKm: 30,
        taxaEntrega: 40,
      ),
    );

    expect(usuario.status, StatusUsuario.pendente);
  });

  test('cadastro de admin por convite explica que ainda não existe', () async {
    final adapter = FakeApiAdapter(
      (_) => const FakeResponse(404, {
        'success': false,
        'message': 'Endpoint não encontrado.',
        'code': 'NOT_FOUND',
      }),
    );

    await expectLater(
      repositoryWith(adapter).registrarAdminPorConvite(
        nomeCompleto: 'Novo Admin',
        email: 'novo@teste.com',
        senha: 'Senha123',
        codigoConvite: 'ABC',
      ),
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('ainda não está disponível'),
        ),
      ),
    );
  });

  group('recuperação de senha', () {
    test('pede o código por e-mail, sem mandar o token', () async {
      storage.accessToken = 'token-antigo';
      final adapter = FakeApiAdapter((request) {
        expect(request.path, '/auth/forgot-password');
        expect(bearer(request), isNull);
        expect(sentBody(request), {
          'identifier': 'maria@reformas.com',
          'channel': 'EMAIL',
        });
        return const FakeResponse(200, {
          'success': true,
          'message': 'Se os dados estiverem cadastrados, você receberá um código de recuperação.',
          'data': {
            'request_id': '0b1e3c7a-9f0d-4f3e-8a55-2f6c1d9e4b21',
            'destination_masked': 'ma***@reformas.com',
            'development_code': '482913',
          },
        });
      });

      final pedido = await repositoryWith(adapter)
          .solicitarRecuperacaoSenha(' Maria@Reformas.com ');

      expect(pedido.requestId, '0b1e3c7a-9f0d-4f3e-8a55-2f6c1d9e4b21');
      expect(pedido.destinoMascarado, 'ma***@reformas.com');
      expect(pedido.codigoDeTeste, '482913');
    });

    test('sem o modo de teste, o código não vem na resposta', () async {
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(200, {
          'success': true,
          'data': {
            'request_id': 'req-1',
            'destination_masked': 'ma***@reformas.com',
          },
        }),
      );

      final pedido = await repositoryWith(adapter)
          .solicitarRecuperacaoSenha('maria@reformas.com');

      expect(pedido.codigoDeTeste, isNull);
    });

    test('redefine a senha com o pedido e o código', () async {
      final adapter = FakeApiAdapter((request) {
        expect(request.path, '/auth/reset-password');
        expect(bearer(request), isNull);
        expect(sentBody(request), {
          'request_id': 'req-1',
          'code': '482913',
          'nova_senha': 'NovaSenha1',
        });
        return const FakeResponse(200, {
          'success': true,
          'message': 'Senha atualizada com sucesso.',
          'data': null,
        });
      });

      await repositoryWith(adapter).redefinirSenha(
        requestId: 'req-1',
        codigo: ' 482913 ',
        novaSenha: 'NovaSenha1',
      );

      expect(adapter.paths, ['POST /auth/reset-password']);
    });

    test('código inválido vira ApiException com o código do erro', () async {
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(400, {
          'success': false,
          'message': 'Código inválido, expirado ou já utilizado.',
          'code': 'INVALID_RECOVERY_CODE',
        }),
      );

      await expectLater(
        repositoryWith(adapter).redefinirSenha(
          requestId: 'req-1',
          codigo: '000000',
          novaSenha: 'NovaSenha1',
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 'INVALID_RECOVERY_CODE')
              .having(
                (e) => e.message,
                'message',
                'Código inválido, expirado ou já utilizado.',
              ),
        ),
      );
    });
  });

  group('logout', () {
    test('revoga na API e limpa os tokens', () async {
      storage
        ..accessToken = 'jwt'
        ..refreshToken = 'refresh';
      final adapter = FakeApiAdapter((request) {
        expect(request.path, '/auth/logout');
        expect(bearer(request), 'Bearer jwt');
        expect(sentBody(request), {'refresh_token': 'refresh'});
        return const FakeResponse(200, {'success': true, 'data': null});
      });

      await repositoryWith(adapter).logout();

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
    });

    test('limpa os tokens mesmo se a API estiver fora do ar', () async {
      storage.accessToken = 'jwt';
      final adapter = FakeApiAdapter((_) => const FakeResponse.networkError());

      await repositoryWith(adapter).logout();

      expect(storage.accessToken, isNull);
    });
  });

  group('sessaoProvider', () {
    ProviderContainer containerWith(FakeApiAdapter adapter) {
      final container = ProviderContainer(
        overrides: [
          tokenStorageProvider.overrideWithValue(storage),
          apiClientProvider.overrideWith(
            (ref) => ApiClient(storage: storage, adapter: adapter),
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('sem token salvo, começa deslogado', () async {
      final adapter = FakeApiAdapter((_) => fail('não deveria chamar a API'));

      expect(await containerWith(adapter).read(sessaoProvider.future), isNull);
    });

    test('com token salvo, recupera o usuário pelo perfil', () async {
      storage.accessToken = 'jwt';
      final adapter = FakeApiAdapter((request) {
        expect(request.path, '/usuarios/perfil');
        return const FakeResponse(200, {
          'success': true,
          'data': _usuarioAdmin,
        });
      });

      final usuario = await containerWith(adapter).read(sessaoProvider.future);

      expect(usuario!.nomeCompleto, 'Admin Sistema');
    });

    test('entrar e sair atualizam o estado', () async {
      final adapter = FakeApiAdapter((request) {
        if (request.path == '/auth/logout') {
          return const FakeResponse(200, {'success': true, 'data': null});
        }
        return const FakeResponse(200, {
          'success': true,
          'data': {
            'access_token': 'jwt',
            'refresh_token': 'refresh',
            'usuario': _usuarioAdmin,
          },
        });
      });
      final container = containerWith(adapter);
      await container.read(sessaoProvider.future);

      await container
          .read(sessaoProvider.notifier)
          .entrar(email: 'admin@collectexpress.com', senha: '123456');
      expect(container.read(sessaoProvider).value!.isAdmin, isTrue);

      await container.read(sessaoProvider.notifier).sair();
      expect(container.read(sessaoProvider).value, isNull);
      expect(storage.accessToken, isNull);
    });

    test('volta para deslogado quando a sessão expira', () async {
      storage.accessToken = 'jwt';
      var perfilChamadas = 0;
      final adapter = FakeApiAdapter((request) {
        perfilChamadas++;
        return perfilChamadas == 1
            ? const FakeResponse(200, {'success': true, 'data': _usuarioAdmin})
            : const FakeResponse(401, {
                'success': false,
                'message': 'Token inválido ou expirado.',
                'code': 'INVALID_ACCESS_TOKEN',
              });
      });
      final container = containerWith(adapter);
      expect(await container.read(sessaoProvider.future), isNotNull);

      // Uma requisição qualquer recebe 401 e não há refresh token.
      await expectLater(
        container.read(apiClientProvider).get('/carrinho'),
        throwsA(isA<ApiException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(container.read(sessaoProvider).value, isNull);
    });
  });
}
