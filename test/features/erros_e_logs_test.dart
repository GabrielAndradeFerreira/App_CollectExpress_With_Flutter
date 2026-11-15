import 'package:app_collect_express_with_flutter/core/logging/log_remoto.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_exception.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/core/widgets/async_value_view.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/configuracoes_admin_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/perfil_loja_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/data/sessao_provider.dart';
import 'package:app_collect_express_with_flutter/main.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _ok(Object? data) => {'success': true, 'data': data};

const _naoEncontrado = FakeResponse(404, {
  'success': false,
  'message': 'não encontrado',
});

ApiClient _cliente(
  FakeApiAdapter adapter, {
  List<Duration> retry = const [],
  bool logado = true,
}) {
  return ApiClient(
    storage: InMemoryTokenStorage(accessToken: logado ? 'jwt' : null),
    adapter: adapter,
    retryDelays: retry,
  );
}

Map<String, dynamic> _fornecedor({
  String nome = 'Caçambas Alfa',
  String telefone = '11988887777',
  String inicio = '08:00:00',
  String fim = '18:00:00',
  double taxa = 50,
}) => {
  'id': 'u1',
  'nome_completo': nome,
  'email': 'alfa@loja.com',
  'tipo_perfil': 'CACAMBEIRO',
  'status': 'ATIVO',
  'documento': '12345678000190',
  'telefone': telefone,
  'detalhes_cacambeiro': {
    'horario_inicio': inicio,
    'horario_fim': fim,
    'raio_entrega_km': 20,
    'taxa_entrega': taxa,
  },
};

void main() {
  setUp(() {
    LogRemoto.reiniciar();
    SharedPreferences.setMockInitialValues({});
  });

  group('LogRemoto', () {
    test('envia o relato para /logs/app com versão e plataforma', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final log = LogRemoto(_cliente(adapter));

      await log.registrar(
        codigo: 'TESTE',
        mensagem: 'algo falhou',
        tela: '/cliente/agendar',
        statusHttp: 400,
        detalhes: {'campo': 'data_inicio'},
      );

      final corpo = sentBody(adapter.requests.single);

      expect(adapter.paths.single, 'POST /logs/app');
      expect(corpo['codigo'], 'TESTE');
      expect(corpo['nivel'], 'ERRO');
      expect(corpo['tela'], '/cliente/agendar');
      expect(corpo['status_http'], 400);
      expect(corpo['app_versao'], LogRemoto.versao);
      expect(corpo['plataforma'], isNotEmpty);
      expect(corpo['detalhes'], {'campo': 'data_inicio'});
    });

    test('o mesmo relato seguido é enviado uma vez só', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final log = LogRemoto(_cliente(adapter));

      for (var i = 0; i < 3; i++) {
        await log.registrar(codigo: 'IGUAL', mensagem: 'repetido');
      }
      await log.registrar(codigo: 'IGUAL', mensagem: 'outra mensagem');

      expect(adapter.requests, hasLength(2));
    });

    test('limita a quantidade de relatos por execução', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final log = LogRemoto(_cliente(adapter));

      for (var i = 0; i < LogRemoto.limiteDaSessao + 10; i++) {
        await log.registrar(codigo: 'RAJADA', mensagem: 'erro $i');
      }

      expect(adapter.requests, hasLength(LogRemoto.limiteDaSessao));
    });

    test('falha ao enviar nunca vira exceção', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse.networkError());
      final log = LogRemoto(_cliente(adapter));

      await expectLater(
        log.registrar(codigo: 'X', mensagem: 'sem rede'),
        completes,
      );
    });

    test('registrarErro: 401 é ignorado e rede vira aviso', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final log = LogRemoto(_cliente(adapter));

      await log.registrarErro(
        const ApiException('Sessão', statusCode: 401),
        tela: '/x',
      );
      expect(adapter.requests, isEmpty);

      await log.registrarErro(
        const ApiException('Não foi possível conectar ao servidor.'),
        tela: '/pedidos',
        acao: 'carregar tela',
      );

      final corpo = sentBody(adapter.requests.single);

      expect(corpo['codigo'], 'APP_REDE');
      expect(corpo['nivel'], 'AVISO');
      expect(corpo['tela'], '/pedidos');
      expect(corpo['detalhes'], {'acao': 'carregar tela'});
    });

    test('registrarErro guarda o código e os campos da API', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final log = LogRemoto(_cliente(adapter));

      await log.registrarErro(
        const ApiException(
          'Dados inválidos.',
          statusCode: 400,
          code: 'VALIDATION_ERROR',
          fields: {'data_inicio': 'inválida'},
        ),
        tela: '/cliente/agendar',
      );

      final corpo = sentBody(adapter.requests.single);

      expect(corpo['codigo'], 'VALIDATION_ERROR');
      expect(corpo['status_http'], 400);
      expect(corpo['detalhes'], {
        'campos': {'data_inicio': 'inválida'},
      });
    });

    test('exceção comum vira APP_EXCECAO com a pilha', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final log = LogRemoto(_cliente(adapter));

      await log.registrarErro(StateError('quebrou'), pilha: StackTrace.current);

      final corpo = sentBody(adapter.requests.single);

      expect(corpo['codigo'], 'APP_EXCECAO');
      expect(corpo['mensagem'], contains('quebrou'));
      expect((corpo['detalhes'] as Map)['pilha'], isNotEmpty);
    });
  });

  group('repetição de consultas', () {
    test('GET com 503 é repetido até dar certo', () async {
      var chamadas = 0;
      final adapter = FakeApiAdapter((_) {
        chamadas++;
        return chamadas < 3
            ? const FakeResponse(503, 'Service Unavailable')
            : FakeResponse(200, _ok({'ok': true}));
      });
      final client = _cliente(
        adapter,
        retry: const [Duration.zero, Duration.zero],
      );

      final dados = await client.get('/qualquer');

      expect(dados, {'ok': true});
      expect(adapter.requests, hasLength(3));
    });

    test('queda de rede em GET repete e, se persistir, avisa', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse.networkError());
      final client = _cliente(
        adapter,
        retry: const [Duration.zero, Duration.zero],
      );

      await expectLater(
        client.get('/qualquer'),
        throwsA(
          isA<ApiException>().having((e) => e.isNetworkError, 'rede', isTrue),
        ),
      );
      expect(adapter.requests, hasLength(3));
    });

    test('POST nunca é repetido (poderia duplicar o pedido)', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(503, 'ruim'));
      final client = _cliente(
        adapter,
        retry: const [Duration.zero, Duration.zero],
      );

      await expectLater(
        client.post('/alugueis/checkout', data: {'a': 1}),
        throwsA(isA<ApiException>()),
      );
      expect(adapter.requests, hasLength(1));
    });

    test('erro do cliente (400/404) não é repetido', () async {
      final adapter = FakeApiAdapter((_) => _naoEncontrado);
      final client = _cliente(
        adapter,
        retry: const [Duration.zero, Duration.zero],
      );

      await expectLater(client.get('/x'), throwsA(isA<ApiException>()));
      expect(adapter.requests, hasLength(1));
    });

    test('sem atrasos configurados não repete', () async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(503, 'ruim'));
      final client = _cliente(adapter);

      await expectLater(client.get('/x'), throwsA(isA<ApiException>()));
      expect(adapter.requests, hasLength(1));
    });
  });

  group('mensagens de erro', () {
    testWidgets('showApiError mostra o texto e relata a falha com a tela', (
      tester,
    ) async {
      final adapter = FakeApiAdapter((_) => const FakeResponse(202, {}));
      final tokens = InMemoryTokenStorage(accessToken: 'jwt');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(storage: tokens, adapter: adapter),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showApiError(
                    context,
                    const ApiException(
                      'Dados inválidos.',
                      statusCode: 400,
                      code: 'VALIDATION_ERROR',
                    ),
                    acao: 'confirmar pedido',
                  ),
                  child: const Text('falhar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('falhar'));
      await tester.pump();

      expect(find.text('Dados inválidos.'), findsOneWidget);

      await tester.pumpAndSettle();

      final envio = adapter.requests.singleWhere((r) => r.path == '/logs/app');
      final corpo = sentBody(envio);

      expect(corpo['codigo'], 'VALIDATION_ERROR');
      expect((corpo['detalhes'] as Map)['acao'], 'confirmar pedido');
    });

    testWidgets('showApiError funciona sem ProviderScope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showApiError(context, 'qualquer coisa'),
                child: const Text('falhar'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('falhar'));
      await tester.pump();

      expect(find.text('Algo deu errado. Tente novamente.'), findsOneWidget);
    });
  });

  group('perfil da loja do fornecedor', () {
    FakeResponse Function(RequestOptions) api({
      Map<String, dynamic>? fornecedor,
      FakeResponse? respostaPerfil,
      FakeResponse? respostaLoja,
      List<Map<String, dynamic>>? atuais,
    }) {
      var atual = fornecedor ?? _fornecedor();

      return (request) {
        switch ((request.method, request.path)) {
          case ('GET', '/usuarios/perfil'):
            return FakeResponse(200, _ok(atual));
          case ('PUT', '/usuarios/perfil'):
            if (respostaPerfil != null) return respostaPerfil;
            final corpo = sentBody(request);
            atual = {
              ...atual,
              'nome_completo': corpo['nome_completo'] ?? atual['nome_completo'],
              'telefone': corpo['telefone'] ?? atual['telefone'],
            };
            return FakeResponse(200, _ok(atual));
          case ('PUT', '/cacambeiros/me'):
            if (respostaLoja != null) return respostaLoja;
            final corpo = sentBody(request);
            atual = {
              ...atual,
              'detalhes_cacambeiro': {
                ...(atual['detalhes_cacambeiro'] as Map<String, dynamic>),
                if (corpo['horario_inicio'] != null)
                  'horario_inicio': '${corpo['horario_inicio']}:00',
                if (corpo['horario_fim'] != null)
                  'horario_fim': '${corpo['horario_fim']}:00',
                if (corpo['taxa_entrega'] != null)
                  'taxa_entrega': corpo['taxa_entrega'],
              },
            };
            return FakeResponse(200, _ok(atual['detalhes_cacambeiro']));
          case ('GET', '/cacambeiros/me/area'):
            return FakeResponse(200, _ok({'definida': false}));
          case ('GET', '/cacambeiros/me/assinatura'):
            return const FakeResponse(404, {
              'success': false,
              'message': 'Nenhuma assinatura cadastrada.',
              'code': 'SIGNATURE_NOT_FOUND',
            });
          case ('GET', '/chat/nao-lidas'):
            return FakeResponse(200, _ok({'conversas': 0, 'mensagens': 0}));
        }

        return _naoEncontrado;
      };
    }

    Future<FakeApiAdapter> abrir(
      WidgetTester tester,
      FakeResponse Function(RequestOptions) handler,
    ) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tokens = InMemoryTokenStorage(accessToken: 'jwt');
      final adapter = FakeApiAdapter(handler);

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(storage: tokens, adapter: adapter),
            ),
          ],
          child: const MaterialApp(home: PerfilLojaPage()),
        ),
      );
      await tester.pumpAndSettle();

      return adapter;
    }

    String valorDe(WidgetTester tester, String chave) =>
        tester.widget<TextFormField>(find.byKey(Key(chave))).controller!.text;

    testWidgets('mostra os dados reais da conta, não dados de exemplo', (
      tester,
    ) async {
      await abrir(tester, api());

      expect(valorDe(tester, 'loja_nome'), 'Caçambas Alfa');
      expect(valorDe(tester, 'loja_telefone'), '11988887777');
      expect(valorDe(tester, 'loja_taxa'), '50,00');
      expect(find.text('Abre às 08:00'), findsOneWidget);
      expect(find.text('Fecha às 18:00'), findsOneWidget);
      expect(find.text('**.***.678/0001-90'), findsOneWidget);
      expect(find.text('alfa@loja.com'), findsOneWidget);

      // Os dados de exemplo que existiam antes não aparecem mais.
      expect(find.textContaining('São Paulo Express'), findsNothing);
      expect(find.textContaining('Banco do Brasil'), findsNothing);
    });

    testWidgets(
      'salvar envia nome, telefone, horário e taxa e relê do servidor',
      (tester) async {
        final adapter = await abrir(tester, api());

        await tester.enterText(
          find.byKey(const Key('loja_nome')),
          'Caçambas Alfa Express',
        );
        await tester.enterText(
          find.byKey(const Key('loja_telefone')),
          '11977776666',
        );
        await tester.enterText(find.byKey(const Key('loja_taxa')), '65,5');

        await tester.tap(find.byKey(const Key('loja_fecha')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await tester.ensureVisible(find.byKey(const Key('loja_salvar')));
        await tester.tap(find.byKey(const Key('loja_salvar')));
        await tester.pumpAndSettle();

        final perfil = sentBody(
          adapter.requests.firstWhere(
            (r) => r.method == 'PUT' && r.path == '/usuarios/perfil',
          ),
        );
        final loja = sentBody(
          adapter.requests.firstWhere(
            (r) => r.method == 'PUT' && r.path == '/cacambeiros/me',
          ),
        );

        expect(perfil, {
          'nome_completo': 'Caçambas Alfa Express',
          'telefone': '11977776666',
        });
        expect(loja['taxa_entrega'], 65.5);
        expect(loja['horario_inicio'], '08:00');
        expect(loja['horario_fim'], '18:00');

        expect(
          find.text('Dados da loja atualizados com sucesso!'),
          findsOneWidget,
        );
        // A tela volta a mostrar o que ficou salvo.
        expect(valorDe(tester, 'loja_nome'), 'Caçambas Alfa Express');
        expect(valorDe(tester, 'loja_taxa'), '65,50');
      },
    );

    testWidgets('sem mudança não chama a API', (tester) async {
      final adapter = await abrir(tester, api());

      await tester.ensureVisible(find.byKey(const Key('loja_salvar')));
      await tester.tap(find.byKey(const Key('loja_salvar')));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma alteração para salvar.'), findsOneWidget);
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    });

    testWidgets('mudar só a taxa não mexe no perfil do usuário', (
      tester,
    ) async {
      final adapter = await abrir(tester, api());

      await tester.enterText(find.byKey(const Key('loja_taxa')), '70');
      await tester.ensureVisible(find.byKey(const Key('loja_salvar')));
      await tester.tap(find.byKey(const Key('loja_salvar')));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.where(
          (r) => r.method == 'PUT' && r.path == '/usuarios/perfil',
        ),
        isEmpty,
      );
      expect(
        adapter.requests.where(
          (r) => r.method == 'PUT' && r.path == '/cacambeiros/me',
        ),
        hasLength(1),
      );
    });

    testWidgets('campos inválidos impedem o envio e mostram o motivo', (
      tester,
    ) async {
      final adapter = await abrir(tester, api());

      await tester.enterText(find.byKey(const Key('loja_nome')), 'ab');
      await tester.enterText(find.byKey(const Key('loja_telefone')), '123');
      await tester.enterText(find.byKey(const Key('loja_taxa')), '0');

      await tester.ensureVisible(find.byKey(const Key('loja_salvar')));
      await tester.tap(find.byKey(const Key('loja_salvar')));
      await tester.pumpAndSettle();

      expect(find.text('O nome deve ter pelo menos 3 letras'), findsOneWidget);
      expect(find.text('Informe um telefone válido'), findsOneWidget);
      expect(
        find.text('A taxa deve estar entre R\$ 0,01 e R\$ 99.999,99'),
        findsOneWidget,
      );
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
    });

    testWidgets('erro da API aparece no campo e na mensagem', (tester) async {
      await abrir(
        tester,
        api(
          respostaLoja: const FakeResponse(400, {
            'success': false,
            'message': 'Dados inválidos.',
            'code': 'VALIDATION_ERROR',
            'fields': {
              'taxa_entrega': 'A taxa deve estar entre 0,01 e 99.999,99.',
            },
          }),
        ),
      );

      await tester.enterText(find.byKey(const Key('loja_taxa')), '70');
      await tester.ensureVisible(find.byKey(const Key('loja_salvar')));
      await tester.tap(find.byKey(const Key('loja_salvar')));
      await tester.pumpAndSettle();

      expect(
        find.text('A taxa deve estar entre 0,01 e 99.999,99.'),
        findsWidgets,
      );
      expect(find.text('Dados da loja atualizados com sucesso!'), findsNothing);
    });

    testWidgets('perfil que não carrega mostra erro com nova tentativa', (
      tester,
    ) async {
      await abrir(
        tester,
        (request) => request.path == '/usuarios/perfil'
            ? const FakeResponse(500, {
                'success': false,
                'message': 'Erro interno no servidor.',
              })
            : api()(request),
      );

      expect(find.text('Erro interno no servidor.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
    });
  });

  group('sair da conta', () {
    Future<(FakeApiAdapter, InMemoryTokenStorage)> abrirConfiguracoes(
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 5000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tokens = InMemoryTokenStorage(
        accessToken: 'jwt',
        refreshToken: 'refresh',
      );
      final adapter = FakeApiAdapter((request) {
        if (request.path == '/usuarios/perfil') {
          return FakeResponse(
            200,
            _ok({
              'id': 'a1',
              'nome_completo': 'Admin',
              'email': 'admin@x.com',
              'tipo_perfil': 'ADMIN',
              'status': 'ATIVO',
            }),
          );
        }
        if (request.path == '/auth/logout') {
          return FakeResponse(200, _ok({}));
        }
        if (request.path == '/chat/nao-lidas') {
          return FakeResponse(200, _ok({'conversas': 0, 'mensagens': 0}));
        }
        return _naoEncontrado;
      });

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(storage: tokens, adapter: adapter),
            ),
          ],
          child: MaterialApp(
            initialRoute: '/configuracoes',
            routes: {
              '/configuracoes': (_) => const ConfiguracoesAdminPage(),
              AppRoutes.home: (_) => const Scaffold(body: Text('tela inicial')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      return (adapter, tokens);
    }

    testWidgets('o admin realmente encerra a sessão e volta ao início', (
      tester,
    ) async {
      final (adapter, tokens) = await abrirConfiguracoes(tester);

      await tester.ensureVisible(find.text('Sair da Conta Administrativa'));
      await tester.tap(find.text('Sair da Conta Administrativa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sair').last);
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('POST /auth/logout'));
      expect(tokens.accessToken, isNull);
      expect(find.text('tela inicial'), findsOneWidget);
    });
  });

  group('sessão expirada', () {
    testWidgets('leva para a tela inicial e avisa', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tokens = InMemoryTokenStorage(
        accessToken: 'jwt-vencido',
        refreshToken: 'refresh-vencido',
      );
      var tokenValido = true;
      final adapter = FakeApiAdapter((request) {
        if (!tokenValido) {
          // O token não vale mais e a renovação também falha.
          return const FakeResponse(401, {
            'success': false,
            'message': 'Token inválido ou expirado.',
            'code': 'INVALID_ACCESS_TOKEN',
          });
        }

        return switch (request.path) {
          '/usuarios/perfil' => FakeResponse(
            200,
            _ok({
              'id': 'u1',
              'nome_completo': 'Maria',
              'email': 'm@x.com',
              'tipo_perfil': 'CONSUMIDOR',
              'status': 'ATIVO',
            }),
          ),
          '/chat/nao-lidas' => FakeResponse(
            200,
            _ok({'conversas': 0, 'mensagens': 0}),
          ),
          _ => _naoEncontrado,
        };
      });

      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(storage: tokens, adapter: adapter),
            ),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              container = ProviderScope.containerOf(context);
              return const CollectApp();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(sessaoProvider).value?.nomeCompleto, 'Maria');

      // Uma chamada autenticada que falha em 401 e não consegue renovar.
      tokenValido = false;
      await tester.runAsync(
        () => expectLater(
          container.read(apiClientProvider).get('/carrinho'),
          throwsA(isA<ApiException>()),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(sessaoProvider).value, isNull);
      expect(container.read(sessaoExpiradaProvider), 1);
      expect(
        find.text('Sua sessão expirou. Entre novamente para continuar.'),
        findsOneWidget,
      );
    });
  });
}
