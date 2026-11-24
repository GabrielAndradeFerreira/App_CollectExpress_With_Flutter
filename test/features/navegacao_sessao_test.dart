import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/core/widgets/app_bottom_navigation.dart';
import 'package:app_collect_express_with_flutter/core/widgets/app_logo.dart';
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
          AppRoutes.adminHome: (_) =>
              const Scaffold(body: Text('painel do admin')),
          AppRoutes.supplierHome: (_) =>
              const Scaffold(body: Text('painel do fornecedor')),
          AppRoutes.cart: (_) => const Scaffold(body: Text('tela do carrinho')),
          AppRoutes.customerProfile: (_) =>
              const Scaffold(body: Text('perfil do cliente')),
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

/// Tela mínima com a barra das telas de reciclagem.
class _HostReciclagem extends StatelessWidget {
  const _HostReciclagem();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
      bottomNavigationBar: RecyclingBottomNavigation(aba: AbaReciclagem.inicio),
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
      expect(find.text('SAIBA MAIS'), findsOneWidget);
      expect(find.text('SERVIÇOS'), findsOneWidget);
      expect(find.text('MODELOS'), findsOneWidget);
      expect(find.text('SAIR'), findsNothing);
      expect(find.text('MEU CARRINHO'), findsNothing);
      expect(find.text('Pedidos'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('cliente: mostra o catálogo e esconde o saiba mais', (
      tester,
    ) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'CONSUMIDOR');
      await _abrirDrawer(tester);

      expect(find.text('Cliente'), findsOneWidget);
      expect(find.text('SERVIÇOS'), findsOneWidget);
      expect(find.text('MODELOS'), findsOneWidget);
      expect(find.text('MEU CARRINHO'), findsOneWidget);
      expect(find.text('MEUS PEDIDOS'), findsOneWidget);
      expect(find.text('SAIBA MAIS'), findsNothing);
      expect(find.text('CADASTRE-SE'), findsNothing);
    });

    // Quem saía do carrinho no meio da compra não tinha como voltar.
    testWidgets('cliente: MEU CARRINHO mostra quantas caçambas há e abre o '
        'carrinho', (tester) async {
      await _abrir(
        tester,
        const _Host(),
        tipoPerfil: 'CONSUMIDOR',
        handler: (request) {
          if (request.path == '/carrinho') {
            return const FakeResponse(200, {
              'success': true,
              'data': {
                'id': 'k1',
                'itens': [],
                'resumo': {'quantidade_itens': 3},
              },
            });
          }
          return const FakeResponse(404, {'success': false});
        },
      );
      await _abrirDrawer(tester);

      expect(
        find.descendant(
          of: find.widgetWithText(AppDrawerItem, 'MEU CARRINHO'),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('MEU CARRINHO'));
      await tester.pumpAndSettle();

      expect(find.text('tela do carrinho'), findsOneWidget);
    });

    testWidgets('cliente com carrinho vazio não vê contador', (tester) async {
      await _abrir(
        tester,
        const _Host(),
        tipoPerfil: 'CONSUMIDOR',
        handler: (_) => const FakeResponse(200, {
          'success': true,
          'data': {'id': null, 'itens': []},
        }),
      );
      await _abrirDrawer(tester);

      expect(
        find.descendant(
          of: find.widgetWithText(AppDrawerItem, 'MEU CARRINHO'),
          matching: find.text('0'),
        ),
        findsNothing,
      );
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
      expect(find.text('SAIBA MAIS'), findsNothing);
      expect(find.text('SERVIÇOS'), findsNothing);
      expect(find.text('MODELOS'), findsNothing);
      expect(find.text('MEU CARRINHO'), findsNothing);
      expect(find.text('Gestão'), findsOneWidget);
      expect(find.text('Painel'), findsOneWidget);
    });

    testWidgets('admin: mostra o painel admin', (tester) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'ADMIN');
      await _abrirDrawer(tester);

      expect(find.text('Administrador'), findsOneWidget);
      expect(find.text('PAINEL ADMIN'), findsOneWidget);
      expect(find.text('MEU PAINEL'), findsNothing);
      expect(find.text('SAIBA MAIS'), findsNothing);
      expect(find.text('SERVIÇOS'), findsNothing);
      expect(find.text('MODELOS'), findsNothing);
      expect(find.text('Admin'), findsOneWidget);
    });

    testWidgets('admin: INÍCIO leva ao painel do admin', (tester) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'ADMIN');
      await _abrirDrawer(tester);

      await tester.tap(find.text('INÍCIO'));
      await tester.pumpAndSettle();

      expect(find.text('painel do admin'), findsOneWidget);
    });

    testWidgets('fornecedor: INÍCIO leva ao painel do fornecedor', (
      tester,
    ) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'CACAMBEIRO');
      await _abrirDrawer(tester);

      await tester.tap(find.text('INÍCIO'));
      await tester.pumpAndSettle();

      expect(find.text('painel do fornecedor'), findsOneWidget);
    });

    testWidgets('admin: o logo do menu leva ao painel do admin', (
      tester,
    ) async {
      await _abrir(tester, const _Host(), tipoPerfil: 'ADMIN');
      await _abrirDrawer(tester);

      await tester.tap(find.byTooltip('Ir para o início'));
      await tester.pumpAndSettle();

      expect(find.text('painel do admin'), findsOneWidget);
    });

    testWidgets('admin: o logo do cabeçalho leva ao painel do admin', (
      tester,
    ) async {
      await _abrir(
        tester,
        const Scaffold(body: AppLogo()),
        tipoPerfil: 'ADMIN',
      );

      await tester.tap(find.byTooltip('Ir para o início'));
      await tester.pumpAndSettle();

      expect(find.text('painel do admin'), findsOneWidget);
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

  // A aba "Perfil" só existe para o parceiro. Quem já entrou como cliente,
  // fornecedor ou admin não vê uma aba que abriria o login por engano.
  group('barra da reciclagem: sem aba que abra o login por engano', () {
    for (final tipoPerfil in [null, 'CONSUMIDOR', 'CACAMBEIRO', 'ADMIN']) {
      testWidgets(': não há aba "Perfil"', (
        tester,
      ) async {
        await _abrir(tester, const _HostReciclagem(), tipoPerfil: tipoPerfil);

        expect(find.text('Materiais'), findsOneWidget);
        expect(find.text('Perfil'), findsNothing);
      });
    }

    testWidgets('parceiro: a aba "Perfil" existe', (tester) async {
      await _abrir(tester, const _HostReciclagem(), tipoPerfil: 'PARCEIRO');

      expect(find.text('Perfil'), findsOneWidget);
    });
  });}
