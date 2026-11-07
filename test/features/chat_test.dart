import 'package:app_collect_express_with_flutter/core/models/chat.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/configuracoes_admin_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/detalhes_pedido_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/gestao_pedidos_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/data/chat_repository.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/chat_formatos.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/pages/conversas_page.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/acompanhar_pedido_page.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/meus_pedidos_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _ok(Object? data) => {'success': true, 'data': data};

String get _agora => DateTime.now().toUtc().toIso8601String();

Map<String, dynamic> _conversa({
  String id = 'c1',
  String tipo = 'PEDIDO',
  String nome = 'Caçambas Alfa',
  String? detalhe = 'Pedido COL-ABC123',
  String status = 'ABERTA',
  Map<String, dynamic>? ultima,
  int naoLidas = 0,
  bool denunciada = false,
  bool podeEnviar = true,
  String? motivoBloqueio,
  bool somenteLeitura = false,
  String? aluguelId = 'p1',
  Map<String, dynamic>? pedido,
}) => {
  'id': id,
  'tipo': tipo,
  'status': status,
  'assunto': tipo == 'CHAMADO' ? 'Cobrança' : null,
  'aluguel_id': aluguelId,
  'pedido_codigo': aluguelId == null ? null : 'COL-ABC123',
  'contato_nome': nome,
  'contato_detalhe': detalhe,
  'ultima_mensagem': ultima,
  'ultima_atividade_em': _agora,
  'nao_lidas': naoLidas,
  'denunciada': denunciada,
  'pode_enviar': podeEnviar,
  'motivo_bloqueio': motivoBloqueio,
  'somente_leitura': somenteLeitura,
  'fechada_em': null,
  'criada_em': _agora,
  'pedido': ?pedido,
};

Map<String, dynamic> _msg(
  int id,
  String texto, {
  bool minha = false,
  bool lida = false,
  String? remetente,
}) => {
  'id': id,
  'texto': texto,
  'lado': minha ? 'CLIENTE' : 'CACAMBEIRO',
  'minha': minha,
  'criada_em': _agora,
  'lida': lida,
  'remetente_nome': remetente,
};

const _pedido = {
  'id': 'p1',
  'codigo': 'COL-ABC123',
  'status_aluguel': 'EM_USO',
  'status_pagamento': 'PAGO',
  'data_pedido': '2026-10-20T15:00:00.000Z',
  'data_inicio': '2026-10-25T00:00:00.000Z',
  'dias_aluguel': 3,
  'preco_final': 340,
  'endereco': {
    'cep': '01310100',
    'logradouro': 'Av. Paulista',
    'numero': '1000',
    'bairro': 'Bela Vista',
    'cidade_estado': 'São Paulo - SP',
  },
  'itens': [
    {
      'nome': 'Caçamba 5m³',
      'tipo_residuo': 'Entulho',
      'tamanho_m3': 5,
      'quantidade': 1,
      'dias_aluguel': 3,
      'preco_diaria': 100,
    },
  ],
};

Map<String, dynamic> _usuario(String perfil) => {
  'id': 'u-$perfil',
  'nome_completo': 'Usuário $perfil',
  'email': 'u@teste.com',
  'tipo_perfil': perfil,
  'status': 'ATIVO',
};

/// API de chat simulada. Guarda o que o app mandou para os testes olharem.
class _ApiDeChat {
  _ApiDeChat({
    this.perfil = 'CONSUMIDOR',
    List<Map<String, dynamic>>? conversas,
    List<Map<String, dynamic>>? mensagens,
    Map<String, dynamic>? detalhe,
    this.naoLidas = const {'conversas': 0, 'mensagens': 0},
    this.respostaEnvio,
    this.extra,
  }) : conversas = conversas ?? [],
       mensagens = mensagens ?? [],
       detalhe = detalhe ?? _conversa(pedido: _pedido);

  final String perfil;
  final List<Map<String, dynamic>> conversas;
  final List<Map<String, dynamic>> mensagens;
  Map<String, dynamic> detalhe;
  Map<String, dynamic> naoLidas;

  /// Substitui a resposta ao envio de mensagem (para simular erros).
  final FakeResponse? respostaEnvio;
  final FakeResponse? Function(RequestOptions request)? extra;

  final enviadas = <Map<String, dynamic>>[];

  FakeResponse responder(RequestOptions request) {
    final outro = extra?.call(request);
    if (outro != null) return outro;

    final caminho = request.path;
    final metodo = request.method;

    if (caminho == '/usuarios/perfil') {
      return FakeResponse(200, _ok(_usuario(perfil)));
    }

    if (caminho == '/chat/nao-lidas') {
      return FakeResponse(200, _ok(naoLidas));
    }

    if (caminho == '/chat/conversas') {
      return FakeResponse(
        200,
        _ok({
          'items': conversas,
          'pagination': {
            'total': conversas.length,
            'page': 1,
            'per_page': 30,
            'total_pages': 1,
          },
        }),
      );
    }

    if (caminho == '/chat/conversas/c1' && metodo == 'GET') {
      return FakeResponse(200, _ok(detalhe));
    }

    if (caminho == '/chat/conversas/c1/mensagens') {
      if (metodo == 'POST') {
        if (respostaEnvio != null) return respostaEnvio!;
        final corpo = sentBody(request);
        enviadas.add(corpo);
        final nova = _msg(
          100 + enviadas.length,
          corpo['texto'] as String,
          minha: true,
        );
        mensagens.add(nova);
        return FakeResponse(201, _ok(nova));
      }

      return FakeResponse(
        200,
        _ok({'items': mensagens, 'tem_anteriores': false}),
      );
    }

    return const FakeResponse(404, {'success': false, 'message': 'não'});
  }
}

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  _ApiDeChat api, {
  bool logado = true,
  Map<String, WidgetBuilder> rotas = const {},
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage(accessToken: logado ? 'jwt' : null);
  final adapter = FakeApiAdapter(api.responder);

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
          ...rotas,
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

Conversa _modelo([Map<String, dynamic>? json]) =>
    Conversa.fromJson(json ?? _conversa());

Finder _item(String texto) => find.text(texto);

void main() {
  group('modelos e formatos', () {
    test('Conversa lê os campos da API', () {
      final conversa = Conversa.fromJson(
        _conversa(
          tipo: 'CHAMADO',
          status: 'FECHADA',
          naoLidas: 3,
          denunciada: true,
          ultima: {'texto': 'Oi', 'minha': true, 'criada_em': _agora},
          pedido: _pedido,
        ),
      );

      expect(conversa.tipo, TipoConversa.chamado);
      expect(conversa.aberta, isFalse);
      expect(conversa.naoLidas, 3);
      expect(conversa.denunciada, isTrue);
      expect(conversa.ultimaMensagem!.minha, isTrue);
      expect(conversa.pedido!.codigo, 'COL-ABC123');
      expect(conversa.pedido!.itens.single.quantidade, 1);
      expect(
        conversa.pedido!.enderecoTexto,
        'Av. Paulista, 1000 - Bela Vista - São Paulo - SP',
      );
      expect(conversa.temPedido, isTrue);
    });

    test('Mensagem e NaoLidas', () {
      final mensagem = Mensagem.fromJson(
        _msg(7, 'Olá', minha: true, lida: true),
      );

      expect(mensagem.id, 7);
      expect(mensagem.minha, isTrue);
      expect(mensagem.lida, isTrue);
      expect(
        NaoLidas.fromJson({'conversas': '2', 'mensagens': 5}).conversas,
        2,
      );
      expect(NaoLidas.zero.mensagens, 0);
    });

    test('horários da lista: hoje, ontem e datas antigas', () {
      final agora = DateTime(2026, 11, 6, 15, 30);

      expect(
        formatarAtividade(DateTime(2026, 11, 6, 9, 5), agora: agora),
        '09:05',
      );
      expect(
        formatarAtividade(DateTime(2026, 11, 5, 23, 59), agora: agora),
        'Ontem',
      );
      expect(formatarAtividade(DateTime(2026, 10, 25), agora: agora), '25/10');
      expect(
        formatarAtividade(DateTime(2025, 10, 25), agora: agora),
        '25/10/2025',
      );
      expect(formatarAtividade(null), '');
      expect(
        formatarDiaDaConversa(DateTime(2026, 11, 6), agora: agora),
        'Hoje',
      );
      expect(
        formatarDiaDaConversa(DateTime(2026, 11, 5), agora: agora),
        'Ontem',
      );
      expect(
        formatarDiaDaConversa(DateTime(2026, 10, 25), agora: agora),
        '25/10/2026',
      );
      expect(inicialDoNome('  maria'), 'M');
      expect(inicialDoNome(''), '?');
    });

    test('mesclarMensagens não repete, ordena e atualiza o "lida"', () {
      final atuais = [
        Mensagem.fromJson(_msg(1, 'a')),
        Mensagem.fromJson(_msg(3, 'c', minha: true)),
      ];
      final novas = [
        Mensagem.fromJson(_msg(2, 'b')),
        Mensagem.fromJson(_msg(3, 'c', minha: true, lida: true)),
      ];

      final mescladas = mesclarMensagens(atuais, novas);

      expect(mescladas.map((m) => m.id), [1, 2, 3]);
      expect(mescladas.last.lida, isTrue);
    });
  });

  test('o repositório manda filtros, cursores e corpos certos', () async {
    final adapter = FakeApiAdapter((request) {
      if (request.path == '/chat/conversas') {
        return FakeResponse(
          200,
          _ok({
            'items': [],
            'pagination': {
              'total': 0,
              'page': 1,
              'per_page': 30,
              'total_pages': 0,
            },
          }),
        );
      }
      return FakeResponse(200, _ok(_conversa()));
    });
    final repositorio = ChatRepository(
      ApiClient(storage: InMemoryTokenStorage(), adapter: adapter),
    );

    await repositorio.listarConversas();
    await repositorio.listarConversas(
      tipo: TipoConversa.chamado,
      aberta: false,
      denunciadas: true,
      busca: ' maria ',
      pagina: 2,
    );
    await repositorio.mensagens('c1', antes: 40);
    await repositorio.abrirChamado(assunto: ' Cobrança ', mensagem: ' Oi ');
    await repositorio.abrirChamado(
      assunto: 'X',
      mensagem: 'Y',
      aluguelId: 'p1',
    );
    await repositorio.denunciar('c1');
    await repositorio.denunciar('c1', motivo: 'Ofensa');

    final primeira = adapter.requests[0].queryParameters;
    expect(primeira.containsKey('tipo'), isFalse);
    expect(primeira.containsKey('status'), isFalse);
    expect(primeira.containsKey('denunciadas'), isFalse);

    final segunda = adapter.requests[1].queryParameters;
    expect(segunda['tipo'], 'CHAMADO');
    expect(segunda['status'], 'FECHADA');
    expect(segunda['denunciadas'], true);
    expect(segunda['busca'], 'maria');
    expect(segunda['page'], 2);

    expect(adapter.requests[2].queryParameters['antes'], 40);
    expect(sentBody(adapter.requests[3]), {
      'assunto': 'Cobrança',
      'mensagem': 'Oi',
    });
    expect(sentBody(adapter.requests[4])['aluguel_id'], 'p1');
    expect(sentBody(adapter.requests[5]), isEmpty);
    expect(sentBody(adapter.requests[6]), {'motivo': 'Ofensa'});
  });

  group('lista de conversas', () {
    final conversas = [
      _conversa(
        ultima: {'texto': 'Chego às 9h', 'minha': false, 'criada_em': _agora},
        naoLidas: 2,
      ),
      _conversa(
        id: 'c2',
        tipo: 'CHAMADO',
        nome: 'Suporte CollectExpress',
        detalhe: 'Cobrança',
        aluguelId: null,
        status: 'FECHADA',
        ultima: {'texto': 'Resolvido', 'minha': true, 'criada_em': _agora},
      ),
    ];

    testWidgets('cliente vê nomes, prévia, bolha e o botão de novo chamado', (
      tester,
    ) async {
      final api = _ApiDeChat(
        conversas: conversas,
        naoLidas: {'conversas': 1, 'mensagens': 2},
      );

      final adapter = await _abrir(tester, const ConversasPage(), api);

      expect(_item('Caçambas Alfa'), findsOneWidget);
      expect(_item('Chego às 9h'), findsOneWidget);
      expect(_item('Você: Resolvido'), findsOneWidget);
      expect(_item('Encerrado'), findsOneWidget);
      expect(find.byKey(const Key('novo_chamado')), findsOneWidget);

      // Bolha da conversa (2) e da aba (1 conversa não lida).
      expect(find.widgetWithText(Container, '2'), findsWidgets);
      expect(find.widgetWithText(Badge, '1'), findsOneWidget);
      expect(_item('Conversas'), findsWidgets);
      expect(adapter.paths, contains('GET /chat/nao-lidas'));
    });

    testWidgets('filtros pedem só o tipo escolhido', (tester) async {
      final api = _ApiDeChat(conversas: conversas);
      final adapter = await _abrir(tester, const ConversasPage(), api);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Chamados'));
      await tester.pumpAndSettle();
      expect(adapter.requests.last.queryParameters['tipo'], 'CHAMADO');

      await tester.tap(find.widgetWithText(ChoiceChip, 'Pedidos'));
      await tester.pumpAndSettle();
      expect(adapter.requests.last.queryParameters['tipo'], 'PEDIDO');
    });

    testWidgets('caçambeiro tem o filtro Suporte e não abre chamado', (
      tester,
    ) async {
      final api = _ApiDeChat(perfil: 'CACAMBEIRO', conversas: conversas);
      final adapter = await _abrir(tester, const ConversasPage(), api);

      expect(find.byKey(const Key('novo_chamado')), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Suporte'));
      await tester.pumpAndSettle();

      expect(
        adapter.requests.last.queryParameters['tipo'],
        'SUPORTE_CACAMBEIRO',
      );
    });

    testWidgets('sem conversas mostra a explicação', (tester) async {
      await _abrir(tester, const ConversasPage(), _ApiDeChat());

      expect(
        find.textContaining('Suas conversas aparecem aqui'),
        findsOneWidget,
      );
    });

    testWidgets('visitante é levado ao login', (tester) async {
      final adapter = await _abrir(
        tester,
        const ConversasPage(),
        _ApiDeChat(),
        logado: false,
      );

      expect(find.textContaining('Entre na sua conta'), findsOneWidget);
      expect(adapter.paths, isNot(contains('GET /chat/conversas')));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('tela de login'), findsOneWidget);
    });

    testWidgets('erro da API mostra "Tentar novamente"', (tester) async {
      final api = _ApiDeChat(
        extra: (request) => request.path == '/chat/conversas'
            ? const FakeResponse.networkError()
            : null,
      );

      await _abrir(tester, const ConversasPage(), api);

      expect(find.text('Tentar novamente'), findsOneWidget);
    });

    testWidgets('a bolha da aba some quando não há não lidas', (tester) async {
      await _abrir(tester, const ConversasPage(), _ApiDeChat());

      expect(find.byType(Badge), findsOneWidget);
      expect(tester.widget<Badge>(find.byType(Badge)).isLabelVisible, isFalse);
    });
  });

  group('lista do admin', () {
    testWidgets('três abas, filtros e denunciadas em destaque', (tester) async {
      final api = _ApiDeChat(
        perfil: 'ADMIN',
        conversas: [
          _conversa(
            tipo: 'CHAMADO',
            nome: 'Maria Cliente',
            detalhe: 'Cobrança',
            aluguelId: null,
            denunciada: true,
            ultima: {'texto': 'Ajuda', 'minha': false, 'criada_em': _agora},
          ),
        ],
      );

      final adapter = await _abrir(tester, const ConversasPage(), api);

      expect(find.widgetWithText(Tab, 'Chamados'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Fornecedores'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Pedidos'), findsOneWidget);
      expect(_item('Maria Cliente'), findsOneWidget);
      expect(_item('Denunciada'), findsOneWidget);
      expect(find.byKey(const Key('novo_chamado')), findsNothing);

      var consulta = adapter.requests.lastWhere(
        (r) => r.path == '/chat/conversas',
      );
      expect(consulta.queryParameters['tipo'], 'CHAMADO');
      expect(consulta.queryParameters['status'], 'ABERTA');

      await tester.tap(find.widgetWithText(ChoiceChip, 'Encerrados'));
      await tester.pumpAndSettle();
      consulta = adapter.requests.lastWhere((r) => r.path == '/chat/conversas');
      expect(consulta.queryParameters['status'], 'FECHADA');

      await tester.tap(find.byKey(const Key('admin_denunciadas')));
      await tester.pumpAndSettle();
      consulta = adapter.requests.lastWhere((r) => r.path == '/chat/conversas');
      expect(consulta.queryParameters['denunciadas'], true);

      await tester.enterText(find.byKey(const Key('admin_busca')), 'maria');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      consulta = adapter.requests.lastWhere((r) => r.path == '/chat/conversas');
      expect(consulta.queryParameters['busca'], 'maria');

      await tester.tap(find.widgetWithText(Tab, 'Fornecedores'));
      await tester.pumpAndSettle();
      consulta = adapter.requests.lastWhere((r) => r.path == '/chat/conversas');
      expect(consulta.queryParameters['tipo'], 'SUPORTE_CACAMBEIRO');

      await tester.tap(find.widgetWithText(Tab, 'Pedidos'));
      await tester.pumpAndSettle();
      consulta = adapter.requests.lastWhere((r) => r.path == '/chat/conversas');
      expect(consulta.queryParameters['tipo'], 'PEDIDO');
    });

    testWidgets('a barra do admin troca Config por Conversas', (tester) async {
      await _abrir(tester, const ConversasPage(), _ApiDeChat(perfil: 'ADMIN'));

      expect(find.text('Config'), findsNothing);
      expect(find.text('Conversas'), findsWidgets);
    });

    testWidgets('Configurações continuam acessíveis, sem aba marcada', (
      tester,
    ) async {
      await _abrir(
        tester,
        const ConfiguracoesAdminPage(),
        _ApiDeChat(perfil: 'ADMIN'),
      );

      expect(find.byType(ConfiguracoesAdminPage), findsOneWidget);
      expect(find.text('Conversas'), findsOneWidget);
    });
  });

  group('tela da conversa', () {
    testWidgets('mostra contato, mensagens e o "lida" nas minhas', (
      tester,
    ) async {
      final api = _ApiDeChat(
        mensagens: [
          _msg(1, 'A caçamba chega hoje?', minha: true, lida: true),
          _msg(2, 'Chega às 9h.'),
          _msg(3, 'Obrigada', minha: true),
        ],
      );

      final adapter = await _abrir(tester, ChatPage(conversa: _modelo()), api);

      expect(_item('Caçambas Alfa'), findsOneWidget);
      expect(_item('Pedido COL-ABC123'), findsOneWidget);
      expect(_item('A caçamba chega hoje?'), findsOneWidget);
      expect(_item('Chega às 9h.'), findsOneWidget);
      expect(_item('Hoje'), findsOneWidget);
      expect(find.byKey(const Key('mensagem_lida')), findsOneWidget);
      expect(find.byKey(const Key('mensagem_enviada')), findsOneWidget);
      expect(find.byTooltip('Mais opções'), findsOneWidget);

      // O detalhe vem antes das mensagens.
      final chat = adapter.paths
          .where((p) => p.contains('/chat/conversas/c1'))
          .toList();
      expect(chat.first, 'GET /chat/conversas/c1');
      expect(chat[1], 'GET /chat/conversas/c1/mensagens');
    });

    testWidgets('enviar manda o texto aparado e limpa o campo', (tester) async {
      final api = _ApiDeChat();
      await _abrir(tester, ChatPage(conversa: _modelo()), api);

      expect(
        _item('Nenhuma mensagem ainda. Comece a conversa!'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const Key('chat_campo')),
        '  Bom dia!  ',
      );
      await tester.tap(find.byKey(const Key('chat_enviar')));
      await tester.pumpAndSettle();

      expect(api.enviadas, [
        {'texto': 'Bom dia!'},
      ]);
      expect(_item('Bom dia!'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('chat_campo')))
            .controller!
            .text,
        isEmpty,
      );

      // Texto vazio não chama a API.
      await tester.enterText(find.byKey(const Key('chat_campo')), '   ');
      await tester.tap(find.byKey(const Key('chat_enviar')));
      await tester.pumpAndSettle();
      expect(api.enviadas, hasLength(1));
    });

    testWidgets('busca mensagens novas sozinha', (tester) async {
      final api = _ApiDeChat(mensagens: [_msg(1, 'Oi')]);
      final adapter = await _abrir(tester, ChatPage(conversa: _modelo()), api);

      api.mensagens.add(_msg(2, 'Pode confirmar o endereço?'));
      await tester.pump(intervaloDaConversa);
      await tester.pumpAndSettle();

      expect(_item('Pode confirmar o endereço?'), findsOneWidget);
      expect(
        adapter.paths
            .where((p) => p == 'GET /chat/conversas/c1/mensagens')
            .length,
        greaterThan(1),
      );
    });

    testWidgets('conversa bloqueada troca o campo pelo motivo', (tester) async {
      final api = _ApiDeChat(
        detalhe: _conversa(
          podeEnviar: false,
          motivoBloqueio: 'A conversa ficou só para leitura 7 dias depois do fim do pedido.',
          pedido: _pedido,
        ),
        mensagens: [_msg(1, 'Foi ótimo')],
      );

      await _abrir(tester, ChatPage(conversa: _modelo()), api);

      expect(find.byKey(const Key('chat_campo')), findsNothing);
      expect(find.byKey(const Key('chat_bloqueado')), findsOneWidget);
      expect(find.textContaining('só para leitura'), findsOneWidget);
      expect(_item('Foi ótimo'), findsOneWidget);
    });

    testWidgets('chamado encerrado durante a digitação recarrega e bloqueia', (
      tester,
    ) async {
      final api = _ApiDeChat(
        respostaEnvio: const FakeResponse(409, {
          'success': false,
          'message': 'Este chamado foi encerrado. Abra um novo se precisar.',
          'code': 'CONVERSATION_CLOSED',
        }),
      );
      await _abrir(tester, ChatPage(conversa: _modelo()), api);

      api.detalhe = _conversa(
        tipo: 'CHAMADO',
        status: 'FECHADA',
        podeEnviar: false,
        motivoBloqueio: 'Este chamado foi encerrado. Abra um novo se precisar.',
      );

      await tester.enterText(find.byKey(const Key('chat_campo')), 'Alô?');
      await tester.tap(find.byKey(const Key('chat_enviar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chat_bloqueado')), findsOneWidget);
      expect(find.byKey(const Key('chat_campo')), findsNothing);
    });

    testWidgets('erro ao abrir mostra "Tentar novamente" e recarrega', (
      tester,
    ) async {
      var falhar = true;
      final api = _ApiDeChat(
        mensagens: [_msg(1, 'Voltou')],
        extra: (request) => falhar && request.path == '/chat/conversas/c1'
            ? const FakeResponse.networkError()
            : null,
      );

      await _abrir(tester, ChatPage(conversa: _modelo()), api);
      expect(find.text('Tentar novamente'), findsOneWidget);

      falhar = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();

      expect(_item('Voltou'), findsOneWidget);
    });

    testWidgets('carrega mensagens anteriores', (tester) async {
      final api = _ApiDeChat(
        mensagens: [_msg(40, 'Recente')],
        extra: (request) {
          if (request.path == '/chat/conversas/c1/mensagens' &&
              request.method == 'GET') {
            if (request.queryParameters['antes'] != null) {
              return FakeResponse(
                200,
                _ok({
                  'items': [_msg(10, 'Bem antiga')],
                  'tem_anteriores': false,
                }),
              );
            }
            return FakeResponse(
              200,
              _ok({
                'items': [_msg(40, 'Recente')],
                'tem_anteriores': true,
              }),
            );
          }
          return null;
        },
      );

      final adapter = await _abrir(tester, ChatPage(conversa: _modelo()), api);

      await tester.tap(find.text('Carregar mensagens anteriores'));
      await tester.pumpAndSettle();

      expect(_item('Bem antiga'), findsOneWidget);
      expect(_item('Recente'), findsOneWidget);
      expect(
        adapter.requests.any((r) => r.queryParameters['antes'] == 40),
        isTrue,
      );
    });
  });

  group('menu da conversa (⋮)', () {
    Future<void> abrirMenu(WidgetTester tester) async {
      await tester.tap(find.byTooltip('Mais opções'));
      await tester.pumpAndSettle();
    }

    testWidgets('cliente vê dados do pedido, sem telefone', (tester) async {
      await _abrir(tester, ChatPage(conversa: _modelo()), _ApiDeChat());

      await abrirMenu(tester);
      expect(find.text('Ver dados do pedido'), findsOneWidget);
      expect(find.text('Denunciar conversa'), findsOneWidget);
      expect(find.text('Encerrar chamado'), findsNothing);

      await tester.tap(find.text('Ver dados do pedido'));
      await tester.pumpAndSettle();

      expect(find.text('Pedido COL-ABC123'), findsWidgets);
      expect(find.text('Em uso'), findsOneWidget);
      expect(find.text('Pago'), findsOneWidget);
      expect(find.textContaining('Av. Paulista, 1000'), findsOneWidget);
      expect(find.textContaining('1× Caçamba 5m³'), findsOneWidget);
      expect(find.text('R\$ 340,00'), findsOneWidget);
      expect(find.textContaining('elefone'), findsNothing);
    });

    testWidgets(
      'chamado do cliente não tem "Ver dados do pedido" sem vínculo',
      (tester) async {
        final chamado = _conversa(
          tipo: 'CHAMADO',
          nome: 'Suporte CollectExpress',
          aluguelId: null,
        );

        await _abrir(
          tester,
          ChatPage(conversa: _modelo(chamado)),
          _ApiDeChat(detalhe: chamado),
        );

        await abrirMenu(tester);
        expect(find.text('Ver dados do pedido'), findsNothing);
        expect(find.text('Denunciar conversa'), findsOneWidget);
      },
    );

    testWidgets('denunciar manda o motivo e confirma', (tester) async {
      final api = _ApiDeChat(
        extra: (request) => request.path == '/chat/conversas/c1/denunciar'
            ? const FakeResponse(201, {
                'success': true,
                'data': {'denunciada': true},
              })
            : null,
      );
      final adapter = await _abrir(tester, ChatPage(conversa: _modelo()), api);

      await abrirMenu(tester);
      await tester.tap(find.text('Denunciar conversa'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('denuncia_motivo')),
        'Linguagem ofensiva',
      );
      await tester.tap(find.byKey(const Key('denuncia_enviar')));
      await tester.pumpAndSettle();

      final pedido = adapter.requests.firstWhere(
        (r) => r.path == '/chat/conversas/c1/denunciar',
      );
      expect(sentBody(pedido), {'motivo': 'Linguagem ofensiva'});
      expect(find.textContaining('Denúncia enviada'), findsOneWidget);
    });

    testWidgets('cancelar a denúncia não chama a API', (tester) async {
      final adapter = await _abrir(
        tester,
        ChatPage(conversa: _modelo()),
        _ApiDeChat(),
      );

      await abrirMenu(tester);
      await tester.tap(find.text('Denunciar conversa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(adapter.paths.any((p) => p.contains('denunciar')), isFalse);
    });

    testWidgets('denúncia repetida mostra a mensagem da API', (tester) async {
      final api = _ApiDeChat(
        extra: (request) => request.path == '/chat/conversas/c1/denunciar'
            ? const FakeResponse(409, {
                'success': false,
                'message':
                    'Você já denunciou esta conversa. A equipe vai analisar.',
                'code': 'ALREADY_REPORTED',
              })
            : null,
      );
      await _abrir(tester, ChatPage(conversa: _modelo()), api);

      await abrirMenu(tester);
      await tester.tap(find.text('Denunciar conversa'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('denuncia_enviar')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Você já denunciou'), findsOneWidget);
    });

    testWidgets('admin encerra o chamado depois de confirmar', (tester) async {
      final chamado = _conversa(
        tipo: 'CHAMADO',
        nome: 'Maria Cliente',
        detalhe: 'Cobrança',
        aluguelId: null,
      );
      final fechado = _conversa(
        tipo: 'CHAMADO',
        nome: 'Maria Cliente',
        detalhe: 'Cobrança',
        aluguelId: null,
        status: 'FECHADA',
        podeEnviar: false,
        motivoBloqueio: 'Este chamado foi encerrado. Abra um novo se precisar.',
      );

      final api = _ApiDeChat(
        perfil: 'ADMIN',
        detalhe: chamado,
        extra: (request) => request.path == '/chat/chamados/c1/fechar'
            ? FakeResponse(200, _ok(fechado))
            : null,
      );
      final adapter = await _abrir(
        tester,
        ChatPage(conversa: _modelo(chamado)),
        api,
      );

      await abrirMenu(tester);
      expect(find.text('Encerrar chamado'), findsOneWidget);

      await tester.tap(find.text('Encerrar chamado'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Encerrar'));
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('PATCH /chat/chamados/c1/fechar'));
      expect(find.byKey(const Key('chat_bloqueado')), findsOneWidget);
      expect(find.textContaining('Encerrado'), findsWidgets);

      await abrirMenu(tester);
      expect(find.text('Encerrar chamado'), findsNothing);
    });

    testWidgets('voltar na confirmação não encerra', (tester) async {
      final chamado = _conversa(tipo: 'CHAMADO', aluguelId: null);
      final adapter = await _abrir(
        tester,
        ChatPage(conversa: _modelo(chamado)),
        _ApiDeChat(perfil: 'ADMIN', detalhe: chamado),
      );

      await abrirMenu(tester);
      await tester.tap(find.text('Encerrar chamado'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Voltar'));
      await tester.pumpAndSettle();

      expect(adapter.paths.any((p) => p.contains('fechar')), isFalse);
    });

    testWidgets('admin marca a denúncia como analisada', (tester) async {
      final denunciada = _conversa(
        tipo: 'SUPORTE_CACAMBEIRO',
        nome: 'Caçambas Alfa',
        aluguelId: null,
        denunciada: true,
      );
      final api = _ApiDeChat(
        perfil: 'ADMIN',
        detalhe: denunciada,
        extra: (request) => request.path == '/chat/conversas/c1/denuncia'
            ? FakeResponse(
                200,
                _ok(
                  _conversa(
                    tipo: 'SUPORTE_CACAMBEIRO',
                    nome: 'Caçambas Alfa',
                    aluguelId: null,
                  ),
                ),
              )
            : null,
      );
      final adapter = await _abrir(
        tester,
        ChatPage(conversa: _modelo(denunciada)),
        api,
      );

      expect(find.textContaining('foi denunciada'), findsOneWidget);

      await abrirMenu(tester);
      await tester.tap(find.text('Marcar denúncia como analisada'));
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('PATCH /chat/conversas/c1/denuncia'));
      expect(find.textContaining('foi denunciada'), findsNothing);
    });

    testWidgets(
      'admin acompanha pedido em leitura: sem campo e sem denunciar',
      (tester) async {
        final observada = _conversa(
          nome: 'Maria × Alfa',
          somenteLeitura: true,
          podeEnviar: false,
          motivoBloqueio:
              'Administradores apenas acompanham conversas de pedidos.',
          pedido: _pedido,
        );

        await _abrir(
          tester,
          ChatPage(conversa: _modelo(observada)),
          _ApiDeChat(
            perfil: 'ADMIN',
            detalhe: observada,
            mensagens: [_msg(1, 'Oi')],
          ),
        );

        expect(find.byKey(const Key('chat_campo')), findsNothing);
        expect(
          find.textContaining('acompanhando esta conversa'),
          findsOneWidget,
        );

        await abrirMenu(tester);
        expect(find.text('Ver dados do pedido'), findsOneWidget);
        expect(find.text('Denunciar conversa'), findsNothing);
      },
    );
  });

  group('novo chamado', () {
    FakeResponse? Function(RequestOptions) rotas(FakeResponse criar) {
      return (request) {
        if (request.path == '/chat/chamados') return criar;
        if (request.path == '/alugueis/meus') {
          return FakeResponse(
            200,
            _ok({
              'items': [
                {
                  'id': 'p1',
                  'cacambeiro_nome': 'Caçambas Alfa',
                  'data_pedido': '2026-10-20T15:00:00.000Z',
                  'data_inicio': '2026-10-25',
                  'dias_aluguel': 3,
                  'preco_final': '340.00',
                  'status_aluguel': 'EM_USO',
                  'status_pagamento': 'PAGO',
                },
              ],
              'pagination': {
                'total': 1,
                'page': 1,
                'per_page': 20,
                'total_pages': 1,
              },
            }),
          );
        }
        return null;
      };
    }

    testWidgets('abre o chamado com o pedido escolhido e vai para o chat', (
      tester,
    ) async {
      final criado = _conversa(
        tipo: 'CHAMADO',
        nome: 'Suporte CollectExpress',
        detalhe: 'Cobrança errada',
        aluguelId: 'p1',
      );
      final api = _ApiDeChat(
        extra: rotas(FakeResponse(201, _ok(criado))),
        mensagens: [_msg(1, 'Fui cobrada duas vezes.', minha: true)],
      );
      final adapter = await _abrir(tester, const ConversasPage(), api);

      await tester.tap(find.byKey(const Key('novo_chamado')));
      await tester.pumpAndSettle();

      // Vazio não envia.
      await tester.tap(find.byKey(const Key('chamado_enviar')));
      await tester.pumpAndSettle();
      expect(
        find.text('Informe o assunto e descreva o problema.'),
        findsOneWidget,
      );
      expect(adapter.paths, isNot(contains('POST /chat/chamados')));

      await tester.enterText(
        find.byKey(const Key('chamado_assunto')),
        'Cobrança errada',
      );
      await tester.enterText(
        find.byKey(const Key('chamado_mensagem')),
        'Fui cobrada duas vezes.',
      );
      await tester.tap(find.byKey(const Key('chamado_pedido')));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Caçambas Alfa').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('chamado_enviar')));
      await tester.pumpAndSettle();

      final pedido = adapter.requests.firstWhere(
        (r) => r.path == '/chat/chamados',
      );
      expect(sentBody(pedido), {
        'assunto': 'Cobrança errada',
        'mensagem': 'Fui cobrada duas vezes.',
        'aluguel_id': 'p1',
      });
      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Fui cobrada duas vezes.'), findsOneWidget);
    });

    testWidgets('já existe chamado aberto: mostra o aviso e abre o existente', (
      tester,
    ) async {
      final api = _ApiDeChat(
        extra: rotas(
          const FakeResponse(409, {
            'success': false,
            'message': 'Você já tem um chamado aberto. Continue por ele ou aguarde o encerramento.',
            'code': 'CHAMADO_ALREADY_OPEN',
            'fields': {'conversa_id': 'c1'},
          }),
        ),
        detalhe: _conversa(
          tipo: 'CHAMADO',
          nome: 'Suporte CollectExpress',
          aluguelId: null,
        ),
        mensagens: [_msg(1, 'Mensagem antiga')],
      );
      await _abrir(tester, const ConversasPage(), api);

      await tester.tap(find.byKey(const Key('novo_chamado')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('chamado_assunto')), 'Outro');
      await tester.enterText(
        find.byKey(const Key('chamado_mensagem')),
        'Texto',
      );
      await tester.tap(find.byKey(const Key('chamado_enviar')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('chamado_erro')), findsOneWidget);
      expect(find.textContaining('já tem um chamado aberto'), findsOneWidget);

      await tester.tap(find.byKey(const Key('chamado_abrir_existente')));
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Mensagem antiga'), findsOneWidget);
    });
  });

  group('entrada pelos pedidos', () {
    testWidgets(
      'Meus pedidos: "Conversar com a empresa" abre a conversa do pedido',
      (tester) async {
        final api = _ApiDeChat(
          mensagens: [_msg(1, 'Bom dia')],
          extra: (request) {
            if (request.path == '/alugueis/meus') {
              return FakeResponse(
                200,
                _ok({
                  'items': [
                    {
                      'id': 'p1',
                      'cacambeiro_nome': 'Caçambas Alfa',
                      'data_pedido': '2026-10-20T15:00:00.000Z',
                      'data_inicio': '2026-10-25',
                      'dias_aluguel': 3,
                      'preco_final': '340.00',
                      'status_aluguel': 'EM_USO',
                      'status_pagamento': 'PAGO',
                    },
                  ],
                  'pagination': {
                    'total': 1,
                    'page': 1,
                    'per_page': 20,
                    'total_pages': 1,
                  },
                }),
              );
            }
            if (request.path == '/chat/pedidos/p1/conversa') {
              return FakeResponse(200, _ok(_conversa(pedido: _pedido)));
            }
            return null;
          },
        );

        final adapter = await _abrir(tester, const MeusPedidosPage(), api);

        await tester.ensureVisible(find.byKey(const Key('pedido_chat_p1')));
        await tester.tap(find.byKey(const Key('pedido_chat_p1')));
        await tester.pumpAndSettle();

        expect(adapter.paths, contains('POST /chat/pedidos/p1/conversa'));
        expect(find.byType(ChatPage), findsOneWidget);
        expect(find.text('Bom dia'), findsOneWidget);
      },
    );

    Map<String, dynamic> detalheDoPedido() => {
      'id': 'a1',
      'codigo': 'COL-ABC1234567',
      'data_pedido': '2026-10-20T10:00:00.000Z',
      'data_inicio': '2026-10-28',
      'dias_aluguel': 3,
      'preco_final': 450.5,
      'status_pagamento': 'PAGO',
      'status_aluguel': 'EM_USO',
      'valores': {'subtotal_itens': 410.5, 'taxa_entrega': 40},
      'consumidor': {
        'id': 'u2',
        'nome_completo': 'Maria Cliente',
        'email': 'maria@teste.com',
        'telefone': '11988887777',
      },
      'cacambeiro': {
        'id': 'u1',
        'nome_completo': 'Caçambas Alfa',
        'email': 'alfa@teste.com',
        'telefone': '11977776666',
        'horario_inicio': '08:00:00',
        'horario_fim': '18:00:00',
      },
    };

    FakeResponse? Function(RequestOptions) rotasDoPedido() {
      return (request) {
        if (request.path == '/alugueis/a1') {
          return FakeResponse(200, _ok(detalheDoPedido()));
        }
        if (request.path == '/chat/pedidos/a1/conversa') {
          return FakeResponse(200, _ok(_conversa(pedido: _pedido)));
        }
        return null;
      };
    }

    testWidgets(
      'Acompanhar pedido (cliente): conversa com o fornecedor, sem telefone',
      (tester) async {
        final api = _ApiDeChat(
          mensagens: [_msg(1, 'Bom dia')],
          extra: rotasDoPedido(),
        );
        final adapter = await _abrir(
          tester,
          const AcompanharPedidoPage(aluguelId: 'a1'),
          api,
        );

        expect(find.textContaining('elefone'), findsNothing);
        expect(find.textContaining('11977776666'), findsNothing);

        await tester.ensureVisible(find.byKey(const Key('pedido_chat')));
        await tester.tap(find.byKey(const Key('pedido_chat')));
        await tester.pumpAndSettle();

        expect(adapter.paths, contains('POST /chat/pedidos/a1/conversa'));
        expect(find.byType(ChatPage), findsOneWidget);
      },
    );

    testWidgets(
      'Detalhes do pedido (fornecedor): conversa com o cliente, sem telefone',
      (tester) async {
        final api = _ApiDeChat(
          perfil: 'CACAMBEIRO',
          mensagens: [_msg(1, 'Bom dia')],
          extra: rotasDoPedido(),
        );
        final adapter = await _abrir(
          tester,
          const DetalhesPedidoPage(aluguelId: 'a1'),
          api,
        );

        expect(find.textContaining('elefone'), findsNothing);
        expect(find.textContaining('11988887777'), findsNothing);
        expect(find.textContaining('(11) 98888-7777'), findsNothing);

        await tester.ensureVisible(find.byKey(const Key('pedido_chat')));
        await tester.tap(find.byKey(const Key('pedido_chat')));
        await tester.pumpAndSettle();

        expect(adapter.paths, contains('POST /chat/pedidos/a1/conversa'));
        expect(find.byType(ChatPage), findsOneWidget);
      },
    );

    testWidgets(
      'Gestão de pedidos (fornecedor): botão de conversa por pedido',
      (tester) async {
        final api = _ApiDeChat(
          perfil: 'CACAMBEIRO',
          extra: (request) {
            if (request.path == '/alugueis/gestao') {
              return FakeResponse(
                200,
                _ok([
                  {
                    'id': 'a1',
                    'consumidor_id': 'u2',
                    'cacambeiro_id': 'u1',
                    'endereco_id': 'e1',
                    'data_pedido': '2026-10-20T15:00:00.000Z',
                    'data_inicio': '2026-10-25',
                    'dias_aluguel': 3,
                    'preco_final': '763.00',
                    'status_pagamento': 'PAGO',
                    'status_aluguel': 'AGUARDANDO_ENTREGA',
                    'consumidor_nome': 'Maria Cliente',
                    'logradouro': 'Av. Paulista',
                    'numero': '1000',
                    'bairro': 'Bela Vista',
                    'cidade_estado': 'São Paulo/SP',
                    'cep': '01311200',
                  },
                ]),
              );
            }
            if (request.path == '/chat/pedidos/a1/conversa') {
              return FakeResponse(200, _ok(_conversa(pedido: _pedido)));
            }
            return null;
          },
        );
        final adapter = await _abrir(tester, const GestaoPedidosPage(), api);

        expect(find.text('Maria Cliente'), findsOneWidget);
        expect(find.textContaining('Telefone'), findsNothing);

        await tester.ensureVisible(find.byKey(const Key('pedido_chat_a1')));
        await tester.tap(find.byKey(const Key('pedido_chat_a1')));
        await tester.pumpAndSettle();

        expect(adapter.paths, contains('POST /chat/pedidos/a1/conversa'));
        expect(find.byType(ChatPage), findsOneWidget);
      },
    );
    testWidgets('erro ao abrir a conversa do pedido mostra o motivo', (
      tester,
    ) async {
      final api = _ApiDeChat(
        extra: (request) {
          if (request.path == '/alugueis/meus') {
            return FakeResponse(
              200,
              _ok({
                'items': [
                  {
                    'id': 'p1',
                    'cacambeiro_nome': 'Caçambas Alfa',
                    'data_pedido': '2026-10-20T15:00:00.000Z',
                    'data_inicio': '2026-10-25',
                    'dias_aluguel': 3,
                    'preco_final': '340.00',
                    'status_aluguel': 'EM_USO',
                    'status_pagamento': 'PAGO',
                  },
                ],
                'pagination': {
                  'total': 1,
                  'page': 1,
                  'per_page': 20,
                  'total_pages': 1,
                },
              }),
            );
          }
          if (request.path == '/chat/pedidos/p1/conversa') {
            return const FakeResponse(404, {
              'success': false,
              'message': 'Pedido não encontrado.',
              'code': 'ORDER_NOT_FOUND',
            });
          }
          return null;
        },
      );

      await _abrir(tester, const MeusPedidosPage(), api);
      await tester.ensureVisible(find.byKey(const Key('pedido_chat_p1')));
      await tester.tap(find.byKey(const Key('pedido_chat_p1')));
      await tester.pumpAndSettle();

      expect(find.text('Pedido não encontrado.'), findsOneWidget);
      expect(find.byType(ChatPage), findsNothing);
    });
  });
}
