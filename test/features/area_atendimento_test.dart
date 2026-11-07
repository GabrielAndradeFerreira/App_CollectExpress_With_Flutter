import 'dart:convert';

import 'package:app_collect_express_with_flutter/core/models/area_atendimento.dart';
import 'package:app_collect_express_with_flutter/core/models/cacamba.dart';
import 'package:app_collect_express_with_flutter/core/models/endereco.dart';
import 'package:app_collect_express_with_flutter/core/models/usuario.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/area_atendimento_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/area_atendimento_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/painel_admin_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/perfil_loja_page.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/data/catalogo_repository.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/presentation/pages/cacamba_details_page.dart';
import 'package:app_collect_express_with_flutter/features/cacambas/presentation/pages/cacambas_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';
import '../helpers/local_entrega_fake.dart';

/// PNG transparente de 1x1 px, para o mapa não baixar imagens nos testes.
final _pngVazio = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

class _TilesVazios extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return MemoryImage(_pngVazio);
  }
}

const _dentro = {
  'id': 'c1',
  'cacambeiro_id': 'u1',
  'nome': 'Caçamba Standard',
  'tipo_residuo': 'Entulho de Obra',
  'tamanho_m3': 4,
  'preco_diaria': 150,
  'disponivel': true,
  'dentro_da_area': true,
  'distancia_km': 3.2,
  'area_definida': true,
};

const _fora = {
  'id': 'c9',
  'cacambeiro_id': 'u9',
  'nome': 'Caçamba Distante',
  'tipo_residuo': 'Madeira',
  'tamanho_m3': 5,
  'preco_diaria': 200,
  'disponivel': true,
  'dentro_da_area': false,
  'distancia_km': 12.34,
  'area_definida': true,
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

Map<String, dynamic> _ok(Object? data) => {'success': true, 'data': data};

const _paulista = {
  'cep': '01310100',
  'logradouro': 'Avenida Paulista',
  'bairro': 'Bela Vista',
  'cidade': 'São Paulo',
  'uf': 'SP',
  'cidade_estado': 'São Paulo - SP',
  'latitude': -23.5614,
  'longitude': -46.6559,
};

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  FakeResponse Function(RequestOptions request) handler, {
  InMemoryTokenStorage? storage,
  List<Override> overrides = const [],
  Map<String, WidgetBuilder> routes = const {},
  LocalEntrega? local = localDeTeste,
}) async {
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
        mapaTileProviderProvider.overrideWithValue(_TilesVazios()),
        localEntregaInicial(local),
        ...overrides,
      ],
      child: MaterialApp(
        home: tela,
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('tela de login')),
          AppRoutes.supplierProfile: (_) =>
              const Scaffold(body: Text('perfil da loja')),
          ...routes,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

const _fornecedorLogado = {
  'id': 'u1',
  'nome_completo': 'Fornecedor Teste',
  'email': 'f@teste.com',
  'tipo_perfil': 'CACAMBEIRO',
  'status': 'ATIVO',
};

void main() {
  group('modelos', () {
    test('LocalEntrega.fromCepJson exige coordenadas', () {
      final local = LocalEntrega.fromCepJson(_paulista);

      expect(local, isNotNull);
      expect(local!.cep, '01310100');
      expect(local.descricao, 'Avenida Paulista · São Paulo - SP');
      expect(
        LocalEntrega.fromCepJson({..._paulista, 'latitude': null}),
        isNull,
      );
    });

    test('LocalEntrega.fromEndereco usa as coordenadas salvas', () {
      const comCoordenadas = Endereco(
        cep: '01310-100',
        logradouro: 'Rua A',
        numero: '10',
        cidadeEstado: 'São Paulo - SP',
        latitude: -23.5,
        longitude: -46.6,
      );
      const semCoordenadas = Endereco(
        cep: '01310100',
        logradouro: 'Rua B',
        numero: '1',
        cidadeEstado: 'São Paulo - SP',
      );

      expect(LocalEntrega.fromEndereco(comCoordenadas)!.cep, '01310100');
      expect(LocalEntrega.fromEndereco(semCoordenadas), isNull);
      expect(LocalEntrega.formatarCep('01310100'), '01310-100');
    });

    test('Cacamba lê os dados da área de atendimento', () {
      final fora = Cacamba.fromJson(_fora);
      final semLocal = Cacamba.fromJson({
        'id': 'x',
        'nome': 'Sem local',
        'tipo_residuo': 'Madeira',
        'tamanho_m3': 3,
        'preco_diaria': 10,
        'dentro_da_area': null,
      });

      expect(fora.dentroDaArea, isFalse);
      expect(fora.podeAlugar, isFalse);
      expect(fora.distanciaKm, 12.34);
      expect(fora.areaDefinida, isTrue);
      expect(semLocal.dentroDaArea, isNull);
      expect(semLocal.podeAlugar, isTrue);
    });

    test('PendenciasFornecedor traduz os códigos da API', () {
      final pendencias = PendenciasFornecedor.fromJson({
        'area_definida': false,
        'assinatura_cadastrada': false,
        'pendencias': ['AREA_ATENDIMENTO', 'ASSINATURA', 'OUTRA'],
      });

      expect(pendencias.pendencias, [
        PendenciaFornecedor.areaAtendimento,
        PendenciaFornecedor.assinatura,
      ]);
      expect(PendenciasFornecedor.fromJson({}).temPendencias, isFalse);
    });

    test('raio do fornecedor pode ser nulo e não vai no corpo', () {
      final detalhes = Usuario.fromJson({
        'id': 'u',
        'nome_completo': 'F',
        'email': 'f@x.com',
        'tipo_perfil': 'CACAMBEIRO',
        'detalhes_cacambeiro': {
          'horario_inicio': '08:00:00',
          'horario_fim': '18:00:00',
          'raio_entrega_km': null,
          'taxa_entrega': 10,
        },
      }).detalhesCacambeiro!;

      expect(detalhes.raioEntregaKm, isNull);
      expect(detalhes.toJson().containsKey('raio_entrega_km'), isFalse);
    });

  });

  test('o catálogo manda a localização e a área só quando há local', () async {
    final adapter = FakeApiAdapter((_) => FakeResponse(200, _pagina([])));
    final repositorio = CatalogoRepository(
      ApiClient(storage: InMemoryTokenStorage(), adapter: adapter),
    );

    await repositorio.listarCacambas();
    await repositorio.listarCacambas(
      local: localDeTeste,
      area: AreaCatalogo.fora,
    );
    await repositorio.detalheCacamba('c1', local: localDeTeste);

    expect(adapter.requests[0].queryParameters.containsKey('latitude'), false);
    expect(adapter.requests[0].queryParameters.containsKey('area'), false);
    expect(adapter.requests[1].queryParameters['area'], 'fora');
    expect(adapter.requests[1].queryParameters['longitude'], -46.6559);
    expect(adapter.requests[2].queryParameters['latitude'], -23.5614);
  });

  group('catálogo do cliente', () {
    FakeResponse catalogo(RequestOptions request) {
      if (request.path == '/localizacao/cep/01310100') {
        return FakeResponse(200, _ok(_paulista));
      }
      if (request.path == '/localizacao/cep/99999999') {
        return const FakeResponse(404, {
          'success': false,
          'message': 'CEP não encontrado.',
          'code': 'CEP_NOT_FOUND',
        });
      }
      if (request.path == '/localizacao/cep/11111111') {
        return FakeResponse(200, _ok({..._paulista, 'latitude': null}));
      }
      if (request.path == '/cacambas') {
        final fora = request.queryParameters['area'] == 'fora';
        return FakeResponse(200, _pagina([fora ? _fora : _dentro]));
      }
      return const FakeResponse(404, {'success': false, 'message': 'não'});
    }

    testWidgets('sem local, pede o CEP e não lista nada ainda', (tester) async {
      final adapter = await _abrir(
        tester,
        const CacambasPage(),
        catalogo,
        local: null,
      );

      expect(find.text('Informe o CEP de entrega'), findsOneWidget);
      expect(find.text('Alugar'), findsNothing);
      expect(adapter.paths, isNot(contains('GET /cacambas')));
    });

    testWidgets('informar o CEP abre o catálogo daquela região', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const CacambasPage(),
        catalogo,
        local: null,
      );

      await tester.tap(find.text('Informar CEP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '01310100');
      await tester.tap(find.text('Ver caçambas na minha região'));
      await tester.pumpAndSettle();

      expect(find.text('Caçamba Standard'), findsOneWidget);
      expect(
        find.text('Entrega em Avenida Paulista · São Paulo - SP'),
        findsOneWidget,
      );

      final lista = adapter.requests.lastWhere((r) => r.path == '/cacambas');
      expect(lista.queryParameters['latitude'], -23.5614);
      expect(lista.queryParameters['area'], 'dentro');
    });

    testWidgets('CEP inexistente mostra o erro da API', (tester) async {
      await _abrir(tester, const CacambasPage(), catalogo, local: null);

      await tester.tap(find.text('Informar CEP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '99999999');
      await tester.tap(find.text('Ver caçambas na minha região'));
      await tester.pumpAndSettle();

      expect(find.text('CEP não encontrado.'), findsOneWidget);
      expect(find.text('Caçamba Standard'), findsNothing);
    });

    testWidgets('CEP sem coordenadas pede outro CEP', (tester) async {
      await _abrir(tester, const CacambasPage(), catalogo, local: null);

      await tester.tap(find.text('Informar CEP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '11111111');
      await tester.tap(find.text('Ver caçambas na minha região'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Tente um CEP próximo'), findsOneWidget);
    });

    testWidgets('CEP com menos de 8 dígitos não consulta a API', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const CacambasPage(),
        catalogo,
        local: null,
      );

      await tester.tap(find.text('Informar CEP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '0131');
      await tester.tap(find.text('Ver caçambas na minha região'));
      await tester.pumpAndSettle();

      expect(find.text('Informe um CEP com 8 dígitos.'), findsOneWidget);
      expect(adapter.paths.where((p) => p.contains('localizacao')), isEmpty);
    });

    testWidgets('ver caçambas fora da área: sem alugar, só contato', (
      tester,
    ) async {
      final adapter = await _abrir(tester, const CacambasPage(), catalogo);

      expect(find.text('Alugar'), findsOneWidget);

      await tester.tap(find.text('Ver caçambas fora da minha área'));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['area'], 'fora');
      expect(find.text('Caçamba Distante'), findsOneWidget);
      expect(find.text('Caçamba Standard'), findsNothing);
      expect(find.text('Alugar'), findsNothing);
      expect(find.text('Detalhes'), findsOneWidget);
      expect(
        find.textContaining('Fora da área de atendimento · a 12,3 km'),
        findsOneWidget,
      );

      await tester.tap(find.text('Voltar para caçambas na minha área'));
      await tester.pumpAndSettle();

      expect(adapter.requests.last.queryParameters['area'], 'dentro');
      expect(find.text('Alugar'), findsOneWidget);
    });

    testWidgets('cliente logado usa o primeiro endereço salvo localizado', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const CacambasPage(),
        (request) {
          if (request.path == '/usuarios/perfil') {
            return FakeResponse(
              200,
              _ok({..._fornecedorLogado, 'tipo_perfil': 'CONSUMIDOR'}),
            );
          }
          if (request.path == '/enderecos') {
            return FakeResponse(
              200,
              _ok([
                {
                  'id': 'e1',
                  'cep': '01001000',
                  'logradouro': 'Sem coordenadas',
                  'numero': '1',
                  'cidade_estado': 'São Paulo - SP',
                },
                {
                  'id': 'e2',
                  'cep': '01310100',
                  'logradouro': 'Avenida Paulista',
                  'numero': '1000',
                  'cidade_estado': 'São Paulo - SP',
                  'latitude': '-23.561400',
                  'longitude': '-46.655900',
                },
              ]),
            );
          }
          return catalogo(request);
        },
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
        local: null,
      );

      expect(find.text('Informe o CEP de entrega'), findsNothing);
      expect(find.text('Caçamba Standard'), findsOneWidget);

      final lista = adapter.requests.lastWhere((r) => r.path == '/cacambas');
      expect(lista.queryParameters['latitude'], -23.5614);
    });
  });

  group('detalhe fora da área', () {
    FakeResponse detalhe(RequestOptions request) {
      if (request.path == '/cacambas/c9') {
        return FakeResponse(
          200,
          _ok({
            ..._fora,
            'cacambeiro': {
              'id': 'u9',
              'nome_completo': 'Fornecedor Distante',
            },
            'avaliacoes': [],
          }),
        );
      }
      return const FakeResponse(404, {'success': false, 'message': 'não'});
    }

    testWidgets('esconde o carrinho e explica por que não dá para alugar', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const CacambaDetailsPage(cacambaId: 'c9'),
        detalhe,
      );

      expect(adapter.requests.first.queryParameters['latitude'], -23.5614);
      expect(find.text('Adicionar ao Carrinho'), findsNothing);
      expect(find.text('Fora da área de atendimento'), findsOneWidget);
      expect(find.textContaining('fica a 12,3 km'), findsOneWidget);
      expect(find.textContaining('Altere o CEP de entrega'), findsOneWidget);

      // Sem telefone nem WhatsApp: a conversa só existe dentro de um pedido.
      expect(find.textContaining('Chamar no WhatsApp'), findsNothing);
      expect(find.textContaining('98888-7777'), findsNothing);
    });
  });
  group('área de atendimento do fornecedor', () {
    FakeResponse Function(RequestOptions) api({
      Map<String, dynamic>? area,
      List<RequestOptions>? salvos,
    }) {
      return (request) {
        if (request.path == '/cacambeiros/me/area') {
          if (request.method == 'PUT') {
            salvos?.add(request);
            return FakeResponse(
              200,
              _ok({
                'definida': true,
                'latitude': -23.5614,
                'longitude': -46.6559,
                'raio_km': 25,
              }),
            );
          }
          return FakeResponse(
            200,
            _ok(
              area ??
                  {
                    'definida': false,
                    'latitude': null,
                    'longitude': null,
                    'raio_km': null,
                  },
            ),
          );
        }
        if (request.path == '/localizacao/cep/01310100') {
          return FakeResponse(200, _ok(_paulista));
        }
        return const FakeResponse(404, {'success': false, 'message': 'não'});
      };
    }

    testWidgets('sem área, só salva depois de marcar o centro pelo CEP', (
      tester,
    ) async {
      final salvos = <RequestOptions>[];
      await _abrir(
        tester,
        const AreaAtendimentoPage(),
        api(salvos: salvos),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      expect(find.text('Raio de atendimento: 20 km'), findsOneWidget);
      expect(
        tester
            .widget<ElevatedButton>(
              find.widgetWithText(ElevatedButton, 'Salvar área'),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(find.byType(TextField), '01310100');
      await tester.tap(find.text('Buscar'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Slider), const Offset(-2000, 0));
      await tester.pumpAndSettle();
      expect(find.text('Raio de atendimento: 1 km'), findsOneWidget);

      await tester.tap(find.text('Salvar área'));
      await tester.pumpAndSettle();

      expect(salvos, hasLength(1));
      expect(sentBody(salvos.single), {
        'latitude': -23.5614,
        'longitude': -46.6559,
        'raio_km': 1,
      });
    });

    testWidgets('tocar no mapa marca o centro', (tester) async {
      final salvos = <RequestOptions>[];
      await _abrir(
        tester,
        const AreaAtendimentoPage(),
        api(salvos: salvos),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      final toque = await tester.startGesture(
        tester.getCenter(find.byType(FlutterMap)),
      );
      await tester.pump(const Duration(milliseconds: 60));
      await toque.up();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.location_on), findsOneWidget);

      await tester.tap(find.text('Salvar área'));
      await tester.pumpAndSettle();

      expect(salvos, hasLength(1));
      expect(sentBody(salvos.single)['raio_km'], 20);
    });

    testWidgets('mostra a área já definida e permite alterar o raio', (
      tester,
    ) async {
      final salvos = <RequestOptions>[];
      await _abrir(
        tester,
        const AreaAtendimentoPage(),
        api(
          salvos: salvos,
          area: {
            'definida': true,
            'latitude': -23.5614,
            'longitude': -46.6559,
            'raio_km': 40,
          },
        ),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      expect(find.text('Raio de atendimento: 40 km'), findsOneWidget);
      expect(find.byIcon(Icons.location_on), findsOneWidget);

      await tester.tap(find.text('Salvar área'));
      await tester.pumpAndSettle();

      expect(sentBody(salvos.single), {
        'latitude': -23.5614,
        'longitude': -46.6559,
        'raio_km': 40,
      });
    });

    testWidgets('a atribuição do OpenStreetMap fica visível no mapa', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AreaAtendimentoPage(),
        api(),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      expect(find.byType(RichAttributionWidget), findsOneWidget);
    });

    testWidgets('card do perfil resume a situação e abre o mapa', (
      tester,
    ) async {
      await _abrir(
        tester,
        const PerfilLojaPage(),
        api(),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      expect(find.textContaining('Área ainda não definida'), findsOneWidget);

      await tester.ensureVisible(
        find.byKey(const Key('area_atendimento_abrir')),
      );
      await tester.tap(find.byKey(const Key('area_atendimento_abrir')));
      await tester.pumpAndSettle();

      expect(find.byType(AreaAtendimentoPage), findsOneWidget);
    });
  });

  group('aviso de cadastro incompleto', () {
    FakeResponse Function(RequestOptions) painel({
      required Map<String, dynamic> usuario,
      required List<String> pendencias,
    }) {
      return (request) {
        if (request.path == '/usuarios/perfil') {
          return FakeResponse(200, _ok(usuario));
        }
        if (request.path == '/cacambeiros/me/pendencias') {
          return FakeResponse(
            200,
            _ok({
              'area_definida': !pendencias.contains('AREA_ATENDIMENTO'),
              'assinatura_cadastrada': !pendencias.contains('ASSINATURA'),
              'pendencias': pendencias,
            }),
          );
        }
        if (request.path == '/cacambeiros/me/area') {
          return FakeResponse(200, _ok({'definida': false, 'raio_km': null}));
        }
        return const FakeResponse(404, {'success': false, 'message': 'não'});
      };
    }

    InMemoryTokenStorage storage() => InMemoryTokenStorage(accessToken: 'jwt');

    testWidgets('fornecedor sem área e sem assinatura vê o aviso', (
      tester,
    ) async {
      await _abrir(
        tester,
        const PainelAdminPage(),
        painel(
          usuario: _fornecedorLogado,
          pendencias: ['AREA_ATENDIMENTO', 'ASSINATURA'],
        ),
        storage: storage(),
      );

      expect(find.text('Complete seu cadastro'), findsOneWidget);
      expect(find.text('Área de atendimento'), findsOneWidget);
      expect(find.text('Assinatura da empresa'), findsOneWidget);

      await tester.tap(find.text('Definir área'));
      await tester.pumpAndSettle();

      expect(find.byType(AreaAtendimentoPage), findsOneWidget);
    });

    testWidgets('com só a assinatura pendente, leva ao perfil da loja', (
      tester,
    ) async {
      await _abrir(
        tester,
        const PainelAdminPage(),
        painel(usuario: _fornecedorLogado, pendencias: ['ASSINATURA']),
        storage: storage(),
      );

      expect(find.text('Complete seu cadastro'), findsOneWidget);
      expect(find.text('Área de atendimento'), findsNothing);

      await tester.tap(find.text('Enviar assinatura'));
      await tester.pumpAndSettle();

      expect(find.text('perfil da loja'), findsOneWidget);
    });

    testWidgets('aparece uma vez só por sessão', (tester) async {
      await _abrir(
        tester,
        const PainelAdminPage(),
        painel(usuario: _fornecedorLogado, pendencias: ['ASSINATURA']),
        storage: storage(),
      );

      await tester.tap(find.text('Depois'));
      await tester.pumpAndSettle();
      expect(find.text('Complete seu cadastro'), findsNothing);

      // Abre o painel de novo na mesma sessão: o aviso não repete.
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PainelAdminPage)),
      );
      expect(container.read(avisoPendenciasMostradoProvider), isTrue);

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushReplacement(
            MaterialPageRoute<void>(builder: (_) => const PainelAdminPage()),
          );
      await tester.pumpAndSettle();

      expect(find.text('Complete seu cadastro'), findsNothing);
    });

    testWidgets('sem pendências, não mostra nada', (tester) async {
      await _abrir(
        tester,
        const PainelAdminPage(),
        painel(usuario: _fornecedorLogado, pendencias: []),
        storage: storage(),
      );

      expect(find.text('Complete seu cadastro'), findsNothing);
    });

    testWidgets('administrador não é avisado nem consulta pendências', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const PainelAdminPage(),
        painel(
          usuario: {..._fornecedorLogado, 'tipo_perfil': 'ADMIN'},
          pendencias: ['AREA_ATENDIMENTO'],
        ),
        storage: storage(),
      );

      expect(find.text('Complete seu cadastro'), findsNothing);
      expect(adapter.paths, isNot(contains('GET /cacambeiros/me/pendencias')));
    });
  });
}
