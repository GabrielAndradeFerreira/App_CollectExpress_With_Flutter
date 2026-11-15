import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/core/widgets/app_bottom_navigation.dart';
import 'package:app_collect_express_with_flutter/core/widgets/app_menu_drawer.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/meus_pedidos_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _usuario(String tipoPerfil) => {
  'success': true,
  'data': {
    'id': 'u1',
    'nome_completo': 'Maria Souza',
    'email': 'maria@email.com',
    'tipo_perfil': tipoPerfil,
    'status': 'ATIVO',
  },
};

const _pedido = {
  'id': 'a1',
  'data_pedido': '2026-10-20T10:00:00.000Z',
  'data_inicio': '2026-10-28',
  'dias_aluguel': 3,
  'preco_final': 450,
  'status_pagamento': 'PENDENTE',
  'status_aluguel': 'AGUARDANDO_ENTREGA',
  'cacambeiro_nome': 'Caçambas Express',
};

final _semSessao = FakeResponse(401, {
  'success': false,
  'error': {'code': 'UNAUTHORIZED', 'message': 'Token ausente'},
});

/// Abre [tela] com a API simulada. Com [tipoPerfil], já começa logado.
Future<(FakeApiAdapter, InMemoryTokenStorage)> _abrir(
  WidgetTester tester,
  Widget tela, {
  String? tipoPerfil,
  FakeResponse Function(RequestOptions request)? handler,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage(
    accessToken: tipoPerfil == null ? null : 'token',
    refreshToken: tipoPerfil == null ? null : 'refresh',
  );
  final adapter = FakeApiAdapter((request) {
    if (request.path == '/usuarios/perfil') {
      return tipoPerfil == null
          ? _semSessao
          : FakeResponse(200, _usuario(tipoPerfil));
    }
    if (request.path == '/auth/logout') {
      return const FakeResponse(200, {'success': true, 'data': null});
    }
    return handler?.call(request) ??
        FakeResponse(404, {'success': false, 'error': 'não encontrado'});
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
        home: tela,
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('tela de login')),
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (adapter, tokens);
}

/// Tela mínima com o drawer e a barra do cliente.
class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      endDrawer: AppMenuDrawer(),
      body: SizedBox.shrink(),
      bottomNavigationBar: CustomerBottomNavigation(currentIndex: 0),
    );
  }
}

Future<void> _abrirDrawer(WidgetTester tester) async {
  tester.state<ScaffoldState>(find.byType(Scaffold).first).openEndDrawer();
  await tester.pumpAndSettle();
}

void main() {
  group('meus pedidos', () {
    testWidgets('lista os pedidos do cliente vindos da API', (tester) async {
      final (adapter, _) = await _abrir(
        tester,
        const MeusPedidosPage(),
        tipoPerfil: 'CONSUMIDOR',
        handler: (request) {
          if (request.path == '/alugueis/meus') {
            return const FakeResponse(200, {
              'success': true,
              'data': {
                'items': [_pedido],
                'pagination': {
                  'total': 1,
                  'page': 1,
                  'per_page': 20,
                  'total_pages': 1,
                },
              },
            });
          }
          return const FakeResponse(404, {'success': false});
        },
      );

      expect(adapter.paths, contains('GET /alugueis/meus'));
      expect(find.text('Caçambas Express'), findsOneWidget);
      expect(find.text('Aguardando entrega'), findsOneWidget);
      expect(find.text('Período contratado: 3 dias'), findsOneWidget);
      expect(find.text('Acompanhar Pedido'), findsOneWidget);
      expect(find.text('Alugar Outra Caçamba'), findsOneWidget);
    });

    testWidgets('sem pedidos, mostra o convite para alugar', (tester) async {
      await _abrir(
        tester,
        const MeusPedidosPage(),
        tipoPerfil: 'CONSUMIDOR',
        handler: (_) => const FakeResponse(200, {
          'success': true,
          'data': {
            'items': [],
            'pagination': {
              'total': 0,
              'page': 1,
              'per_page': 20,
              'total_pages': 1,
            },
          },
        }),
      );

      expect(find.text('Nenhum pedido no momento'), findsOneWidget);
      expect(find.text('Buscar Caçambas Disponíveis'), findsOneWidget);
    });

    testWidgets('sem login, pede para entrar', (tester) async {
      await _abrir(
        tester,
        const MeusPedidosPage(),
        handler: (_) => _semSessao,
      );

      expect(find.text('Entre na sua conta para continuar.'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Entrar'), findsOneWidget);
    });
  });

  group('drawer e barra de navegação', () {
    testWidgets('deslogado: mostra login e cadastro', (tester) async {
      await _abrir(tester, const _Host());
      await _abrirDrawer(tester);

      expect(find.text('Olá, bem-vindo!'), findsOneWidget);
      expect(find.text('LOGIN'), findsOneWidget);
      expect(find.text('CADASTRE-SE'), findsOneWidget);
      expect(find.text('SAIR'), findsNothing);
      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('fornecedor: mostra o painel e a gestão de pedidos', (
      tester,
    ) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'CACAMBEIRO');
      await _abrirDrawer(tester);

      expect(find.text('Olá, Maria Souza'), findsOneWidget);
      expect(find.text('Fornecedor de Caçambas'), findsOneWidget);
      expect(find.text('MEU PAINEL'), findsOneWidget);
      expect(find.text('GESTÃO PEDIDOS'), findsOneWidget);
      expect(find.text('PAINEL ADMIN'), findsNothing);
      expect(find.text('LOGIN'), findsNothing);
      expect(find.text('CADASTRE-SE'), findsNothing);
      expect(find.text('Gestão'), findsOneWidget);
      expect(find.text('Painel'), findsOneWidget);
    });

    testWidgets('admin: mostra o painel admin', (tester) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'ADMIN');
      await _abrirDrawer(tester);

      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('PAINEL ADMIN'), findsOneWidget);
      expect(find.text('MEU PAINEL'), findsNothing);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('sair encerra a sessão e volta para a tela inicial', (
      tester,
    ) async {
      final (adapter, tokens) = await _abrir(
        tester,
        const _Host(),
        tipoPerfil: 'CONSUMIDOR',
      );
      await _abrirDrawer(tester);

      expect(find.text('MEUS PEDIDOS'), findsOneWidget);

      await tester.tap(find.text('SAIR'));
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('POST /auth/logout'));
      expect(tokens.accessToken, isNull);
      // A rota "/" é a tela inicial (aqui, o próprio _Host); o login não abre.
      expect(find.byType(_Host), findsOneWidget);
      expect(find.text('tela de login'), findsNothing);
      expect(find.text('Você saiu da sua conta.'), findsOneWidget);
    });
  });
}
