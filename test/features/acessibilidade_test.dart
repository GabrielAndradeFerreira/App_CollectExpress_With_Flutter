import 'package:app_collect_express_with_flutter/core/accessibility/tamanho_texto.dart';
import 'package:app_collect_express_with_flutter/core/models/chat.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin_auth/presentation/pages/admin_login_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/cadastro_parceiro_reciclagem_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/pages/chat_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/pages/conversas_page.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/widgets/bolha_mensagem.dart';
import 'package:app_collect_express_with_flutter/features/chat/presentation/widgets/conversa_tile.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/agendar_coleta_page.dart';
import 'package:app_collect_express_with_flutter/core/models/reciclagem.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/coletas_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/minhas_sinalizacoes_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/ofertas_disponiveis_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/parceiro_inicio_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/perfil_parceiro_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/reciclagem_landing_page.dart';
import 'package:app_collect_express_with_flutter/features/reciclagem/presentation/pages/sinalizar_reciclagem_page.dart';
import 'package:app_collect_express_with_flutter/main.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _ok(Object? data) => {'success': true, 'data': data};

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
  {'id': 'm3', 'nome': 'Óleo de cozinha'},
  {'id': 'm4', 'nome': 'Eletrônicos'},
];

const _naoEncontrado = FakeResponse(404, {
  'success': false,
  'message': 'não encontrado',
});

final _janelaInicio = DateTime(2030, 1, 1, 8).toUtc().toIso8601String();
final _janelaFim = DateTime(2030, 1, 5, 18).toUtc().toIso8601String();

const _endereco = {
  'logradouro': 'Avenida Engenheiro Luís Carlos Berrini',
  'numero': '1000',
  'bairro': 'Cidade Monções',
  'cidade_estado': 'São Paulo - SP',
};

Map<String, dynamic> _coleta() => {
  'id': 'c1',
  'codigo': 'COL-REC-AB12CD34',
  'status': 'AGENDADA',
  'data_agendada': DateTime(2030, 1, 3, 9).toUtc().toIso8601String(),
  'cancelavel_ate': DateTime(2030, 1, 2, 9).toUtc().toIso8601String(),
  'pode_cancelar': true,
  'pode_concluir': true,
  'materiais': ['Plástico', 'Papel e papelão', 'Óleo de cozinha'],
  'descricao': 'Garrafas PET limpas e caixas de papelão desmontadas',
  'quantidade_estimada': 'Cerca de 30 kg em sacos grandes',
  'observacoes_oferta': 'Portão azul, tocar a campainha',
  'endereco': _endereco,
  'gerador_nome': 'Maria Aparecida de Souza Cliente',
  'gerador_tipo': 'Cliente',
  'parceiro_nome': 'Recicla Mais Reciclagem e Coleta Ltda',
};

FakeResponse _api(RequestOptions request, {String perfil = 'PARCEIRO'}) {
  return switch (request.path) {
    '/usuarios/perfil' => FakeResponse(
      200,
      _ok({
        'id': 'u1',
        'nome_completo': 'Recicla Mais Reciclagem e Coleta Ltda',
        'email': 'u@teste.com',
        'tipo_perfil': perfil,
        'status': 'ATIVO',
      }),
    ),
    '/materiais' => FakeResponse(200, _ok(_materiais)),
    '/coletas/resumo' => FakeResponse(
      200,
      _ok({
        'agendadas': 12,
        'concluidas': 340,
        'kg_coletados': 12345.5,
        'ofertas_abertas': 27,
      }),
    ),
    '/parceiros/me/pendencias' => FakeResponse(
      200,
      _ok({
        'pendencias': ['AREA_ATUACAO', 'ASSINATURA', 'MATERIAIS'],
      }),
    ),
    '/ofertas-coleta' => FakeResponse(
      200,
      _ok({
        ..._pagina([
          {
            'id': 'o1',
            'materiais': _materiais,
            'descricao': 'Garrafas PET limpas e caixas de papelão',
            'quantidade_estimada': 'Cerca de 30 kg em sacos grandes',
            'janela_inicio': _janelaInicio,
            'janela_fim': _janelaFim,
            'primeiro_horario': _janelaInicio,
            'bairro': 'Cidade Monções',
            'cidade_estado': 'São Paulo - SP',
            'distancia_km': 4.2,
            'anunciante_tipo': 'Fornecedor',
          },
        ]),
        'area_definida': false,
      }),
    ),
    '/ofertas-coleta/minhas' => FakeResponse(
      200,
      _ok([
        {
          'id': 'o1',
          'status': 'AGENDADA',
          'materiais': _materiais,
          'descricao': 'Garrafas PET limpas e caixas de papelão',
          'quantidade_estimada': 'Cerca de 30 kg em sacos grandes',
          'janela_inicio': _janelaInicio,
          'janela_fim': _janelaFim,
          'endereco': _endereco,
          'coleta': {
            'id': 'c1',
            'codigo': 'COL-REC-AB12CD34',
            'status': 'AGENDADA',
            'data_agendada': DateTime(2030, 1, 3, 9).toUtc().toIso8601String(),
            'cancelavel_ate': DateTime(2030, 1, 2, 9).toUtc().toIso8601String(),
            'parceiro_nome': 'Recicla Mais Reciclagem e Coleta Ltda',
            'pode_cancelar': true,
          },
        },
      ]),
    ),
    '/coletas' => FakeResponse(200, _ok(_pagina([_coleta()]))),
    '/parceiros/me' => FakeResponse(
      200,
      _ok({
        'nome': 'Recicla Mais Reciclagem e Coleta Ltda',
        'email': 'empresa-de-reciclagem@dominio-bem-comprido.com.br',
        'status': 'ATIVO',
        'responsavel_nome': 'João da Silva Sauro Pereira',
        'endereco_coleta': 'Rua das Flores, 100, Centro, São Paulo - SP',
        'capacidade_diaria_kg': 500,
        'disponivel': true,
        'materiais': _materiais,
        'area': {'definida': false},
      }),
    ),
    '/parceiros/me/area' => FakeResponse(200, _ok({'definida': false})),
    '/enderecos' => FakeResponse(
      200,
      _ok([
        {
          'id': 'e1',
          'cep': '04578000',
          ..._endereco,
          'cidade_estado': 'São Paulo/SP',
        },
      ]),
    ),
    '/chat/nao-lidas' => FakeResponse(
      200,
      _ok({'conversas': 120, 'mensagens': 340}),
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
            'contato_nome': 'Maria Aparecida de Souza Cliente',
            'contato_detalhe': 'Coleta COL-REC-AB12CD34',
            'nao_lidas': 3,
            'ultima_mensagem': {
              'texto': 'Posso retirar mais cedo, às oito da manhã?',
              'minha': false,
              'criada_em': DateTime.now().toUtc().toIso8601String(),
            },
            'ultima_atividade_em': DateTime.now().toUtc().toIso8601String(),
          },
        ]),
      ),
    ),
    '/parceiros/me/assinatura' ||
    '/cacambeiros/me/assinatura' => const FakeResponse(404, {
      'success': false,
      'message': 'Nenhuma assinatura cadastrada.',
      'code': 'SIGNATURE_NOT_FOUND',
    }),
    _ => _naoEncontrado,
  };
}

/// Abre [tela] numa tela de celular pequena, com o texto do app ampliado
/// por [tamanho]. Qualquer overflow vira exceção e reprova o teste.
Future<void> _abrirAmpliado(
  WidgetTester tester,
  Widget tela, {
  TamanhoTexto tamanho = TamanhoTexto.muitoGrande,
  String perfil = 'PARCEIRO',
  bool logado = true,
}) async {
  tester.view.physicalSize = const Size(360, 740);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage(accessToken: logado ? 'jwt' : null);
  final adapter = FakeApiAdapter((request) => _api(request, perfil: perfil));

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: tokens, adapter: adapter),
        ),
        tamanhoTextoProvider.overrideWith(() => _TamanhoFixo(tamanho)),
      ],
      child: MaterialApp(
        builder: (context, child) => Consumer(
          builder: (context, ref, _) => aplicarTamanhoTexto(
            context,
            child,
            ref.watch(tamanhoTextoProvider).fator,
          ),
        ),
        home: tela,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _TamanhoFixo extends TamanhoTextoNotifier {
  _TamanhoFixo(this.tamanho);

  final TamanhoTexto tamanho;

  @override
  TamanhoTexto build() => tamanho;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('tamanho do texto', () {
    test('começa normal e reconhece as chaves gravadas', () {
      expect(TamanhoTexto.deChave(null), TamanhoTexto.normal);
      expect(TamanhoTexto.deChave('lixo'), TamanhoTexto.normal);
      expect(TamanhoTexto.deChave('grande'), TamanhoTexto.grande);
      expect(TamanhoTexto.deChave('muito_grande'), TamanhoTexto.muitoGrande);
      expect(TamanhoTexto.values.map((t) => t.fator), [1, 1.25, 1.5]);
    });

    test('a escolha fica gravada no aparelho', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(tamanhoTextoProvider), TamanhoTexto.normal);

      await container
          .read(tamanhoTextoProvider.notifier)
          .escolher(TamanhoTexto.grande);

      expect(container.read(tamanhoTextoProvider), TamanhoTexto.grande);

      final preferencias = await SharedPreferences.getInstance();
      expect(preferencias.getString('tamanho_texto'), 'grande');
    });

    test('na abertura do app lê o que foi gravado', () async {
      SharedPreferences.setMockInitialValues({'tamanho_texto': 'muito_grande'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.listen(tamanhoTextoProvider, (_, _) {});
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(tamanhoTextoProvider), TamanhoTexto.muitoGrande);
    });

    testWidgets('soma o tamanho escolhido ao tamanho do sistema', (
      tester,
    ) async {
      late double escala;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.2)),
          child: Builder(
            builder: (context) => aplicarTamanhoTexto(
              context,
              Builder(
                builder: (context) {
                  escala = MediaQuery.textScalerOf(context).scale(10);
                  return const SizedBox();
                },
              ),
              1.5,
            ),
          ),
        ),
      );

      expect(escala, closeTo(18, 0.001));
    });

    testWidgets('o menu abre a folha e a escolha vale na hora', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tokens = InMemoryTokenStorage();

      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            tokenStorageProvider.overrideWithValue(tokens),
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                storage: tokens,
                adapter: FakeApiAdapter((_) => _naoEncontrado),
              ),
            ),
          ],
          child: const CollectApp(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Abrir menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('TAMANHO DO TEXTO'));
      await tester.pumpAndSettle();

      expect(find.text('Tamanho do texto'), findsOneWidget);
      final antes = tester.getSize(
        find.byKey(const Key('tamanho_texto_previa')),
      );

      await tester.tap(find.byKey(const Key('tamanho_texto_muito_grande')));
      await tester.pumpAndSettle();

      final depois = tester.getSize(
        find.byKey(const Key('tamanho_texto_previa')),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('tamanho_texto_previa'))),
      );

      expect(container.read(tamanhoTextoProvider), TamanhoTexto.muitoGrande);
      expect(depois.height, greaterThan(antes.height));

      final preferencias = await SharedPreferences.getInstance();
      expect(preferencias.getString('tamanho_texto'), 'muito_grande');
    });
  });

  group('telas a 150% de texto em celular pequeno', () {
    testWidgets('início', (tester) async {
      await _abrirAmpliado(tester, const HomePage(), logado: false);
    });

    testWidgets('login', (tester) async {
      await _abrirAmpliado(tester, const LoginPage(), logado: false);
    });

    testWidgets('login do admin', (tester) async {
      await _abrirAmpliado(tester, const AdminLoginPage(), logado: false);
    });

    testWidgets('cadastro do parceiro', (tester) async {
      await _abrirAmpliado(
        tester,
        const CadastroParceiroReciclagemPage(
          email: 'empresa@recicla.com',
          password: 'Senha123',
        ),
        logado: false,
      );
    });

    testWidgets('reciclagem: tela pública', (tester) async {
      await _abrirAmpliado(
        tester,
        const ReciclagemLandingPage(),
        logado: false,
      );
    });

    testWidgets('reciclagem: início do parceiro', (tester) async {
      await _abrirAmpliado(tester, const ParceiroInicioPage());
    });

    testWidgets('reciclagem: vitrine de sinalizações', (tester) async {
      await _abrirAmpliado(tester, const OfertasDisponiveisPage());
    });

    testWidgets('reciclagem: agendar coleta', (tester) async {
      await _abrirAmpliado(
        tester,
        AgendarColetaPage(
          oferta: OfertaDisponivel.fromJson({
            'id': 'o1',
            'materiais': _materiais,
            'descricao': 'Garrafas PET limpas e caixas de papelão',
            'quantidade_estimada': 'Cerca de 30 kg em sacos grandes',
            'observacoes': 'Portão azul, tocar a campainha',
            'janela_inicio': _janelaInicio,
            'janela_fim': _janelaFim,
            'primeiro_horario': _janelaInicio,
            'bairro': 'Cidade Monções',
            'cidade_estado': 'São Paulo - SP',
          }),
        ),
      );
    });

    testWidgets('reciclagem: coletas do parceiro', (tester) async {
      await _abrirAmpliado(tester, const ColetasPage());
    });

    testWidgets('reciclagem: coletas de quem entrega', (tester) async {
      await _abrirAmpliado(tester, const ColetasPage(), perfil: 'CONSUMIDOR');
    });

    testWidgets('reciclagem: minhas sinalizações', (tester) async {
      await _abrirAmpliado(
        tester,
        const MinhasSinalizacoesPage(),
        perfil: 'CONSUMIDOR',
      );
    });

    testWidgets('reciclagem: sinalizar material', (tester) async {
      await _abrirAmpliado(
        tester,
        const SinalizarReciclagemPage(),
        perfil: 'CONSUMIDOR',
      );
    });

    testWidgets('reciclagem: perfil do parceiro', (tester) async {
      await _abrirAmpliado(tester, const PerfilParceiroPage());
    });

    testWidgets('conversas', (tester) async {
      await _abrirAmpliado(tester, const ConversasPage());
    });

    testWidgets('conversa aberta', (tester) async {
      await _abrirAmpliado(
        tester,
        ChatPage(
          conversa: Conversa.fromJson({
            'id': 'cv1',
            'tipo': 'COLETA',
            'status': 'ABERTA',
            'contato_nome': 'Maria Aparecida de Souza Cliente',
            'contato_detalhe': 'Coleta COL-REC-AB12CD34',
          }),
        ),
      );
    });
  });

  group('leitores de tela', () {
    testWidgets('a bolha é lida inteira: quem, texto, hora e situação', (
      tester,
    ) async {
      final semantica = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BolhaMensagem(
                  mensagem: Mensagem.fromJson({
                    'id': 1,
                    'texto': 'Posso retirar às 9h',
                    'minha': true,
                    'lida': true,
                    'criada_em': DateTime(
                      2030,
                      1,
                      2,
                      9,
                      5,
                    ).toUtc().toIso8601String(),
                  }),
                ),
                BolhaMensagem(
                  mensagem: Mensagem.fromJson({
                    'id': 2,
                    'texto': 'Pode sim',
                    'minha': false,
                    'remetente_nome': 'Maria',
                    'criada_em': DateTime(
                      2030,
                      1,
                      2,
                      9,
                      7,
                    ).toUtc().toIso8601String(),
                  }),
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel(
          RegExp(r'^Você: Posso retirar às 9h\. .*, lida$'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(RegExp(r'^Maria: Pode sim\. ')),
        findsOneWidget,
      );

      semantica.dispose();
    });

    testWidgets('o número de não lidas é lido por extenso', (tester) async {
      final semantica = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [BolhaNaoLidas(total: 1), BolhaNaoLidas(total: 7)],
            ),
          ),
        ),
      );

      expect(find.bySemanticsLabel('1 mensagem não lida'), findsOneWidget);
      expect(find.bySemanticsLabel('7 mensagens não lidas'), findsOneWidget);

      semantica.dispose();
    });

    testWidgets('botões só com ícone têm descrição', (tester) async {
      await _abrirAmpliado(
        tester,
        const AdminLoginPage(),
        tamanho: TamanhoTexto.normal,
        logado: false,
      );

      expect(find.byTooltip('Mostrar senha'), findsOneWidget);
    });

    testWidgets('o botão do menu tem descrição e alvo de 48 px', (
      tester,
    ) async {
      await _abrirAmpliado(
        tester,
        const HomePage(),
        tamanho: TamanhoTexto.normal,
        logado: false,
      );

      final tamanho = tester.getSize(find.byTooltip('Abrir menu'));

      expect(tamanho.width, greaterThanOrEqualTo(48));
      expect(tamanho.height, greaterThanOrEqualTo(48));
    });
  });
}
