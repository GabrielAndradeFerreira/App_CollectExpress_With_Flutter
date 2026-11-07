import 'package:app_collect_express_with_flutter/core/models/area_atendimento.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/admin_geral_page.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/presentation/pages/cacamba_details_page.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/presentation/pages/cacambas_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/local_entrega_fake.dart';

const _cacamba = {
  'id': 'c1',
  'cacambeiro_id': 'u1',
  'nome': 'Caçamba Standard',
  'tipo_residuo': 'Entulho de Obra',
  'tamanho_m3': 4,
  'preco_diaria': 150,
  'foto_url': null,
  'disponivel': true,
};

final _cacambaMadeira = <String, dynamic>{
  ..._cacamba,
  'id': 'c2',
  'nome': 'Caçamba Madeira',
  'tipo_residuo': 'Madeira',
};

Map<String, dynamic> _pagina(List<Map<String, dynamic>> itens) => {
  'success': true,
  'data': {
    'items': itens,
    'pagination': {
      'total': itens.length,
      'page': 1,
      'per_page': 20,
      'total_pages': 1,
    },
  },
};

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  FakeResponse Function(RequestOptions request) handler, {
  InMemoryTokenStorage? storage,
  LocalEntrega? local = localDeTeste,
}) async {
  // Telas compridas: evita itens fora da área visível no teste.
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = storage ?? InMemoryTokenStorage();
  final adapter = FakeApiAdapter(handler);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: tokens, adapter: adapter),
        ),
        localEntregaInicial(local),
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
  return adapter;
}

void main() {
  testWidgets('catálogo mostra as caçambas da API e filtra por categoria', (
    tester,
  ) async {
    final adapter = await _abrir(tester, const CacambasPage(), (request) {
      final tipo = request.queryParameters['tipo_residuo'];
      return FakeResponse(
        200,
        _pagina([
          if (tipo == null || tipo == 'Entulho de Obra') _cacamba,
          if (tipo == null || tipo == 'Madeira') _cacambaMadeira,
        ]),
      );
    });

    expect(find.text('Caçamba Standard'), findsOneWidget);
    expect(find.text('Caçamba Madeira'), findsOneWidget);
    expect(find.text('R\$ 150,00'), findsNWidgets(2));
    expect(find.text('4m³'), findsNWidgets(2));

    // Os filtros vêm das categorias das caçambas.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Madeira'));
    await tester.pumpAndSettle();

    expect(adapter.requests.last.queryParameters['tipo_residuo'], 'Madeira');
    expect(adapter.requests.last.queryParameters['latitude'], -23.5614);
    expect(adapter.requests.last.queryParameters['longitude'], -46.6559);
    expect(adapter.requests.last.queryParameters['area'], 'dentro');
    expect(find.text('Caçamba Standard'), findsNothing);
    expect(find.text('Caçamba Madeira'), findsOneWidget);
  });

  testWidgets('catálogo mostra o erro da API com "Tentar novamente"', (
    tester,
  ) async {
    await _abrir(
      tester,
      const CacambasPage(),
      (_) => const FakeResponse.networkError(),
    );

    expect(find.text('Não foi possível conectar ao servidor.'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  group('detalhe da caçamba', () {
    FakeResponse detalhe(RequestOptions request) {
      if (request.path == '/cacambas/c1') {
        return const FakeResponse(200, {
          'success': true,
          'data': {
            ..._cacamba,
            'cacambeiro': {
              'id': 'u1',
              'nome_completo': 'Fornecedor Teste',
              'horario_inicio': '08:00:00',
              'horario_fim': '18:00:00',
              'taxa_entrega': 40,
              'nota_media': 4.5,
              'total_avaliacoes': 2,
            },
            'avaliacoes': [],
          },
        });
      }
      if (request.path == '/usuarios/perfil') {
        return const FakeResponse(200, {
          'success': true,
          'data': {
            'id': 'u2',
            'nome_completo': 'Cliente',
            'email': 'c@teste.com',
            'tipo_perfil': 'CONSUMIDOR',
          },
        });
      }
      if (request.path == '/carrinho/itens') {
        return const FakeResponse(201, {
          'success': true,
          'data': {'id': 'k1', 'itens': []},
        });
      }
      return const FakeResponse(200, {
        'success': true,
        'data': {'id': null, 'itens': []},
      });
    }

    testWidgets('mostra os dados e o fornecedor', (tester) async {
      await _abrir(tester, const CacambaDetailsPage(cacambaId: 'c1'), detalhe);

      expect(find.text('Caçamba Standard'), findsOneWidget);
      expect(find.text('R\$ 150,00'), findsOneWidget);
      expect(find.text('Fornecedor: Fornecedor Teste'), findsOneWidget);
      expect(find.textContaining('Taxa de entrega: R\$ 40,00'), findsOneWidget);
    });

    testWidgets('sem login, adicionar ao carrinho abre o login', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const CacambaDetailsPage(cacambaId: 'c1'),
        detalhe,
      );

      await tester.tap(find.text('Adicionar ao Carrinho'));
      await tester.pumpAndSettle();

      expect(find.text('tela de login'), findsOneWidget);
      expect(adapter.paths, isNot(contains('POST /carrinho/itens')));
    });

    testWidgets('logado, adiciona ao carrinho com quantidade e dias', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const CacambaDetailsPage(cacambaId: 'c1'),
        detalhe,
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Adicionar ao Carrinho'));
      await tester.pumpAndSettle();

      final pedido = adapter.requests.firstWhere(
        (r) => r.path == '/carrinho/itens',
      );
      expect(sentBody(pedido), {
        'cacamba_id': 'c1',
        'quantidade': 2,
        'dias_aluguel': 3,
      });
    });
  });

  testWidgets('painel do admin mostra as métricas e os pedidos recentes', (
    tester,
  ) async {
    await _abrir(tester, const AdminGeralPage(), (request) {
      if (request.path == '/admin/dashboard') {
        return const FakeResponse(200, {
          'success': true,
          'data': {
            'total_usuarios': 12,
            'total_pedidos': 5,
            'receita_total': 1500,
            'lucro_plataforma': 75,
            'cacambeiros_ativos': 3,
            'pedidos_por_status': {},
            'pedidos_ao_longo_do_tempo': [],
          },
        });
      }
      return FakeResponse(200, {
        'success': true,
        'data': {
          'items': [
            {
              'id': 'p1',
              'consumidor_nome': 'Maria',
              'cacambeiro_nome': 'Fornecedor Teste',
              'preco_final': '450.00',
              'status_aluguel': 'EM_USO',
              'data_pedido': '2026-10-20T15:00:00.000Z',
            },
          ],
          'pagination': {'total': 1, 'page': 1, 'total_pages': 1},
        },
      });
    }, storage: InMemoryTokenStorage(accessToken: 'jwt'));

    expect(find.text('12'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('R\$ 1.500,00'), findsOneWidget);
    expect(find.text('Pedido de Maria'), findsOneWidget);
    expect(find.text('Em uso'), findsOneWidget);
    expect(find.text('Nenhum pedido nos últimos 7 dias'), findsOneWidget);
  });
}
