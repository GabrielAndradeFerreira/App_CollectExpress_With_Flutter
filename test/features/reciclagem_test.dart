import 'dart:typed_data';

import 'package:app_collect_express_with_flutter/core/models/chat.dart';
import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/models/reciclagem.dart';
import 'package:app_collect_express_with_flutter/core/models/usuario.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/gestao_parceiros_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/cadastro_parceiro_reciclagem_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/pages/conversas_page.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/compartilhar_pdf.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/data/reciclagem_repository.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/agendar_coleta_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/coletas_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/minhas_sinalizacoes_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/ofertas_disponiveis_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/parceiro_inicio_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/perfil_parceiro_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/reciclagem_landing_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/sinalizar_reciclagem_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _ok(Object? data) => {'success': true, 'data': data};

const _naoEncontrado = FakeResponse(404, {
  'success': false,
  'message': 'não encontrado',
});

Map<String, dynamic> _pagina(List<Map<String, dynamic>> itens) => {
  'items': itens,
  'pagination': {
    'total': itens.length,
    'page': 1,
    'per_page': 20,
    'total_pages': 1,
  },
};

const _materiais = [
  {'id': 'm1', 'nome': 'Plástico'},
  {'id': 'm2', 'nome': 'Papel e papelão'},
];

Map<String, dynamic> _usuario(String perfil, {String id = 'u1'}) => {
  'id': id,
  'nome_completo': 'Usuário $perfil',
  'email': 'u@teste.com',
  'tipo_perfil': perfil,
  'status': 'ATIVO',
};

Map<String, dynamic> _ofertaDisponivel({
  String id = 'o1',
  DateTime? primeiroHorario,
  DateTime? janelaFim,
}) => {
  'id': id,
  'materiais': _materiais,
  'descricao': 'Garrafas PET limpas em sacos',
  'quantidade_estimada': '30 kg',
  'observacoes': 'Portão azul',
  'janela_inicio': DateTime(2030, 1, 1, 8).toUtc().toIso8601String(),
  'janela_fim': (janelaFim ?? DateTime(2030, 1, 5, 18))
      .toUtc()
      .toIso8601String(),
  'primeiro_horario': (primeiroHorario ?? DateTime(2030, 1, 2, 10))
      .toUtc()
      .toIso8601String(),
  'bairro': 'Bela Vista',
  'cidade_estado': 'São Paulo - SP',
  'distancia_km': 4.2,
  'anunciante_tipo': 'Cliente',
};

Map<String, dynamic> _coleta({
  String id = 'c1',
  String status = 'AGENDADA',
  bool podeCancelar = true,
  bool podeConcluir = false,
  double? peso,
}) => {
  'id': id,
  'codigo': 'COL-REC-AB12CD34',
  'status': status,
  'data_agendada': DateTime(2030, 1, 3, 9).toUtc().toIso8601String(),
  'agendada_em': DateTime(2030, 1, 1, 9).toUtc().toIso8601String(),
  'cancelavel_ate': DateTime(2030, 1, 2, 9).toUtc().toIso8601String(),
  'pode_cancelar': podeCancelar,
  'pode_concluir': podeConcluir,
  'materiais': ['Plástico', 'Papel e papelão'],
  'descricao': 'Garrafas PET limpas em sacos',
  'quantidade_estimada': '30 kg',
  'observacoes': 'Levo duas pessoas',
  'observacoes_oferta': 'Portão azul',
  'janela_inicio': DateTime(2030, 1, 1, 8).toUtc().toIso8601String(),
  'janela_fim': DateTime(2030, 1, 5, 18).toUtc().toIso8601String(),
  'endereco': {
    'logradouro': 'Av. Paulista',
    'numero': '1000',
    'bairro': 'Bela Vista',
    'cidade_estado': 'São Paulo - SP',
  },
  'gerador_nome': 'Maria Cliente',
  'gerador_tipo': 'Cliente',
  'parceiro_nome': 'Recicla Mais',
  'peso_real_kg': peso,
};

Map<String, dynamic> _minhaOferta({
  String status = 'ABERTA',
  Map<String, dynamic>? coleta,
}) => {
  'id': 'o1',
  'status': status,
  'materiais': _materiais,
  'descricao': 'Garrafas PET limpas em sacos',
  'quantidade_estimada': '30 kg',
  'observacoes': null,
  'janela_inicio': DateTime(2030, 1, 1, 8).toUtc().toIso8601String(),
  'janela_fim': DateTime(2030, 1, 5, 18).toUtc().toIso8601String(),
  'endereco': {
    'logradouro': 'Av. Paulista',
    'numero': '1000',
    'bairro': 'Bela Vista',
    'cidade_estado': 'São Paulo - SP',
  },
  'criada_em': DateTime(2029, 12, 30).toUtc().toIso8601String(),
  'coleta': coleta,
};

const _endereco = {
  'id': 'e1',
  'cep': '01310100',
  'logradouro': 'Av. Paulista',
  'numero': '1000',
  'bairro': 'Bela Vista',
  'cidade_estado': 'São Paulo/SP',
};

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  FakeResponse Function(RequestOptions request) handler, {
  bool logado = true,
  List<Override> overrides = const [],
  Map<String, WidgetBuilder> rotas = const {},
}) async {
  tester.view.physicalSize = const Size(1200, 5000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage(accessToken: logado ? 'jwt' : null);
  final adapter = FakeApiAdapter(handler);

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: tokens, adapter: adapter),
        ),
        ...overrides,
      ],
      child: MaterialApp(
        home: tela,
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('tela de login')),
          AppRoutes.recyclingMine: (_) =>
              const Scaffold(body: Text('tela das minhas sinalizações')),
          AppRoutes.recyclingOffers: (_) =>
              const Scaffold(body: Text('tela das sinalizações')),
          AppRoutes.recyclingCollections: (_) =>
              const Scaffold(body: Text('tela das coletas')),
          ...rotas,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

void main() {
  group('modelos', () {
    test('parceiro é um perfil da API e Usuario sabe disso', () {
      expect(TipoPerfil.fromApi('PARCEIRO'), TipoPerfil.parceiro);

      final usuario = Usuario.fromJson({
        ..._usuario('PARCEIRO'),
        'detalhes_parceiro': {
          'responsavel_nome': 'João',
          'endereco_coleta': 'Rua A, 10',
          'capacidade_diaria_kg': '500.00',
          'raio_atuacao_km': 25,
          'materiais': ['Plástico', 'Vidro'],
        },
      });

      expect(usuario.isParceiro, isTrue);
      expect(usuario.isConsumidor, isFalse);
      expect(usuario.detalhesParceiro!.responsavelNome, 'João');
      expect(usuario.detalhesParceiro!.capacidadeDiariaKg, 500);
      expect(usuario.detalhesParceiro!.materiais, ['Plástico', 'Vidro']);
    });

    test('OfertaDisponivel lê a vitrine sem endereço completo', () {
      final oferta = OfertaDisponivel.fromJson(_ofertaDisponivel());

      expect(oferta.materiais.map((m) => m.nome), [
        'Plástico',
        'Papel e papelão',
      ]);
      expect(oferta.local, 'Bela Vista - São Paulo - SP');
      expect(oferta.distanciaKm, 4.2);
      expect(oferta.anuncianteTipo, 'Cliente');
    });

    test('Coleta lê os campos e o endereço em uma linha', () {
      final coleta = Coleta.fromJson(_coleta(podeConcluir: true, peso: 12.5));

      expect(coleta.status, StatusColeta.agendada);
      expect(coleta.podeConcluir, isTrue);
      expect(coleta.pesoRealKg, 12.5);
      expect(
        coleta.enderecoTexto,
        'Av. Paulista, 1000 - Bela Vista - São Paulo - SP',
      );
      expect(coleta.parceiroNome, 'Recicla Mais');
    });

    test('pendências do parceiro vêm dos códigos da API', () {
      expect(pendenciasDoParceiro(['AREA_ATUACAO', 'ASSINATURA', 'OUTRA']), [
        PendenciaParceiro.areaAtuacao,
        PendenciaParceiro.assinatura,
      ]);
      expect(pendenciasDoParceiro(null), isEmpty);
    });

    test('Conversa de coleta guarda o código e o resumo da coleta', () {
      final conversa = Conversa.fromJson({
        'id': 'cv1',
        'tipo': 'COLETA',
        'status': 'ABERTA',
        'coleta_id': 'c1',
        'coleta_codigo': 'COL-REC-AB12CD34',
        'contato_nome': 'Recicla Mais',
        'coleta': _coleta(),
      });

      expect(conversa.tipo, TipoConversa.coleta);
      expect(conversa.temColeta, isTrue);
      expect(conversa.coleta!.codigo, 'COL-REC-AB12CD34');
    });

    test('DadosCadastroParceiro monta o corpo do cadastro', () {
      const dados = DadosCadastroParceiro(
        responsavelNome: ' João ',
        enderecoColeta: 'Rua A, 10',
        materiaisIds: ['m1'],
        capacidadeDiariaKg: 300,
      );

      expect(dados.toJson(), {
        'responsavel_nome': 'João',
        'endereco_coleta': 'Rua A, 10',
        'materiais_ids': ['m1'],
        'capacidade_diaria_kg': 300.0,
      });
    });
  });

  group('repositório', () {
    test('criarOferta envia o corpo esperado e a assinatura', () async {
      final adapter = FakeApiAdapter(
        (_) => FakeResponse(201, _ok(_minhaOferta())),
      );
      final tokens = InMemoryTokenStorage(accessToken: 'jwt');
      final repositorio = ReciclagemRepository(
        ApiClient(storage: tokens, adapter: adapter),
      );

      await repositorio.criarOferta(
        materiaisIds: ['m1'],
        descricao: ' Garrafas ',
        quantidadeEstimada: '10 kg',
        enderecoId: 'e1',
        janelaInicio: DateTime.utc(2030, 1, 1, 8),
        janelaFim: DateTime.utc(2030, 1, 1, 12),
        assinaturaBase64: 'data:image/png;base64,AAAA',
      );

      final corpo = sentBody(adapter.requests.single);

      expect(adapter.paths.single, 'POST /ofertas-coleta');
      expect(corpo['materiais_ids'], ['m1']);
      expect(corpo['descricao'], 'Garrafas');
      expect(corpo['aceite_termos'], isTrue);
      expect(corpo['janela_inicio'], '2030-01-01T08:00:00.000Z');
      expect(corpo['assinatura_base64'], 'data:image/png;base64,AAAA');
      expect(corpo.containsKey('observacoes'), isFalse);
    });

    test('ofertasDisponiveis manda os filtros como parâmetros', () async {
      final adapter = FakeApiAdapter(
        (_) => FakeResponse(
          200,
          _ok({
            ..._pagina([_ofertaDisponivel()]),
            'area_definida': true,
          }),
        ),
      );
      final repositorio = ReciclagemRepository(
        ApiClient(
          storage: InMemoryTokenStorage(accessToken: 'jwt'),
          adapter: adapter,
        ),
      );

      final resposta = await repositorio.ofertasDisponiveis((
        materiais: 'm1,m2',
        distanciaKm: 10,
        de: null,
        ate: null,
        pagina: 2,
      ));

      final consulta = adapter.requests.single.queryParameters;

      expect(consulta['materiais'], 'm1,m2');
      expect(consulta['distancia_km'], 10);
      expect(consulta['page'], 2);
      expect(consulta.containsKey('de'), isFalse);
      expect(resposta.pagina.itens.single.id, 'o1');
      expect(resposta.areaDefinida, isTrue);
    });
  });

  group('tela pública', () {
    testWidgets('sem login oferece sinalizar, ser parceiro e entrar', (
      tester,
    ) async {
      await _abrir(
        tester,
        const ReciclagemLandingPage(),
        (request) => request.path == '/usuarios/perfil'
            ? const FakeResponse(401, {'success': false, 'message': 'sem'})
            : _naoEncontrado,
        logado: false,
        rotas: {AppRoutes.register: (_) => const Text('tela de cadastro')},
      );

      expect(find.text('Sinalizar material'), findsOneWidget);
      expect(find.text('Quero ser parceiro'), findsOneWidget);
      expect(find.text('Já tenho conta. Entrar'), findsOneWidget);

      await tester.tap(find.text('Quero ser parceiro'));
      await tester.pumpAndSettle();

      expect(find.text('tela de cadastro'), findsOneWidget);
    });

    testWidgets('parceiro logado vai direto para o painel', (tester) async {
      await _abrir(
        tester,
        const ReciclagemLandingPage(),
        (request) => request.path == '/usuarios/perfil'
            ? FakeResponse(200, _ok(_usuario('PARCEIRO')))
            : _naoEncontrado,
        rotas: {AppRoutes.recyclingHome: (_) => const Text('painel parceiro')},
      );

      expect(find.text('Ir para o meu painel'), findsOneWidget);
      expect(find.text('Quero ser parceiro'), findsNothing);
    });
  });

  group('cadastro do parceiro', () {
    FakeResponse api(RequestOptions request) {
      if (request.path == '/materiais') {
        return FakeResponse(200, _ok(_materiais));
      }
      if (request.path == '/auth/register') {
        return FakeResponse(201, _ok(_usuario('PARCEIRO')));
      }
      return _naoEncontrado;
    }

    Future<FakeApiAdapter> abrir(
      WidgetTester tester,
      FakeResponse Function(RequestOptions) handler,
    ) {
      return _abrir(
        tester,
        const CadastroParceiroReciclagemPage(
          email: 'empresa@recicla.com',
          password: 'Senha123',
        ),
        handler,
        logado: false,
      );
    }

    Future<void> preencher(WidgetTester tester) async {
      Future<void> digitar(int indice, String texto) async {
        await tester.enterText(find.byType(TextFormField).at(indice), texto);
      }

      await digitar(0, 'Recicla Mais Ltda');
      await digitar(1, '11222333000181');
      await digitar(2, 'João da Silva');
      await digitar(3, 'Rua das Flores, 100, Centro, São Paulo - SP');
      await digitar(4, '11999998888');
      await digitar(6, 'empresa@recicla.com');
      await digitar(8, 'Senha123');
    }

    testWidgets('não envia sem preencher e sem escolher material', (
      tester,
    ) async {
      final adapter = await abrir(tester, api);

      await tester.tap(find.text('CADASTRAR-SE'));
      await tester.pumpAndSettle();

      expect(find.text('Informe o nome da empresa'), findsOneWidget);
      expect(find.text('Informe um CNPJ com 14 dígitos'), findsOneWidget);
      expect(
        find.text('Escolha ao menos um tipo de material.'),
        findsOneWidget,
      );
      expect(adapter.paths, isNot(contains('POST /auth/register')));
    });

    testWidgets('envia o cadastro como PARCEIRO e avisa que vai para análise', (
      tester,
    ) async {
      final adapter = await abrir(tester, api);

      await preencher(tester);
      await tester.tap(find.text('Plástico'));
      await tester.pump();
      await tester.tap(find.text('CADASTRAR-SE'));
      await tester.pumpAndSettle();

      final requisicao = adapter.requests.firstWhere(
        (r) => r.path == '/auth/register',
      );
      final corpo = sentBody(requisicao);

      expect(corpo['tipo_perfil'], 'PARCEIRO');
      expect(corpo['documento'], '11222333000181');
      expect(corpo['responsavel_nome'], 'João da Silva');
      expect(corpo['endereco_coleta'], contains('Rua das Flores'));
      expect(corpo['materiais_ids'], ['m1']);
      expect(corpo.containsKey('capacidade_diaria_kg'), isFalse);
      expect(find.text('Cadastro enviado!'), findsOneWidget);
    });
  });

  group('início do parceiro', () {
    testWidgets('mostra o resumo e o que falta cadastrar', (tester) async {
      await _abrir(tester, const ParceiroInicioPage(), (request) {
        return switch (request.path) {
          '/usuarios/perfil' => FakeResponse(200, _ok(_usuario('PARCEIRO'))),
          '/coletas/resumo' => FakeResponse(
            200,
            _ok({
              'agendadas': 3,
              'concluidas': 7,
              'kg_coletados': 120.5,
              'ofertas_abertas': 9,
            }),
          ),
          '/parceiros/me/pendencias' => FakeResponse(
            200,
            _ok({
              'pendencias': ['AREA_ATUACAO', 'ASSINATURA'],
            }),
          ),
          _ => _naoEncontrado,
        };
      });

      expect(find.text('Olá, Usuário PARCEIRO'), findsOneWidget);
      expect(find.byKey(const Key('resumo_abertas')), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('resumo_abertas'))).data,
        '9',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('resumo_agendadas'))).data,
        '3',
      );
      expect(
        tester.widget<Text>(find.byKey(const Key('resumo_kg'))).data,
        '120,5 kg',
      );
      expect(find.byKey(const Key('parceiro_pendencias')), findsOneWidget);
      expect(find.text('Área de atuação'), findsOneWidget);
      expect(find.text('Assinatura da empresa'), findsOneWidget);
    });

    testWidgets('sem pendências o aviso não aparece', (tester) async {
      await _abrir(tester, const ParceiroInicioPage(), (request) {
        return switch (request.path) {
          '/usuarios/perfil' => FakeResponse(200, _ok(_usuario('PARCEIRO'))),
          '/coletas/resumo' => FakeResponse(200, _ok(<String, dynamic>{})),
          '/parceiros/me/pendencias' => FakeResponse(
            200,
            _ok({'pendencias': <String>[]}),
          ),
          _ => _naoEncontrado,
        };
      });

      expect(find.byKey(const Key('parceiro_pendencias')), findsNothing);
    });
  });

  group('vitrine de sinalizações', () {
    FakeResponse api(RequestOptions request) {
      return switch (request.path) {
        '/usuarios/perfil' => FakeResponse(200, _ok(_usuario('PARCEIRO'))),
        '/materiais' => FakeResponse(200, _ok(_materiais)),
        '/ofertas-coleta' => FakeResponse(
          200,
          _ok({
            ..._pagina(
              request.queryParameters['materiais'] == 'm2'
                  ? []
                  : [_ofertaDisponivel()],
            ),
            'area_definida': true,
          }),
        ),
        _ => _naoEncontrado,
      };
    }

    testWidgets('lista a sinalização sem endereço completo', (tester) async {
      await _abrir(tester, const OfertasDisponiveisPage(), api);

      expect(find.text('Garrafas PET limpas em sacos'), findsOneWidget);
      expect(find.text('Bela Vista - São Paulo - SP'), findsOneWidget);
      expect(find.text('4 km'), findsOneWidget);
      expect(find.text('Agendar coleta'), findsOneWidget);
      expect(find.textContaining('Paulista'), findsNothing);
    });

    testWidgets('filtrar por material consulta a API de novo', (tester) async {
      final adapter = await _abrir(tester, const OfertasDisponiveisPage(), api);

      await tester.tap(
        find.byKey(const Key('filtro_material_Papel e papelão')),
      );
      await tester.pumpAndSettle();

      final consultas = adapter.requests
          .where((r) => r.path == '/ofertas-coleta')
          .toList();

      expect(consultas.last.queryParameters['materiais'], 'm2');
      expect(
        find.textContaining('Nenhuma sinalização encontrada'),
        findsOneWidget,
      );
    });

    testWidgets('avisa quando a área de atuação ainda não foi definida', (
      tester,
    ) async {
      await _abrir(tester, const OfertasDisponiveisPage(), (request) {
        if (request.path == '/ofertas-coleta') {
          return FakeResponse(
            200,
            _ok({..._pagina([]), 'area_definida': false}),
          );
        }
        return api(request);
      });

      expect(find.text('Definir área de atuação'), findsOneWidget);
    });
  });

  group('agendar coleta', () {
    final agora = DateTime(2030, 1, 1, 10);

    Future<FakeApiAdapter> abrir(
      WidgetTester tester,
      OfertaDisponivel oferta, {
      FakeResponse Function(RequestOptions)? handler,
    }) {
      return _abrir(
        tester,
        AgendarColetaPage(oferta: oferta, agora: agora),
        handler ??
            (request) => request.path == '/coletas'
                ? FakeResponse(201, _ok(_coleta()))
                : _naoEncontrado,
      );
    }

    testWidgets('sem escolher dia e hora pede para escolher', (tester) async {
      final adapter = await abrir(
        tester,
        OfertaDisponivel.fromJson(_ofertaDisponivel()),
      );

      await tester.tap(find.text('Confirmar agendamento'));
      await tester.pumpAndSettle();

      expect(
        find.text('Escolha o dia e o horário da retirada.'),
        findsOneWidget,
      );
      expect(adapter.paths, isNot(contains('POST /coletas')));
    });

    testWidgets('sinalização sem horário com 24 h de antecedência avisa', (
      tester,
    ) async {
      await abrir(
        tester,
        OfertaDisponivel.fromJson(
          // A janela termina em menos de 24 h: não dá mais para agendar.
          _ofertaDisponivel(janelaFim: DateTime(2030, 1, 1, 20)),
        ),
      );

      await tester.tap(find.byKey(const Key('agendar_dia')));
      await tester.pumpAndSettle();

      expect(find.textContaining('não tem mais horário'), findsOneWidget);
    });

    testWidgets('agenda no primeiro horário permitido e mostra o sucesso', (
      tester,
    ) async {
      final adapter = await abrir(
        tester,
        OfertaDisponivel.fromJson(_ofertaDisponivel()),
      );

      await tester.tap(find.byKey(const Key('agendar_dia')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('agendar_hora')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Retirada em 02/01/2030 às 10:00'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('agendar_observacoes')),
        'Levo uma van',
      );
      await tester.tap(find.text('Confirmar agendamento'));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere((r) => r.path == '/coletas'),
      );

      expect(corpo['oferta_id'], 'o1');
      expect(
        corpo['data_agendada'],
        DateTime(2030, 1, 2, 10).toUtc().toIso8601String(),
      );
      expect(corpo['observacoes'], 'Levo uma van');
      expect(find.text('Coleta agendada!'), findsOneWidget);
      expect(find.textContaining('COL-REC-AB12CD34'), findsOneWidget);
    });
  });

  group('coletas', () {
    FakeResponse api(
      RequestOptions request, {
      String perfil = 'PARCEIRO',
      Map<String, dynamic>? coleta,
    }) {
      return switch ((request.method, request.path)) {
        ('GET', '/usuarios/perfil') => FakeResponse(200, _ok(_usuario(perfil))),
        ('GET', '/coletas') => FakeResponse(
          200,
          _ok(_pagina([coleta ?? _coleta(podeConcluir: true)])),
        ),
        ('GET', '/coletas/c1/documento') => const FakeResponse(200, {
          'pdf': 'simulado',
        }),
        ('PATCH', '/coletas/c1/concluir') => FakeResponse(
          200,
          _ok(_coleta(status: 'CONCLUIDA', peso: 42)),
        ),
        ('PATCH', '/coletas/c1/cancelar') => FakeResponse(
          200,
          _ok(_coleta(status: 'CANCELADA')),
        ),
        ('POST', '/chat/coletas/c1/conversa') => FakeResponse(
          200,
          _ok({
            'id': 'cv1',
            'tipo': 'COLETA',
            'status': 'ABERTA',
            'coleta_id': 'c1',
            'contato_nome': 'Maria Cliente',
          }),
        ),
        _ => _naoEncontrado,
      };
    }

    testWidgets('parceiro vê os dados e quem entrega, sem telefone', (
      tester,
    ) async {
      await _abrir(tester, const ColetasPage(), api);

      expect(find.text('COL-REC-AB12CD34'), findsOneWidget);
      expect(find.text('Agendada'), findsWidgets);
      expect(find.text('Cliente: Maria Cliente'), findsOneWidget);
      expect(
        find.text('Av. Paulista, 1000 - Bela Vista - São Paulo - SP'),
        findsOneWidget,
      );
      expect(find.text('Portão azul'), findsOneWidget);
      expect(find.byKey(const Key('concluir_c1')), findsOneWidget);
    });

    testWidgets('parceiro conclui informando o peso real', (tester) async {
      final adapter = await _abrir(tester, const ColetasPage(), api);

      await tester.tap(find.byKey(const Key('concluir_c1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('concluir_peso')), '42,5');
      await tester.tap(find.byKey(const Key('concluir_confirmar')));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere((r) => r.path == '/coletas/c1/concluir'),
      );

      expect(corpo['peso_real_kg'], 42.5);
      expect(find.text('Coleta concluída.'), findsOneWidget);
    });

    testWidgets('peso inválido não conclui', (tester) async {
      final adapter = await _abrir(tester, const ColetasPage(), api);

      await tester.tap(find.byKey(const Key('concluir_c1')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('concluir_peso')), 'abc');
      await tester.tap(find.byKey(const Key('concluir_confirmar')));
      await tester.pumpAndSettle();

      expect(find.text('Informe um peso válido em kg.'), findsOneWidget);
      expect(adapter.paths, isNot(contains('PATCH /coletas/c1/concluir')));
    });

    testWidgets('baixa o termo e entrega o PDF para compartilhar', (
      tester,
    ) async {
      String? nome;
      Uint8List? recebido;

      await _abrir(
        tester,
        const ColetasPage(),
        api,
        overrides: [
          compartilharPdfProvider.overrideWithValue((bytes, arquivo) async {
            recebido = bytes;
            nome = arquivo;
          }),
        ],
      );

      await tester.tap(find.byKey(const Key('documento_c1')));
      await tester.pumpAndSettle();

      expect(nome, 'termo-coleta-COL-REC-AB12CD34.pdf');
      expect(recebido, isNotEmpty);
    });

    testWidgets('parceiro cancela e quem entrega é avisado', (tester) async {
      final adapter = await _abrir(tester, const ColetasPage(), api);

      await tester.tap(find.byKey(const Key('cancelar_c1')));
      await tester.pumpAndSettle();

      // O parceiro não escolhe encerrar a sinalização.
      expect(find.byKey(const Key('cancelar_encerrar')), findsNothing);

      await tester.enterText(
        find.byKey(const Key('cancelar_motivo')),
        'Caminhão quebrou',
      );
      await tester.tap(find.byKey(const Key('cancelar_confirmar')));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere((r) => r.path == '/coletas/c1/cancelar'),
      );

      expect(corpo['motivo'], 'Caminhão quebrou');
      expect(corpo.containsKey('encerrar_sinalizacao'), isFalse);
    });

    testWidgets('quem entrega vê o parceiro e pode encerrar a sinalização', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const ColetasPage(),
        (request) => api(request, perfil: 'CONSUMIDOR', coleta: _coleta()),
      );

      expect(find.text('Parceiro: Recicla Mais'), findsOneWidget);
      expect(find.byKey(const Key('concluir_c1')), findsNothing);
      expect(find.textContaining('Você pode cancelar até'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cancelar_c1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancelar_encerrar')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cancelar_confirmar')));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere((r) => r.path == '/coletas/c1/cancelar'),
      );

      expect(corpo['encerrar_sinalizacao'], isTrue);
    });

    testWidgets('coleta cancelada não oferece termo nem cancelar', (
      tester,
    ) async {
      await _abrir(
        tester,
        const ColetasPage(),
        (request) => api(
          request,
          coleta: _coleta(status: 'CANCELADA', podeCancelar: false),
        ),
      );

      expect(find.text('Cancelada'), findsWidgets);
      expect(find.byKey(const Key('documento_c1')), findsNothing);
      expect(find.byKey(const Key('cancelar_c1')), findsNothing);
      expect(find.byKey(const Key('conversa_c1')), findsOneWidget);
    });

    testWidgets('conversar abre o chat da coleta', (tester) async {
      final adapter = await _abrir(tester, const ColetasPage(), api);

      await tester.tap(find.byKey(const Key('conversa_c1')));
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('POST /chat/coletas/c1/conversa'));
      expect(find.byType(ChatPage), findsOneWidget);
    });
  });

  group('minhas sinalizações', () {
    FakeResponse api(
      RequestOptions request, {
      Map<String, dynamic>? oferta,
      String perfil = 'CONSUMIDOR',
    }) {
      return switch ((request.method, request.path)) {
        ('GET', '/usuarios/perfil') => FakeResponse(200, _ok(_usuario(perfil))),
        ('GET', '/ofertas-coleta/minhas') => FakeResponse(
          200,
          _ok([oferta ?? _minhaOferta()]),
        ),
        ('PATCH', '/ofertas-coleta/o1/cancelar') => FakeResponse(
          200,
          _ok(_minhaOferta(status: 'CANCELADA')),
        ),
        _ => _naoEncontrado,
      };
    }

    testWidgets('sinalização aberta pode ser cancelada', (tester) async {
      final adapter = await _abrir(tester, const MinhasSinalizacoesPage(), api);

      expect(find.text('Aberta'), findsOneWidget);
      expect(find.text('Garrafas PET limpas em sacos'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sinalizacao_cancelar_o1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cancelar_sinalizacao_confirmar')));
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('PATCH /ofertas-coleta/o1/cancelar'));
    });

    testWidgets('mostra a coleta agendada com termo, conversa e prazo', (
      tester,
    ) async {
      await _abrir(
        tester,
        const MinhasSinalizacoesPage(),
        (request) => api(
          request,
          oferta: _minhaOferta(
            status: 'AGENDADA',
            coleta: {
              'id': 'c1',
              'codigo': 'COL-REC-AB12CD34',
              'status': 'AGENDADA',
              'data_agendada': DateTime(
                2030,
                1,
                3,
                9,
              ).toUtc().toIso8601String(),
              'cancelavel_ate': DateTime(
                2030,
                1,
                2,
                9,
              ).toUtc().toIso8601String(),
              'parceiro_nome': 'Recicla Mais',
              'pode_cancelar': true,
            },
          ),
        ),
      );

      // O título do bloco e o selo da sinalização usam o mesmo texto.
      expect(find.text('Coleta agendada'), findsNWidgets(2));
      expect(find.text('Recicla Mais'), findsOneWidget);
      expect(find.textContaining('Você pode cancelar até'), findsOneWidget);
      expect(find.byKey(const Key('sinalizacao_termo_o1')), findsOneWidget);
      expect(find.byKey(const Key('sinalizacao_conversa_o1')), findsOneWidget);
      expect(
        find.byKey(const Key('sinalizacao_cancelar_coleta_o1')),
        findsOneWidget,
      );
      // Já agendada: a sinalização em si não pode mais ser cancelada.
      expect(find.byKey(const Key('sinalizacao_cancelar_o1')), findsNothing);
    });

    testWidgets('sem sinalizações explica como começar', (tester) async {
      await _abrir(
        tester,
        const MinhasSinalizacoesPage(),
        (request) => request.path == '/ofertas-coleta/minhas'
            ? FakeResponse(200, _ok(<Object>[]))
            : api(request),
      );

      expect(find.textContaining('ainda não sinalizou'), findsOneWidget);
      expect(find.byKey(const Key('nova_sinalizacao')), findsOneWidget);
    });
  });

  group('sinalizar material', () {
    final agora = DateTime(2030, 1, 1, 10);

    FakeResponse api(RequestOptions request, {String perfil = 'CONSUMIDOR'}) {
      return switch ((request.method, request.path)) {
        ('GET', '/usuarios/perfil') => FakeResponse(200, _ok(_usuario(perfil))),
        ('GET', '/materiais') => FakeResponse(200, _ok(_materiais)),
        ('GET', '/enderecos') => FakeResponse(200, _ok([_endereco])),
        ('GET', '/cacambeiros/me/assinatura') => const FakeResponse(404, {
          'success': false,
          'message': 'Nenhuma assinatura cadastrada.',
          'code': 'SIGNATURE_NOT_FOUND',
        }),
        ('POST', '/ofertas-coleta') => FakeResponse(201, _ok(_minhaOferta())),
        _ => _naoEncontrado,
      };
    }

    Future<void> escolherDataHora(WidgetTester tester, Key chave) async {
      await tester.tap(find.byKey(chave));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    testWidgets('cliente sem preencher vê o que falta', (tester) async {
      final adapter = await _abrir(
        tester,
        SinalizarReciclagemPage(agora: agora),
        api,
      );

      await tester.tap(find.byKey(const Key('sinalizar_enviar')));
      await tester.pumpAndSettle();

      expect(
        find.text('Escolha ao menos um tipo de material.'),
        findsOneWidget,
      );
      expect(adapter.paths, isNot(contains('POST /ofertas-coleta')));
    });

    testWidgets('cliente precisa assinar para concordar com o termo', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        SinalizarReciclagemPage(agora: agora),
        api,
      );

      await tester.tap(find.byKey(const Key('sinalizar_material_Plástico')));
      await tester.enterText(
        find.byKey(const Key('sinalizar_descricao')),
        'Garrafas PET limpas',
      );
      await tester.enterText(
        find.byKey(const Key('sinalizar_quantidade')),
        '30 kg',
      );
      await escolherDataHora(tester, const Key('sinalizar_inicio'));

      await tester.tap(find.byKey(const Key('sinalizar_enviar')));
      await tester.pumpAndSettle();

      expect(
        find.text('Marque o aceite e assine para continuar.'),
        findsOneWidget,
      );
      expect(adapter.paths, isNot(contains('POST /ofertas-coleta')));
    });

    testWidgets('janela que termina em menos de 25 h é recusada', (
      tester,
    ) async {
      await _abrir(
        tester,
        // "Agora" muito distante da janela padrão (2 dias à frente) não
        // vale: aqui a janela é escolhida no mesmo dia.
        SinalizarReciclagemPage(agora: agora),
        api,
      );

      await tester.tap(find.byKey(const Key('sinalizar_material_Plástico')));
      await tester.enterText(
        find.byKey(const Key('sinalizar_descricao')),
        'Garrafas PET limpas',
      );
      await tester.enterText(
        find.byKey(const Key('sinalizar_quantidade')),
        '30 kg',
      );

      // Início: dia de hoje às 8h (o seletor abre dois dias à frente; o
      // toque no dia atual é feito pelo calendário).
      await tester.tap(find.byKey(const Key('sinalizar_inicio')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('sinalizar_enviar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('mais de 25 horas'), findsWidgets);
    });

    testWidgets('caçambeiro sem assinatura da empresa é avisado', (
      tester,
    ) async {
      await _abrir(
        tester,
        SinalizarReciclagemPage(agora: agora),
        (request) => api(request, perfil: 'CACAMBEIRO'),
        rotas: {AppRoutes.supplierProfile: (_) => const Text('perfil loja')},
      );

      expect(
        find.text('Você ainda não enviou a assinatura da empresa.'),
        findsOneWidget,
      );
      expect(find.text('Enviar agora'), findsOneWidget);

      final caixa = tester.widget<Checkbox>(
        find.byKey(const Key('sinalizar_aceite')),
      );
      expect(caixa.onChanged, isNull);
    });
  });

  group('perfil do parceiro', () {
    FakeResponse api(RequestOptions request) {
      return switch ((request.method, request.path)) {
        ('GET', '/usuarios/perfil') => FakeResponse(
          200,
          _ok(_usuario('PARCEIRO')),
        ),
        ('GET', '/parceiros/me') => FakeResponse(
          200,
          _ok({
            'nome': 'Recicla Mais Ltda',
            'email': 'empresa@recicla.com',
            'status': 'ATIVO',
            'responsavel_nome': 'João da Silva',
            'endereco_coleta': 'Rua das Flores, 100',
            'capacidade_diaria_kg': 500,
            'disponivel': true,
            'tem_assinatura': false,
            'materiais': _materiais,
            'area': {'definida': false},
          }),
        ),
        ('PUT', '/parceiros/me') => FakeResponse(200, _ok({'nome': 'x'})),
        ('GET', '/parceiros/me/area') => FakeResponse(
          200,
          _ok({'definida': false}),
        ),
        ('GET', '/parceiros/me/assinatura') => const FakeResponse(404, {
          'success': false,
          'message': 'Nenhuma assinatura cadastrada.',
          'code': 'SIGNATURE_NOT_FOUND',
        }),
        ('GET', '/materiais') => FakeResponse(200, _ok(_materiais)),
        _ => _naoEncontrado,
      };
    }

    testWidgets('mostra os dados da empresa e os materiais', (tester) async {
      await _abrir(tester, const PerfilParceiroPage(), api);

      expect(find.text('Recicla Mais Ltda'), findsOneWidget);
      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('500 kg'), findsOneWidget);
      expect(find.text('Plástico'), findsOneWidget);
      expect(find.text('Área de atuação'), findsOneWidget);
      expect(find.text('Assinatura da empresa'), findsOneWidget);
    });

    testWidgets('pausar as coletas envia disponivel=false', (tester) async {
      final adapter = await _abrir(tester, const PerfilParceiroPage(), api);

      await tester.tap(find.byKey(const Key('parceiro_disponivel')));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere(
          (r) => r.method == 'PUT' && r.path == '/parceiros/me',
        ),
      );

      expect(corpo['disponivel'], isFalse);
      expect(corpo.containsKey('materiais_ids'), isFalse);
    });
  });

  group('admin: parceiros de reciclagem', () {
    Map<String, dynamic> parceiro(String status) => {
      'id': 'p1',
      'nome_completo': 'Recicla Mais Ltda',
      'email': 'empresa@recicla.com',
      'tipo_perfil': 'PARCEIRO',
      'status': status,
      'documento': '**.***.333/0001-81',
      'telefone': '11999998888',
      'criado_em': '2030-01-01T10:00:00.000Z',
    };

    FakeResponse api(RequestOptions request, {String status = 'PENDENTE'}) {
      return switch ((request.method, request.path)) {
        ('GET', '/usuarios') => FakeResponse(
          200,
          _ok(_pagina([parceiro(status)])),
        ),
        ('GET', '/usuarios/p1') => FakeResponse(
          200,
          _ok({
            ...parceiro(status),
            'enderecos': <Object>[],
            'pedidos': <Object>[],
            'detalhes_parceiro': {
              'responsavel_nome': 'João da Silva',
              'endereco_coleta': 'Rua das Flores, 100',
              'capacidade_diaria_kg': 500,
              'materiais': ['Plástico'],
            },
          }),
        ),
        ('PATCH', '/usuarios/p1/status') => FakeResponse(
          200,
          _ok(parceiro('ATIVO')),
        ),
        _ => _naoEncontrado,
      };
    }

    testWidgets('lista só parceiros e mostra os pendentes primeiro', (
      tester,
    ) async {
      final adapter = await _abrir(tester, const GestaoParceirosPage(), api);

      final consulta = adapter.requests
          .firstWhere((r) => r.path == '/usuarios')
          .queryParameters;

      expect(consulta['tipo_perfil'], 'PARCEIRO');
      expect(consulta['status'], 'PENDENTE');
      expect(find.text('Recicla Mais Ltda'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
    });

    testWidgets('aprovar cadastro muda o status para ATIVO', (tester) async {
      final adapter = await _abrir(tester, const GestaoParceirosPage(), api);

      await tester.tap(find.byKey(const Key('aprovar_p1')));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere((r) => r.path == '/usuarios/p1/status'),
      );

      expect(corpo['status'], 'ATIVO');
      expect(find.text('Recicla Mais Ltda está ativo.'), findsOneWidget);
    });

    testWidgets('o detalhe mostra responsável, endereço e materiais', (
      tester,
    ) async {
      await _abrir(tester, const GestaoParceirosPage(), api);

      await tester.tap(find.byKey(const Key('parceiro_p1')));
      await tester.pumpAndSettle();

      expect(find.text('João da Silva'), findsOneWidget);
      expect(find.text('Rua das Flores, 100'), findsOneWidget);
      expect(find.text('Plástico'), findsOneWidget);
      expect(find.byKey(const Key('detalhe_aprovar')), findsOneWidget);
      expect(find.byKey(const Key('detalhe_recusar')), findsOneWidget);
    });

    testWidgets('parceiro ativo pode ser suspenso', (tester) async {
      final adapter = await _abrir(
        tester,
        const GestaoParceirosPage(),
        (request) => api(request, status: 'ATIVO'),
      );

      await tester.tap(find.byKey(const Key('parceiros_filtro_ativos')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('parceiro_p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('detalhe_suspender')));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.firstWhere((r) => r.path == '/usuarios/p1/status'),
      );

      expect(corpo['status'], 'SUSPENSO');
    });
  });

  group('conversas', () {
    FakeResponse api(RequestOptions request, {String perfil = 'PARCEIRO'}) {
      return switch (request.path) {
        '/usuarios/perfil' => FakeResponse(200, _ok(_usuario(perfil))),
        '/chat/nao-lidas' => FakeResponse(
          200,
          _ok({'conversas': 2, 'mensagens': 5}),
        ),
        '/chat/conversas' => FakeResponse(
          200,
          _ok(
            _pagina([
              {
                'id': 'cv1',
                'tipo': 'COLETA',
                'status': 'ABERTA',
                'coleta_id': 'c1',
                'coleta_codigo': 'COL-REC-AB12CD34',
                'contato_nome': 'Maria Cliente',
                'contato_detalhe': 'Coleta COL-REC-AB12CD34',
                'nao_lidas': 2,
                'ultima_atividade_em': DateTime.now().toUtc().toIso8601String(),
              },
            ]),
          ),
        ),
        _ => _naoEncontrado,
      };
    }

    testWidgets('parceiro vê as conversas das coletas e a barra dele', (
      tester,
    ) async {
      await _abrir(tester, const ConversasPage(), api);

      expect(find.text('Maria Cliente'), findsOneWidget);
      // Sem filtros: o parceiro só tem chats de coleta.
      expect(find.text('Pedidos'), findsNothing);
      expect(find.text('Chamados'), findsNothing);
      // Barra de reciclagem do parceiro: cinco abas.
      expect(find.text('Sinalizações'), findsOneWidget);
      expect(find.text('Coletas'), findsOneWidget);
      expect(find.text('Perfil'), findsOneWidget);
    });

    testWidgets('cliente filtra as conversas de coleta', (tester) async {
      await _abrir(
        tester,
        const ConversasPage(),
        (request) => api(request, perfil: 'CONSUMIDOR'),
      );

      expect(find.text('Coletas'), findsOneWidget);
      expect(find.text('Chamados'), findsOneWidget);
    });

    testWidgets('o admin tem uma aba para acompanhar as coletas', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const ConversasPage(),
        (request) => api(request, perfil: 'ADMIN'),
      );

      expect(find.text('Coletas'), findsOneWidget);

      await tester.tap(find.text('Coletas'));
      await tester.pumpAndSettle();

      final tipos = adapter.requests
          .where((r) => r.path == '/chat/conversas')
          .map((r) => r.queryParameters['tipo']);

      expect(tipos, contains('COLETA'));
    });

    testWidgets('o chat da coleta tem o menu "Ver dados da coleta"', (
      tester,
    ) async {
      await _abrir(
        tester,
        ChatPage(
          conversa: Conversa.fromJson({
            'id': 'cv1',
            'tipo': 'COLETA',
            'status': 'ABERTA',
            'coleta_id': 'c1',
            'contato_nome': 'Maria Cliente',
          }),
        ),
        (request) {
          if (request.path == '/chat/conversas/cv1') {
            return FakeResponse(
              200,
              _ok({
                'id': 'cv1',
                'tipo': 'COLETA',
                'status': 'ABERTA',
                'coleta_id': 'c1',
                'contato_nome': 'Maria Cliente',
                'pode_enviar': true,
                'coleta': _coleta(),
              }),
            );
          }
          if (request.path == '/chat/conversas/cv1/mensagens') {
            return FakeResponse(
              200,
              _ok({'items': <Object>[], 'tem_anteriores': false}),
            );
          }
          return api(request);
        },
      );

      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ver dados da coleta'));
      await tester.pumpAndSettle();

      expect(find.text('Coleta COL-REC-AB12CD34'), findsOneWidget);
      expect(find.text('Recicla Mais'), findsOneWidget);
      expect(
        find.text('Av. Paulista, 1000 - Bela Vista - São Paulo - SP'),
        findsOneWidget,
      );
    });
  });
}
