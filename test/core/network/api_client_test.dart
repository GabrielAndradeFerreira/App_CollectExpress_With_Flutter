import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_exception.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_api.dart';

void main() {
  late InMemoryTokenStorage storage;

  ApiClient clientWith(FakeApiAdapter adapter) {
    return ApiClient(
      storage: storage,
      baseUrl: 'http://api.test/api',
      adapter: adapter,
    );
  }

  setUp(() {
    storage = InMemoryTokenStorage();
  });

  group('respostas', () {
    test('devolve o data do formato novo {success, data}', () async {
      final client = clientWith(
        FakeApiAdapter(
          (_) => const FakeResponse(200, {
            'success': true,
            'message': 'ok',
            'data': {'id': '1'},
          }),
        ),
      );

      expect(await client.get('/x'), {'id': '1'});
    });

    test('mantém a paginação que vem fora do data (GET /usuarios)', () async {
      final client = clientWith(
        FakeApiAdapter(
          (_) => const FakeResponse(200, {
            'success': true,
            'data': [
              {'id': '1'},
            ],
            'total': 21,
            'pagination': {'total': 21, 'page': 1, 'totalPages': 2},
          }),
        ),
      );

      expect(await client.get('/x'), {
        'items': [
          {'id': '1'},
        ],
        'pagination': {'total': 21, 'page': 1, 'totalPages': 2},
      });
    });

    test('devolve o corpo inteiro no formato antigo', () async {
      final client = clientWith(
        FakeApiAdapter(
          (_) => const FakeResponse(200, [
            {'id': '1'},
          ]),
        ),
      );

      expect(await client.get('/x'), [
        {'id': '1'},
      ]);
    });
  });

  group('erros', () {
    Future<ApiException> errorFrom(FakeResponse response) async {
      final client = clientWith(FakeApiAdapter((_) => response));
      try {
        await client.get('/x');
      } on ApiException catch (error) {
        return error;
      }
      fail('deveria lançar ApiException');
    }

    test('lê o formato novo com code e fields', () async {
      final error = await errorFrom(
        const FakeResponse(400, {
          'success': false,
          'message': 'Campos inválidos.',
          'code': 'VALIDATION_ERROR',
          'fields': {'cep': 'CEP deve conter 8 dígitos.'},
        }),
      );

      // Com um campo só, a mensagem é a do próprio campo.
      expect(error.message, 'CEP deve conter 8 dígitos.');
      expect(error.statusCode, 400);
      expect(error.code, 'VALIDATION_ERROR');
      expect(error.fields, {'cep': 'CEP deve conter 8 dígitos.'});
    });

    test('Dados inválidos com vários campos diz o que conferir', () async {
      final error = await errorFrom(
        const FakeResponse(400, {
          'success': false,
          'message': 'Dados inválidos.',
          'code': 'VALIDATION_ERROR',
          'fields': {
            'data_inicio': 'Informe a data.',
            'endereco_id': 'Informe o endereço.',
          },
        }),
      );

      expect(
        error.message,
        'Dados inválidos. Confira: data de início, endereço.',
      );
    });

    test('Dados inválidos com um campo cita o nome amigável', () async {
      final error = await errorFrom(
        const FakeResponse(400, {
          'success': false,
          'message': 'Dados inválidos.',
          'code': 'VALIDATION_ERROR',
          'fields': {
            'assinatura_base64': "O campo 'assinatura_base64' é obrigatório.",
          },
        }),
      );

      expect(error.message, "O campo 'assinatura' é obrigatório.");
    });

    test('resposta sem texto usa uma mensagem pelo status', () async {
      final indisponivel = await errorFrom(const FakeResponse(503, 'ruim'));
      final limite = await errorFrom(const FakeResponse(429, null));

      expect(indisponivel.message, contains('indisponível'));
      expect(limite.message, contains('Muitas solicitações'));
    });

    test('lê {error} do formato antigo', () async {
      final error = await errorFrom(
        const FakeResponse(409, {'error': 'Email já cadastrado'}),
      );

      expect(error.message, 'Email já cadastrado');
      expect(error.statusCode, 409);
    });

    test('lê {errors: [{campo, mensagem}]} do formato antigo', () async {
      final error = await errorFrom(
        const FakeResponse(400, {
          'errors': [
            {'campo': 'senha', 'mensagem': 'Senha fraca'},
          ],
        }),
      );

      expect(error.message, 'Senha fraca');
      expect(error.fields, {'senha': 'Senha fraca'});
    });

    test('falha de rede vira mensagem amigável', () async {
      final error = await errorFrom(const FakeResponse.networkError());

      expect(error.message, 'Não foi possível conectar ao servidor.');
      expect(error.isNetworkError, isTrue);
    });
  });

  group('token', () {
    test('envia o Bearer nas rotas autenticadas', () async {
      storage.accessToken = 'abc';
      final adapter = FakeApiAdapter((_) => const FakeResponse(200, {}));

      await clientWith(adapter).get('/usuarios/perfil');

      expect(bearer(adapter.requests.single), 'Bearer abc');
    });

    test('não envia token quando auth = false', () async {
      storage.accessToken = 'abc';
      final adapter = FakeApiAdapter((_) => const FakeResponse(200, {}));

      await clientWith(adapter).post('/auth/login', data: {}, auth: false);

      expect(bearer(adapter.requests.single), isNull);
    });
  });

  group('renovação do token', () {
    test('no 401 renova com o refresh token e repete a requisição', () async {
      storage
        ..accessToken = 'velho'
        ..refreshToken = 'refresh-1';

      final adapter = FakeApiAdapter((request) {
        if (request.path == '/auth/refresh') {
          expect(sentBody(request), {'refresh_token': 'refresh-1'});
          return const FakeResponse(200, {
            'success': true,
            'data': {'access_token': 'novo', 'refresh_token': 'refresh-2'},
          });
        }

        return bearer(request) == 'Bearer novo'
            ? const FakeResponse(200, {
                'success': true,
                'data': {'ok': true},
              })
            : const FakeResponse(401, {'message': 'Token expirado'});
      });

      final result = await clientWith(adapter).get('/usuarios/perfil');

      expect(result, {'ok': true});
      expect(storage.accessToken, 'novo');
      expect(storage.refreshToken, 'refresh-2');
      expect(adapter.paths, [
        'GET /usuarios/perfil',
        'POST /auth/refresh',
        'GET /usuarios/perfil',
      ]);
    });

    test('vários 401 ao mesmo tempo fazem uma única renovação', () async {
      storage
        ..accessToken = 'velho'
        ..refreshToken = 'refresh-1';

      final adapter = FakeApiAdapter((request) {
        if (request.path == '/auth/refresh') {
          return const FakeResponse(200, {
            'success': true,
            'data': {'access_token': 'novo', 'refresh_token': 'refresh-2'},
          });
        }

        return bearer(request) == 'Bearer novo'
            ? const FakeResponse(200, {'success': true, 'data': 'ok'})
            : const FakeResponse(401, {
                'message': 'Token expirado',
              }, delay: Duration(milliseconds: 20));
      });

      final client = clientWith(adapter);
      final results = await Future.wait([
        client.get('/a'),
        client.get('/b'),
        client.get('/c'),
      ]);

      expect(results, ['ok', 'ok', 'ok']);
      expect(
        adapter.paths.where((p) => p == 'POST /auth/refresh'),
        hasLength(1),
      );
    });

    test('se a renovação falha, limpa a sessão e avisa', () async {
      storage
        ..accessToken = 'velho'
        ..refreshToken = 'refresh-revogado';

      final adapter = FakeApiAdapter((request) {
        if (request.path == '/auth/refresh') {
          return const FakeResponse(401, {'message': 'Refresh inválido'});
        }
        return const FakeResponse(401, {'message': 'Token expirado'});
      });

      final client = clientWith(adapter);
      var expiredEvents = 0;
      client.sessionExpired.listen((_) => expiredEvents++);

      await expectLater(
        client.get('/usuarios/perfil'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      await Future<void>.delayed(Duration.zero);

      expect(storage.accessToken, isNull);
      expect(storage.refreshToken, isNull);
      expect(expiredEvents, 1);
    });

    test('sem refresh token (API antiga), encerra a sessão sem chamar /auth/refresh', () async {
      storage.accessToken = 'velho';
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(401, {'error': 'Token inválido ou expirado'}),
      );

      await expectLater(
        clientWith(adapter).get('/usuarios/perfil'),
        throwsA(isA<ApiException>()),
      );

      expect(adapter.paths, ['GET /usuarios/perfil']);
      expect(storage.accessToken, isNull);
    });

    test('falha de rede ao renovar mantém a sessão', () async {
      storage
        ..accessToken = 'velho'
        ..refreshToken = 'refresh-1';

      final adapter = FakeApiAdapter((request) {
        if (request.path == '/auth/refresh') {
          return const FakeResponse.networkError();
        }
        return const FakeResponse(401, {'message': 'Token expirado'});
      });

      await expectLater(
        clientWith(adapter).get('/usuarios/perfil'),
        throwsA(isA<ApiException>()),
      );

      expect(storage.accessToken, 'velho');
      expect(storage.refreshToken, 'refresh-1');
    });

    test('401 no login (sem token) não tenta renovar', () async {
      storage.refreshToken = 'refresh-1';
      final adapter = FakeApiAdapter(
        (_) => const FakeResponse(401, {'message': 'Credenciais inválidas'}),
      );

      await expectLater(
        clientWith(adapter).post('/auth/login', data: {}, auth: false),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Credenciais inválidas',
          ),
        ),
      );

      expect(adapter.paths, ['POST /auth/login']);
      expect(storage.refreshToken, 'refresh-1');
    });
  });

  test('requisições usam a URL base configurada', () async {
    final adapter = FakeApiAdapter((_) => const FakeResponse(200, {}));

    await clientWith(adapter).get('/cacambas', query: {'page': 2});

    final request = adapter.requests.single;
    expect(request.uri.toString(), 'http://api.test/api/cacambas?page=2');
    expect(request.method, 'GET');
    expect(request, isA<RequestOptions>());
  });
}
