import 'dart:convert';
import 'dart:typed_data';

import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/detalhes_pedido_page.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/compartilhar_pdf.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/acompanhar_pedido_page.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/pages/agendar_entrega_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

const _naoEncontrado = FakeResponse(404, {
  'success': false,
  'message': 'não encontrado',
});

Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  Widget tela,
  FakeResponse Function(RequestOptions request) handler, {
  List<Override> overrides = const [],
}) async {
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
        ...overrides,
      ],
      child: MaterialApp(home: tela),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

/// Desenha na área de assinatura e confirma o modal.
Future<void> _assinar(WidgetTester tester) async {
  final area = find.byKey(const Key('assinatura_area'));
  final gesto = await tester.startGesture(tester.getCenter(area));

  for (var i = 0; i < 20; i++) {
    await gesto.moveBy(const Offset(6, 3));
    await tester.pump();
  }
  await gesto.up();
  await tester.pump();

  await tester.runAsync(() async {
    await tester.tap(find.byKey(const Key('assinatura_confirmar')));
    await Future<void>.delayed(const Duration(milliseconds: 500));
  });
  await tester.pumpAndSettle();
}

Map<String, dynamic> _pedido({
  String statusAluguel = 'EM_USO',
  String statusPagamento = 'PAGO',
  bool contrato = true,
  Map<String, dynamic>? extensao,
}) => {
  'success': true,
  'data': {
    'id': 'a1',
    'codigo': 'COL-ABC1234567',
    'data_pedido': '2026-10-20T10:00:00.000Z',
    'data_inicio': '2026-10-28',
    'dias_aluguel': 3,
    'preco_final': 450.5,
    'status_pagamento': statusPagamento,
    'status_aluguel': statusAluguel,
    'valores': {'subtotal_itens': 410.5, 'taxa_entrega': 40},
    'contrato': contrato ? {'disponivel': true, 'status': 'GERADO'} : null,
    'extensao': extensao,
  },
};

Map<String, dynamic> _resumo({
  bool permite = true,
  bool pode = true,
  String? motivo,
  Map<String, dynamic>? atual,
  int diasExtra = 0,
}) => {
  'permite_extensao': permite,
  'pode_estender': pode,
  'motivo_bloqueio': motivo,
  'dias_extra': diasExtra,
  'max_dias_por_extensao': 30,
  'diaria_total': 300,
  'atual': atual,
};

Map<String, dynamic> _extensao(String status) => {
  'id': 'x1',
  'aluguel_id': 'a1',
  'dias_adicionais': 4,
  'valor': 1200,
  'status': status,
  'solicitacao_expira_em': '2026-11-02T12:00:00.000Z',
  'pagamento_expira_em': '2026-11-01T12:00:00.000Z',
};

void main() {
  group('checkout com aceite dos termos e assinatura', () {
    FakeResponse handler(RequestOptions request) {
      if (request.path == '/enderecos') {
        return const FakeResponse(200, {
          'success': true,
          'data': [
            {
              'id': 'e1',
              'cep': '01001000',
              'logradouro': 'Rua das Flores',
              'numero': '123',
              'bairro': 'Centro',
              'cidade_estado': 'São Paulo/SP',
            },
          ],
        });
      }

      if (request.path == '/carrinho') {
        return const FakeResponse(200, {
          'success': true,
          'data': {
            'id': 'k1',
            'itens': [
              {
                'id': 'i1',
                'cacamba_id': 'c1',
                'quantidade': 1,
                'dias_aluguel': 5,
                'subtotal': 600,
                'cacamba': {
                  'id': 'c1',
                  'nome': 'Caçamba 5m³',
                  'tipo_residuo': 'Entulho',
                  'tamanho_m3': 5,
                  'preco_diaria': 120,
                },
              },
            ],
            'resumo': {
              'quantidade_itens': 1,
              'subtotal': 600,
              'taxa_entrega': 40,
              'total_estimado': 640,
            },
          },
        });
      }

      if (request.method == 'POST' && request.path == '/alugueis/checkout') {
        return const FakeResponse(201, {
          'success': true,
          'data': {
            'id': 'p1',
            'preco_final': '640.00',
            'status_aluguel': 'AGUARDANDO_ENTREGA',
            'status_pagamento': 'PENDENTE',
            'contrato_disponivel': true,
          },
        });
      }

      return _naoEncontrado;
    }

    ElevatedButton botaoConfirmar(WidgetTester tester) =>
        tester.widget<ElevatedButton>(find.byKey(const Key('confirmar_pedido')));

    Future<void> escolherData(WidgetTester tester) async {
      final amanha = DateTime.now().add(const Duration(days: 1));

      await tester.tap(
        find.descendant(
          of: find.byType(GridView),
          matching: find.text('${amanha.day}'),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('o pedido só é liberado depois de aceitar e assinar', (
      tester,
    ) async {
      await _abrir(tester, const AgendarEntregaPage(), handler);

      await escolherData(tester);

      // Endereço, carrinho e data prontos, mas sem assinatura.
      expect(botaoConfirmar(tester).onPressed, isNull);

      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pumpAndSettle();

      // Cancelar a assinatura mantém o pedido bloqueado.
      await tester.tap(find.byKey(const Key('assinatura_cancelar')));
      await tester.pumpAndSettle();
      expect(botaoConfirmar(tester).onPressed, isNull);

      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pumpAndSettle();
      await _assinar(tester);

      expect(find.byKey(const Key('aceite_termos_previa')), findsOneWidget);
      expect(botaoConfirmar(tester).onPressed, isNotNull);

      // Desmarcar apaga a assinatura e bloqueia de novo.
      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('aceite_termos_previa')), findsNothing);
      expect(botaoConfirmar(tester).onPressed, isNull);
    });

    testWidgets('envia o aceite e a assinatura PNG junto com o pedido', (
      tester,
    ) async {
      final adapter = await _abrir(tester, const AgendarEntregaPage(), handler);

      await escolherData(tester);
      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pumpAndSettle();
      await _assinar(tester);

      await tester.ensureVisible(find.byKey(const Key('confirmar_pedido')));
      await tester.tap(find.byKey(const Key('confirmar_pedido')));
      await tester.pumpAndSettle();

      final post = adapter.requests.singleWhere(
        (r) => r.method == 'POST' && r.path == '/alugueis/checkout',
      );
      final corpo = sentBody(post);

      expect(corpo['endereco_id'], 'e1');
      expect(corpo['aceite_termos'], true);

      final assinatura = corpo['assinatura_base64'] as String;
      expect(assinatura, startsWith('data:image/png;base64,'));

      final png = base64Decode(assinatura.split(',').last);
      expect(png.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);

      final dados = ByteData.sublistView(Uint8List.fromList(png));
      expect(dados.getUint32(16), 900);
      expect(dados.getUint32(20), 300);
    });

    testWidgets('sem a data, mesmo assinado, avisa e não envia', (
      tester,
    ) async {
      final adapter = await _abrir(tester, const AgendarEntregaPage(), handler);

      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pumpAndSettle();
      await _assinar(tester);

      await tester.ensureVisible(find.byKey(const Key('confirmar_pedido')));
      await tester.tap(find.byKey(const Key('confirmar_pedido')));
      await tester.pumpAndSettle();

      expect(
        find.text('Escolha a data de início da locação.'),
        findsOneWidget,
      );
      expect(
        adapter.requests.where((r) => r.path == '/alugueis/checkout'),
        isEmpty,
      );
    });
  });

  group('acompanhar pedido: contrato e extensão', () {
    testWidgets('baixa o contrato e entrega o PDF para compartilhar', (
      tester,
    ) async {
      Uint8List? recebido;
      String? nome;

      final adapter = await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (request) => request.path == '/alugueis/a1/contrato'
            ? const FakeResponse(200, {'pdf': 'simulado'})
            : FakeResponse(200, _pedido()),
        overrides: [
          compartilharPdfProvider.overrideWithValue((bytes, arquivo) async {
            recebido = bytes;
            nome = arquivo;
          }),
        ],
      );

      await tester.tap(find.byKey(const Key('baixar_contrato')));
      await tester.pumpAndSettle();

      expect(adapter.paths, contains('GET /alugueis/a1/contrato'));
      expect(recebido, isNotEmpty);
      expect(nome, 'contrato-COL-ABC1234567.pdf');
    });

    testWidgets('mostra a mensagem da API quando o contrato não existe', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (request) => request.path == '/alugueis/a1/contrato'
            ? const FakeResponse(404, {
                'success': false,
                'message': 'Este pedido não possui contrato.',
                'code': 'CONTRACT_NOT_FOUND',
              })
            : FakeResponse(200, _pedido()),
        overrides: [
          compartilharPdfProvider.overrideWithValue((_, _) async {}),
        ],
      );

      await tester.tap(find.byKey(const Key('baixar_contrato')));
      await tester.pumpAndSettle();

      expect(find.text('Este pedido não possui contrato.'), findsOneWidget);
    });

    testWidgets('pedido antigo não mostra contrato nem extensão', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (_) => FakeResponse(200, _pedido(contrato: false)),
      );

      expect(find.byKey(const Key('baixar_contrato')), findsNothing);
      expect(find.byKey(const Key('estender_aluguel')), findsNothing);
      expect(find.text('Estender aluguel'), findsNothing);
    });

    testWidgets('caçamba sem permissão de extensão não oferece o botão', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (_) => FakeResponse(
          200,
          _pedido(
            extensao: _resumo(
              permite: false,
              pode: false,
              motivo: 'EXTENSION_NOT_ALLOWED',
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('estender_aluguel')), findsNothing);
      expect(find.text('Estender aluguel'), findsNothing);
    });

    testWidgets('escolhe os dias, vê o valor e envia o pedido', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (request) {
          if (request.method == 'POST' &&
              request.path == '/alugueis/a1/extensoes') {
            return FakeResponse(201, {
              'success': true,
              'data': _extensao('SOLICITADA'),
            });
          }
          return FakeResponse(200, _pedido(extensao: _resumo()));
        },
      );

      await tester.tap(find.byKey(const Key('estender_aluguel')));
      await tester.pumpAndSettle();

      // 1 dia = R$ 300,00 (soma das diárias dos itens).
      expect(find.text('Valor da extensão: R\$ 300,00'), findsOneWidget);

      await tester.tap(find.byKey(const Key('extensao_mais')));
      await tester.tap(find.byKey(const Key('extensao_mais')));
      await tester.pumpAndSettle();

      expect(find.text('Valor da extensão: R\$ 900,00'), findsOneWidget);
      expect(
        tester.widget<Text>(find.byKey(const Key('extensao_dias'))).data,
        '3 dias',
      );

      await tester.tap(find.byKey(const Key('extensao_enviar')));
      await tester.pumpAndSettle();

      final post = adapter.requests.singleWhere(
        (r) => r.method == 'POST' && r.path == '/alugueis/a1/extensoes',
      );
      expect(sentBody(post), {'dias_adicionais': 3});
      expect(
        find.textContaining('Pedido enviado ao fornecedor'),
        findsOneWidget,
      );
    });

    testWidgets('cancelar a escolha de dias não envia nada', (tester) async {
      final adapter = await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (_) => FakeResponse(200, _pedido(extensao: _resumo())),
      );

      await tester.tap(find.byKey(const Key('estender_aluguel')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'POST'), isEmpty);
    });

    testWidgets('mostra o motivo quando a API recusa o pedido', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (request) => request.method == 'POST'
            ? const FakeResponse(409, {
                'success': false,
                'message':
                    'Já existe um pedido de extensão em andamento para este aluguel.',
                'code': 'EXTENSION_ALREADY_OPEN',
              })
            : FakeResponse(200, _pedido(extensao: _resumo())),
      );

      await tester.tap(find.byKey(const Key('estender_aluguel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('extensao_enviar')));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Já existe um pedido de extensão'),
        findsOneWidget,
      );
    });

    testWidgets('aguardando o fornecedor: mostra o estado e some o botão', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (_) => FakeResponse(
          200,
          _pedido(
            extensao: _resumo(
              pode: false,
              motivo: 'EXTENSION_ALREADY_OPEN',
              atual: _extensao('SOLICITADA'),
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('extensao_solicitada')), findsOneWidget);
      expect(find.byKey(const Key('estender_aluguel')), findsNothing);
    });

    testWidgets('aceita pelo fornecedor: oferece pagar e abre o PIX da extensão', (
      tester,
    ) async {
      final adapter = await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (request) {
          if (request.path == '/alugueis/a1/extensoes/x1/pix') {
            return const FakeResponse(201, {
              'success': true,
              'data': {
                'id': 'pix-9',
                'aluguel_id': 'a1',
                'extensao_id': 'x1',
                'status': 'PENDING',
                'status_pagamento': 'PENDENTE',
                'valor': 1200,
                'copia_cola': '000201EXTENSAO',
                'dev_mode': false,
              },
            });
          }
          return FakeResponse(
            200,
            _pedido(
              extensao: _resumo(
                pode: false,
                motivo: 'EXTENSION_ALREADY_OPEN',
                atual: _extensao('AGUARDANDO_PAGAMENTO'),
              ),
            ),
          );
        },
      );

      expect(
        find.byKey(const Key('extensao_aguardando_pagamento')),
        findsOneWidget,
      );
      expect(find.textContaining('R\$ 1.200,00'), findsWidgets);

      await tester.tap(find.byKey(const Key('pagar_extensao')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(adapter.paths, contains('POST /alugueis/a1/extensoes/x1/pix'));
      expect(find.text('Pagamento da extensão'), findsOneWidget);
      expect(find.text('000201EXTENSAO'), findsOneWidget);
    });

    testWidgets('extensão recusada ou expirada permite pedir de novo', (
      tester,
    ) async {
      await _abrir(
        tester,
        const AcompanharPedidoPage(aluguelId: 'a1'),
        (_) => FakeResponse(
          200,
          _pedido(extensao: _resumo(atual: _extensao('RECUSADA'))),
        ),
      );

      expect(find.byKey(const Key('extensao_ultimo')), findsOneWidget);
      expect(find.textContaining('Recusada pelo fornecedor'), findsOneWidget);
      expect(find.byKey(const Key('estender_aluguel')), findsOneWidget);
    });
  });

  group('detalhe do pedido do fornecedor: responder à extensão', () {
    FakeResponse Function(RequestOptions) api({
      required String statusExtensao,
      FakeResponse? patch,
    }) {
      return (request) {
        if (request.method == 'PATCH' &&
            request.path == '/alugueis/a1/extensoes/x1') {
          return patch ??
              FakeResponse(200, {
                'success': true,
                'data': _extensao('AGUARDANDO_PAGAMENTO'),
              });
        }
        if (request.path == '/alugueis/a1') {
          return FakeResponse(
            200,
            _pedido(
              extensao: _resumo(
                pode: false,
                atual: _extensao(statusExtensao),
              ),
            ),
          );
        }
        return _naoEncontrado;
      };
    }

    testWidgets('aceita depois de confirmar', (tester) async {
      final adapter = await _abrir(
        tester,
        const DetalhesPedidoPage(aluguelId: 'a1'),
        api(statusExtensao: 'SOLICITADA'),
      );

      expect(find.byKey(const Key('extensao_aceitar')), findsOneWidget);

      await tester.ensureVisible(find.byKey(const Key('extensao_aceitar')));
      await tester.tap(find.byKey(const Key('extensao_aceitar')));
      await tester.pumpAndSettle();

      // Nada foi enviado antes da confirmação.
      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);

      await tester.tap(find.byKey(const Key('extensao_confirmar')));
      await tester.pumpAndSettle();

      final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(sentBody(patch), {'acao': 'ACEITAR'});
      expect(
        find.textContaining('O cliente tem 24 horas para pagar'),
        findsOneWidget,
      );
    });

    testWidgets('recusa depois de confirmar', (tester) async {
      final adapter = await _abrir(
        tester,
        const DetalhesPedidoPage(aluguelId: 'a1'),
        api(statusExtensao: 'SOLICITADA'),
      );

      await tester.ensureVisible(find.byKey(const Key('extensao_recusar')));
      await tester.tap(find.byKey(const Key('extensao_recusar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('extensao_confirmar')));
      await tester.pumpAndSettle();

      final patch = adapter.requests.singleWhere((r) => r.method == 'PATCH');
      expect(sentBody(patch), {'acao': 'RECUSAR'});
    });

    testWidgets('voltar na confirmação não envia nada', (tester) async {
      final adapter = await _abrir(
        tester,
        const DetalhesPedidoPage(aluguelId: 'a1'),
        api(statusExtensao: 'SOLICITADA'),
      );

      await tester.ensureVisible(find.byKey(const Key('extensao_aceitar')));
      await tester.tap(find.byKey(const Key('extensao_aceitar')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Voltar'),
        ),
      );
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'PATCH'), isEmpty);
    });

    testWidgets('já respondida não mostra os botões', (tester) async {
      await _abrir(
        tester,
        const DetalhesPedidoPage(aluguelId: 'a1'),
        api(statusExtensao: 'AGUARDANDO_PAGAMENTO'),
      );

      expect(find.byKey(const Key('extensao_aceitar')), findsNothing);
      expect(find.byKey(const Key('extensao_recusar')), findsNothing);
      expect(find.byKey(const Key('extensao_situacao')), findsOneWidget);
    });

    testWidgets('prazo vencido: mostra o erro da API e recarrega', (
      tester,
    ) async {
      await _abrir(
        tester,
        const DetalhesPedidoPage(aluguelId: 'a1'),
        api(
          statusExtensao: 'SOLICITADA',
          patch: const FakeResponse(410, {
            'success': false,
            'message': 'O prazo para responder a este pedido terminou.',
            'code': 'EXTENSION_EXPIRED',
          }),
        ),
      );

      await tester.ensureVisible(find.byKey(const Key('extensao_aceitar')));
      await tester.tap(find.byKey(const Key('extensao_aceitar')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('extensao_confirmar')));
      await tester.pumpAndSettle();

      expect(
        find.text('O prazo para responder a este pedido terminou.'),
        findsOneWidget,
      );
    });

    testWidgets('o fornecedor também baixa o contrato', (tester) async {
      String? nome;

      await _abrir(
        tester,
        const DetalhesPedidoPage(aluguelId: 'a1'),
        (request) => request.path == '/alugueis/a1/contrato'
            ? const FakeResponse(200, {'pdf': 'simulado'})
            : api(statusExtensao: 'PAGA')(request),
        overrides: [
          compartilharPdfProvider.overrideWithValue((_, arquivo) async {
            nome = arquivo;
          }),
        ],
      );

      await tester.ensureVisible(find.byKey(const Key('baixar_contrato')));
      await tester.tap(find.byKey(const Key('baixar_contrato')));
      await tester.pumpAndSettle();

      expect(nome, 'contrato-COL-ABC1234567.pdf');
    });
  });
}
