import 'package:app_collect_express_with_flutter/core/models/cacamba.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/cadastrar_cacamba_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/gestao_usuarios_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/minhas_cacambas_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/widgets/foto_cacamba_picker.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/cadastro_fornecedor_page.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

// Fluxo do fornecedor: cadastro → aprovação pelo admin → cadastro de caçamba.

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  FakeResponse Function(RequestOptions request) handler, {
  InMemoryTokenStorage? storage,
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

Finder _campo(String hint) => find.widgetWithText(TextFormField, hint);

const _naoEncontrado = FakeResponse(404, {
  'success': false,
  'message': 'não encontrado',
});

void main() {
  group('cadastro do fornecedor', () {
    Future<void> preencher(WidgetTester tester) async {
      await tester.enterText(
        _campo('Nome que aparece para os clientes'),
        'Caçambas Teste',
      );
      await tester.enterText(_campo('00.000.000/0001-00'), '12345678000199');
      await tester.enterText(
        _campo('Confirme o e-mail da empresa'),
        'empresa@teste.com',
      );
      await tester.enterText(_campo('Confirme sua senha'), 'Senha123');
      await tester.enterText(_campo('(11) 99999-9999'), '11988887777');
      await tester.enterText(_campo('0,00'), '50,00');

      // Abre às 08:00 (padrão do relógio) e fecha às 20:00 (8 PM).
      await tester.tap(_campo('07:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(_campo('18:00'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    const tela = CadastroFornecedorPage(
      email: 'empresa@teste.com',
      password: 'Senha123',
    );

    testWidgets('envia os dados para a API e avisa que está em análise', (
      tester,
    ) async {
      final adapter = await _abrir(tester, tela, (request) {
        if (request.path == '/auth/register') {
          return const FakeResponse(201, {
            'success': true,
            'data': {
              'id': 'f1',
              'nome_completo': 'Caçambas Teste',
              'email': 'empresa@teste.com',
              'tipo_perfil': 'CACAMBEIRO',
              'status': 'PENDENTE',
            },
          });
        }
        return _naoEncontrado;
      });

      await preencher(tester);
      await tester.tap(find.text('CADASTRAR-SE'));
      await tester.pumpAndSettle();

      expect(adapter.paths, ['POST /auth/register']);
      expect(sentBody(adapter.requests.single), {
        'nome_completo': 'Caçambas Teste',
        'email': 'empresa@teste.com',
        'senha': 'Senha123',
        'tipo_perfil': 'CACAMBEIRO',
        'documento': '12345678000199',
        'telefone': '11988887777',
        'horario_inicio': '08:00',
        'horario_fim': '20:00',
        'taxa_entrega': 50,
      });

      expect(find.text('Raio de Entrega (km)'), findsNothing);
      expect(find.text('Cadastro enviado!'), findsOneWidget);
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('tela de login'), findsOneWidget);
    });

    testWidgets('mostra no campo o erro que a API devolveu', (tester) async {
      await _abrir(tester, tela, (request) {
        return const FakeResponse(409, {
          'success': false,
          'message': 'E-mail já cadastrado.',
          'code': 'EMAIL_ALREADY_EXISTS',
          'fields': {'email': 'Este e-mail já está em uso.'},
        });
      });

      await preencher(tester);
      await tester.tap(find.text('CADASTRAR-SE'));
      await tester.pumpAndSettle();

      expect(find.text('Este e-mail já está em uso.'), findsOneWidget);
      expect(find.text('E-mail já cadastrado.'), findsOneWidget);
      expect(find.text('Cadastro enviado!'), findsNothing);
    });
  });

  group('gestão de usuários', () {
    Map<String, dynamic> usuario(
      String id,
      String nome,
      String tipo,
      String status,
    ) => {
      'id': id,
      'nome_completo': nome,
      'email': '$id@teste.com',
      'tipo_perfil': tipo,
      'status': status,
      'telefone': '11988887777',
      'criado_em': '2026-10-27T12:00:00.000Z',
    };

    // Formato de GET /usuarios: lista em `data` e paginação fora dela.
    Map<String, dynamic> lista(List<Map<String, dynamic>> itens) => {
      'success': true,
      'data': itens,
      'total': itens.length,
      'page': 1,
      'totalPages': 1,
      'pagination': {
        'total': itens.length,
        'page': 1,
        'limit': 20,
        'totalPages': 1,
      },
    };

    testWidgets('lista os usuários da API e aprova um fornecedor pendente', (
      tester,
    ) async {
      var statusFornecedor = 'PENDENTE';

      final adapter = await _abrir(tester, const GestaoUsuariosPage(), (
        request,
      ) {
        if (request.path == '/usuarios/perfil') {
          return FakeResponse(200, {
            'success': true,
            'data': usuario('admin1', 'Admin Geral', 'ADMIN', 'ATIVO'),
          });
        }
        if (request.path == '/usuarios/f1/status') {
          statusFornecedor = sentBody(request)['status'] as String;
          return FakeResponse(200, {
            'success': true,
            'data': usuario(
              'f1',
              'Entulho Novo',
              'CACAMBEIRO',
              statusFornecedor,
            ),
          });
        }
        if (request.path == '/usuarios') {
          final fornecedor = usuario(
            'f1',
            'Entulho Novo',
            'CACAMBEIRO',
            statusFornecedor,
          );
          final todos = [
            fornecedor,
            usuario('c1', 'Maria Cliente', 'CONSUMIDOR', 'ATIVO'),
          ];
          final status = request.queryParameters['status'];
          return FakeResponse(
            200,
            lista([
              for (final u in todos)
                if (status == null || u['status'] == status) u,
            ]),
          );
        }
        return _naoEncontrado;
      }, storage: InMemoryTokenStorage(accessToken: 'jwt'));

      expect(find.text('Entulho Novo'), findsOneWidget);
      expect(find.text('Maria Cliente'), findsOneWidget);
      expect(find.text('Fornecedor'), findsOneWidget);
      expect(find.text('Pendente'), findsOneWidget);
      expect(find.text('1 cadastro aguardando aprovação'), findsOneWidget);
      expect(find.text('Pendentes (1)'), findsOneWidget);

      await tester.tap(find.text('Entulho Novo'));
      await tester.pumpAndSettle();
      expect(find.text('Recusar cadastro'), findsOneWidget);

      await tester.tap(find.text('Aprovar cadastro'));
      await tester.pumpAndSettle();

      final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.path, '/usuarios/f1/status');
      expect(sentBody(patch), {'status': 'ATIVO'});
      expect(
        find.text('Cadastro aprovado. O fornecedor já pode entrar no app.'),
        findsOneWidget,
      );

      // A lista recarrega com o novo status.
      expect(find.text('Pendente'), findsNothing);
      expect(find.text('1 cadastro aguardando aprovação'), findsNothing);
    });

    testWidgets('não oferece mudar o status de administradores', (
      tester,
    ) async {
      final adapter = await _abrir(tester, const GestaoUsuariosPage(), (
        request,
      ) {
        if (request.path == '/usuarios') {
          return FakeResponse(
            200,
            lista([usuario('a2', 'Outro Admin', 'ADMIN', 'ATIVO')]),
          );
        }
        return _naoEncontrado;
      }, storage: InMemoryTokenStorage(accessToken: 'jwt'));

      await tester.tap(find.text('Outro Admin'));
      await tester.pumpAndSettle();

      expect(
        find.text('O status de administradores não pode ser alterado.'),
        findsOneWidget,
      );
      expect(find.text('Suspender usuário'), findsNothing);
      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
    });
  });

  group('cadastro de caçamba', () {
    const entulho = {
      'id': 'c1',
      'nome': 'Caçamba 5m³',
      'tipo_residuo': 'Entulho de Obra',
      'tamanho_m3': 5,
      'preco_diaria': 150,
      'disponivel': true,
    };
    final madeira = <String, dynamic>{
      ...entulho,
      'id': 'c2',
      'tipo_residuo': 'Madeira',
    };

    Future<void> abrirCadastro(WidgetTester tester) async {
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
    }

    /// Tela que abre o cadastro e entrega o resultado em [aoFechar].
    Widget abridor(void Function(bool?) aoFechar) {
      return Builder(
        builder: (context) {
          return Scaffold(
            body: TextButton(
              onPressed: () async {
                aoFechar(
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const CadastrarCacambaPage(),
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          );
        },
      );
    }

    FakeResponse Function(RequestOptions) api({required FakeResponse post}) {
      return (request) {
        if (request.method == 'POST' && request.path == '/cacambas') {
          return post;
        }
        if (request.path == '/cacambas/minhas') {
          return FakeResponse(200, {
            'success': true,
            'data': [madeira],
          });
        }
        if (request.path == '/cacambas') {
          return const FakeResponse(200, {
            'success': true,
            'data': {
              'items': [entulho],
              'pagination': {
                'total': 1,
                'page': 1,
                'per_page': 20,
                'total_pages': 1,
              },
            },
          });
        }
        return _naoEncontrado;
      };
    }

    testWidgets('sugere as categorias conhecidas e envia para a API', (
      tester,
    ) async {
      bool? resultado;
      final adapter = await _abrir(
        tester,
        abridor((value) => resultado = value),
        api(
          post: FakeResponse(201, {
            'success': true,
            'data': {...madeira, 'id': 'nova'},
          }),
        ),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );
      await abrirCadastro(tester);

      expect(find.widgetWithText(ChoiceChip, 'Entulho de Obra'), findsOne);
      expect(find.widgetWithText(ChoiceChip, 'Madeira'), findsOne);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Madeira'));
      await tester.tap(find.text('7m³'));
      await tester.enterText(_campo('0,00'), '180,50');
      await tester.tap(find.text('Publicar Caçamba'));
      await tester.pumpAndSettle();

      final post = adapter.requests.singleWhere((r) => r.method == 'POST');
      expect(sentBody(post), {
        'nome': 'Caçamba 7m³ - Madeira',
        'tipo_residuo': 'Madeira',
        'tamanho_m3': 7,
        'preco_diaria': 180.5,
        'permite_extensao': false,
      });
      expect(resultado, isTrue);
      expect(find.byType(CadastrarCacambaPage), findsNothing);
    });

    testWidgets('envia a foto escolhida em base64 e a opção de extensão', (
      tester,
    ) async {
      final foto = FotoSelecionada(
        Uint8List.fromList(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==')),
        'image/png',
      );

      final adapter = await _abrir(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      CadastrarCacambaPage(escolherFoto: () async => foto),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        api(
          post: FakeResponse(201, {
            'success': true,
            'data': {...madeira, 'id': 'nova'},
          }),
        ),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );
      await abrirCadastro(tester);

      expect(find.byKey(const Key('foto_cacamba_previa')), findsNothing);

      await tester.tap(find.byKey(const Key('foto_cacamba_escolher')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('foto_cacamba_previa')), findsOneWidget);
      expect(find.text('Trocar foto'), findsOneWidget);

      await tester.tap(find.byKey(const Key('permite_extensao_switch')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Madeira'));
      await tester.enterText(_campo('0,00'), '99');
      await tester.tap(find.text('Publicar Caçamba'));
      await tester.pumpAndSettle();

      final corpo = sentBody(
        adapter.requests.singleWhere((r) => r.method == 'POST'),
      );
      expect(corpo['foto_base64'], foto.dataUri);
      expect(corpo['foto_base64'], startsWith('data:image/png;base64,'));
      expect(corpo['permite_extensao'], true);
      expect(corpo.containsKey('foto_url'), isFalse);
    });

    testWidgets('remover a foto escolhida volta para a imagem padrão', (
      tester,
    ) async {
      final foto = FotoSelecionada(
        Uint8List.fromList(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==')),
        'image/png',
      );

      await _abrir(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) =>
                      CadastrarCacambaPage(escolherFoto: () async => foto),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        api(post: _naoEncontrado),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );
      await abrirCadastro(tester);

      await tester.tap(find.byKey(const Key('foto_cacamba_escolher')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('foto_cacamba_previa')), findsOneWidget);

      await tester.tap(find.byKey(const Key('foto_cacamba_remover')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('foto_cacamba_previa')), findsNothing);
      expect(find.text('Escolher foto'), findsOneWidget);
    });

    testWidgets('mostra o aviso quando a foto não serve', (tester) async {
      await _abrir(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => CadastrarCacambaPage(
                    escolherFoto: () async =>
                        throw const FotoInvalidaException('Foto grande demais.'),
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
        api(post: _naoEncontrado),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );
      await abrirCadastro(tester);

      await tester.tap(find.byKey(const Key('foto_cacamba_escolher')));
      await tester.pumpAndSettle();

      expect(find.text('Foto grande demais.'), findsOneWidget);
      expect(find.byKey(const Key('foto_cacamba_previa')), findsNothing);
    });

    testWidgets('mostra no campo a categoria recusada pela API', (
      tester,
    ) async {
      await _abrir(
        tester,
        abridor((_) {}),
        api(
          post: const FakeResponse(400, {
            'success': false,
            'message': 'A categoria informada não existe.',
            'code': 'CATEGORY_NOT_FOUND',
            'fields': {'tipo_residuo': 'Selecione uma categoria cadastrada.'},
          }),
        ),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );
      await abrirCadastro(tester);

      await tester.enterText(
        _campo('Categoria cadastrada pelo administrador'),
        'Vidro',
      );
      await tester.enterText(_campo('0,00'), '100');
      await tester.tap(find.text('Publicar Caçamba'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione uma categoria cadastrada.'), findsOneWidget);
      expect(find.byType(CadastrarCacambaPage), findsOneWidget);
    });
  });

  group('edição de caçamba', () {
    final original = Cacamba.fromJson(const {
      'id': 'c1',
      'nome': 'Caçamba 5m³ - Entulho de Obra',
      'tipo_residuo': 'Entulho de Obra',
      'tamanho_m3': 5,
      'preco_diaria': '150.00',
      'foto_url': 'https://api.teste.com/uploads/cacambas/antiga.png',
      'disponivel': true,
      'permite_extensao': false,
    });

    final pngReal = Uint8List.fromList(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      ),
    );

    FakeResponse Function(RequestOptions) api({FakeResponse? put}) {
      return (request) {
        if (request.method == 'PUT' && request.path == '/cacambas/c1') {
          return put ??
              const FakeResponse(200, {
                'success': true,
                'data': {'id': 'c1', 'nome': 'Caçamba'},
              });
        }
        if (request.path == '/cacambas/minhas') {
          return const FakeResponse(200, {'success': true, 'data': []});
        }
        if (request.path == '/cacambas') {
          return const FakeResponse(200, {
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
          });
        }
        return _naoEncontrado;
      };
    }

    Future<({FakeApiAdapter adapter, List<bool?> fechou})> abrirEdicao(
      WidgetTester tester, {
      Cacamba? cacamba,
      FakeResponse? put,
      Future<FotoSelecionada?> Function()? escolherFoto,
    }) async {
      final fechou = <bool?>[];

      final adapter = await _abrir(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                fechou.add(
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => CadastrarCacambaPage(
                        cacamba: cacamba ?? original,
                        escolherFoto: escolherFoto ?? escolherFotoDaGaleria,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
        api(put: put),
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();

      return (adapter: adapter, fechou: fechou);
    }

    Map<String, dynamic> corpoDoPut(FakeApiAdapter adapter) =>
        sentBody(adapter.requests.singleWhere((r) => r.method == 'PUT'));

    testWidgets('abre com os dados da caçamba preenchidos', (tester) async {
      await abrirEdicao(tester);

      expect(find.text('Editar Caçamba'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);
      expect(find.text('Publicar Caçamba'), findsNothing);

      expect(find.widgetWithText(TextFormField, 'Entulho de Obra'), findsOne);
      expect(find.widgetWithText(TextFormField, '150,00'), findsOne);
      expect(
        tester
            .widget<SwitchListTile>(find.byKey(const Key('permite_extensao_switch')))
            .value,
        isFalse,
      );

      // Há foto salva, então dá para removê-la.
      expect(
        find.byKey(const Key('foto_cacamba_remover_atual')),
        findsOneWidget,
      );
    });

    testWidgets('mudar só o preço envia só o preço', (tester) async {
      final tela = await abrirEdicao(tester);

      await tester.enterText(find.widgetWithText(TextFormField, '150,00'), '99,90');
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(corpoDoPut(tela.adapter), {'preco_diaria': 99.9});
      expect(tela.fechou, [true]);
    });

    testWidgets('mudar o volume atualiza também o nome', (tester) async {
      final tela = await abrirEdicao(tester);

      await tester.tap(find.text('7m³'));
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(corpoDoPut(tela.adapter), {
        'nome': 'Caçamba 7m³ - Entulho de Obra',
        'tamanho_m3': 7,
      });
    });

    testWidgets('ligar a extensão envia só permite_extensao', (tester) async {
      final tela = await abrirEdicao(tester);

      await tester.tap(find.byKey(const Key('permite_extensao_switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(corpoDoPut(tela.adapter), {'permite_extensao': true});
    });

    testWidgets('trocar a foto envia a nova em base64', (tester) async {
      final foto = FotoSelecionada(pngReal, 'image/png');
      final tela = await abrirEdicao(tester, escolherFoto: () async => foto);

      await tester.tap(find.byKey(const Key('foto_cacamba_escolher')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(corpoDoPut(tela.adapter), {'foto_base64': foto.dataUri});
    });

    testWidgets('remover a foto atual manda foto_url nulo', (tester) async {
      final tela = await abrirEdicao(tester);

      await tester.tap(find.byKey(const Key('foto_cacamba_remover_atual')));
      await tester.pumpAndSettle();

      // O botão some e a imagem padrão volta.
      expect(find.byKey(const Key('foto_cacamba_remover_atual')), findsNothing);

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(corpoDoPut(tela.adapter), {'foto_url': null});
    });

    testWidgets('sem alterações, avisa e não chama a API', (tester) async {
      final tela = await abrirEdicao(tester);

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(find.text('Nenhuma alteração para salvar.'), findsOneWidget);
      expect(tela.adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      expect(tela.fechou, isEmpty);
      expect(find.byType(CadastrarCacambaPage), findsOneWidget);
    });

    testWidgets('volume fora do padrão aparece como opção', (tester) async {
      await abrirEdicao(
        tester,
        cacamba: Cacamba.fromJson(const {
          'id': 'c1',
          'nome': 'Caçamba 4m³',
          'tipo_residuo': 'Entulho de Obra',
          'tamanho_m3': 4,
          'preco_diaria': 100,
        }),
      );

      expect(find.text('4m³'), findsOneWidget);
      expect(find.text('3m³'), findsOneWidget);
      expect(find.text('7m³'), findsOneWidget);
    });

    testWidgets('mostra no campo o erro que a API devolveu', (tester) async {
      await abrirEdicao(
        tester,
        put: const FakeResponse(400, {
          'success': false,
          'message': 'A categoria informada não existe.',
          'code': 'CATEGORY_NOT_FOUND',
          'fields': {'tipo_residuo': 'Selecione uma categoria cadastrada.'},
        }),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Entulho de Obra'),
        'Vidro',
      );
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(find.text('Selecione uma categoria cadastrada.'), findsOneWidget);
      expect(find.byType(CadastrarCacambaPage), findsOneWidget);
    });

    testWidgets('na lista, o menu Editar abre a edição e atualiza a lista', (
      tester,
    ) async {
      var listagens = 0;

      final adapter = await _abrir(
        tester,
        const MinhasCacambasPage(),
        (request) {
          if (request.method == 'PUT' && request.path == '/cacambas/c1') {
            return const FakeResponse(200, {
              'success': true,
              'data': {'id': 'c1', 'nome': 'Caçamba'},
            });
          }
          if (request.path == '/cacambas/minhas') {
            listagens++;
            return const FakeResponse(200, {
              'success': true,
              'data': [
                {
                  'id': 'c1',
                  'nome': 'Caçamba 5m³ - Entulho de Obra',
                  'tipo_residuo': 'Entulho de Obra',
                  'tamanho_m3': 5,
                  'preco_diaria': '150.00',
                  'disponivel': true,
                  'permite_extensao': false,
                },
              ],
            });
          }
          return api()(request);
        },
        storage: InMemoryTokenStorage(accessToken: 'jwt'),
      );

      await tester.tap(find.byTooltip('Opções'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Caçamba'), findsOneWidget);

      // A própria tela de edição também consulta as caçambas (sugestões).
      final antesDeSalvar = listagens;

      await tester.enterText(find.widgetWithText(TextFormField, '150,00'), '200');
      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(sentBody(adapter.requests.singleWhere((r) => r.method == 'PUT')), {
        'preco_diaria': 200,
      });
      expect(find.text('Caçamba atualizada.'), findsOneWidget);
      expect(
        listagens,
        greaterThan(antesDeSalvar),
        reason: 'a lista é recarregada depois de salvar',
      );
    });
  });
}