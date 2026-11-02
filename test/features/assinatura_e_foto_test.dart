import 'dart:convert';
import 'dart:typed_data';

import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/core/widgets/signature_pad_dialog.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/widgets/assinatura_empresa_card.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/widgets/foto_cacamba_picker.dart';
import 'package:app_collect_express_with_flutter/features/pedidos/presentation/widgets/aceite_termos_card.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

/// Cabeçalho mínimo de PNG com a largura e a altura informadas.
Uint8List pngComTamanho(int largura, int altura, {int extra = 0}) {
  final bytes = Uint8List(33 + extra);
  bytes.setAll(0, [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
  final dados = ByteData.sublistView(bytes);
  dados.setUint32(8, 13);
  bytes.setAll(12, ascii.encode('IHDR'));
  dados.setUint32(16, largura);
  dados.setUint32(20, altura);
  return bytes;
}

void main() {
  group('formato e tamanho da foto da caçamba', () {
    test('reconhece JPEG, PNG e WebP pelos bytes, não pela extensão', () {
      expect(
        detectarMimeDaImagem(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0])),
        'image/jpeg',
      );
      expect(detectarMimeDaImagem(pngComTamanho(10, 10)), 'image/png');

      final webp = Uint8List(16)
        ..setAll(0, ascii.encode('RIFF'))
        ..setAll(8, ascii.encode('WEBP'));
      expect(detectarMimeDaImagem(webp), 'image/webp');

      expect(detectarMimeDaImagem(ascii.encode('GIF89a......')), isNull);
      expect(detectarMimeDaImagem(Uint8List(0)), isNull);
    });

    test('valida e monta o data URI', () {
      final foto = validarFoto(pngComTamanho(800, 600));

      expect(foto.mime, 'image/png');
      expect(foto.dataUri, startsWith('data:image/png;base64,'));
    });

    test('recusa formato desconhecido e arquivo grande demais', () {
      expect(
        () => validarFoto(utf8.encode('não sou uma imagem')),
        throwsA(isA<FotoInvalidaException>()),
      );

      expect(
        () => validarFoto(
          pngComTamanho(800, 600, extra: kTamanhoMaximoFoto + 1),
        ),
        throwsA(
          isA<FotoInvalidaException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('1,5 MB'),
          ),
        ),
      );
    });
  });

  group('regras da assinatura da empresa', () {
    test('lê as dimensões pelo cabeçalho do PNG', () {
      final dimensoes = dimensoesDoPng(pngComTamanho(900, 300))!;

      expect(dimensoes.largura, 900);
      expect(dimensoes.altura, 300);
      expect(dimensoesDoPng(ascii.encode('xxxxxxxxxxxxxxxxxxxxxxxxxxxx')), isNull);
    });

    test('aceita 3:1 dentro dos limites', () {
      expect(() => validarAssinaturaEmpresa(pngComTamanho(900, 300)), returnsNormally);
      expect(() => validarAssinaturaEmpresa(pngComTamanho(300, 100)), returnsNormally);
      expect(() => validarAssinaturaEmpresa(pngComTamanho(1200, 400)), returnsNormally);
    });

    test('recusa o que a API recusaria, com mensagem clara', () {
      void recusa(Uint8List bytes, String trecho) {
        expect(
          () => validarAssinaturaEmpresa(bytes),
          throwsA(
            isA<FotoInvalidaException>().having(
              (e) => e.mensagem,
              'mensagem',
              contains(trecho),
            ),
          ),
        );
      }

      recusa(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]), 'PNG');
      recusa(pngComTamanho(900, 300, extra: 301 * 1024), '300 KB');
      recusa(pngComTamanho(150, 50), 'Tamanho inválido');
      recusa(pngComTamanho(1800, 600), 'Tamanho inválido');
      recusa(pngComTamanho(600, 400), '3:1');
    });
  });

  group('modal de assinatura', () {
    Future<void> abrir(
      WidgetTester tester,
      void Function(Uint8List?) aoFechar,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async => aoFechar(await mostrarAssinatura(context)),
                child: const Text('assinar'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('assinar'));
      await tester.pumpAndSettle();
    }

    Future<void> riscar(WidgetTester tester) async {
      final area = find.byKey(const Key('assinatura_area'));
      final gesto = await tester.startGesture(tester.getCenter(area));

      for (var i = 0; i < 20; i++) {
        await gesto.moveBy(const Offset(6, 3));
        await tester.pump();
      }

      await gesto.up();
      await tester.pump();
    }

    testWidgets('Confirmar só libera depois de riscar a área', (tester) async {
      await abrir(tester, (_) {});

      ElevatedButton botao() => tester.widget<ElevatedButton>(
        find.byKey(const Key('assinatura_confirmar')),
      );

      expect(botao().onPressed, isNull);

      await riscar(tester);

      expect(botao().onPressed, isNotNull);

      // Limpar volta a bloquear.
      await tester.tap(find.byKey(const Key('assinatura_limpar')));
      await tester.pump();

      expect(botao().onPressed, isNull);
    });

    testWidgets('Cancelar fecha sem assinatura', (tester) async {
      Uint8List? resultado = Uint8List(1);
      await abrir(tester, (r) => resultado = r);

      await riscar(tester);
      await tester.tap(find.byKey(const Key('assinatura_cancelar')));
      await tester.pumpAndSettle();

      expect(resultado, isNull);
      expect(find.byType(SignaturePadDialog), findsNothing);
    });

    testWidgets('Confirmar devolve um PNG 900x300', (tester) async {
      Uint8List? resultado;
      await abrir(tester, (r) => resultado = r);

      await riscar(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const Key('assinatura_confirmar')));
        await Future<void>.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      expect(resultado, isNotNull);
      final dimensoes = dimensoesDoPng(resultado!)!;
      expect(dimensoes.largura, 900);
      expect(dimensoes.altura, 300);
    });
  });

  group('aceite dos termos', () {
    Future<Uint8List?> montar(
      WidgetTester tester, {
      required Uint8List? assinatura,
      required ValueChanged<Uint8List?> onChanged,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AceiteTermosCard(
              assinatura: assinatura,
              onChanged: onChanged,
            ),
          ),
        ),
      );
      return assinatura;
    }

    testWidgets('começa desmarcado e sem prévia', (tester) async {
      await montar(tester, assinatura: null, onChanged: (_) {});

      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('aceite_termos_checkbox')))
            .value,
        isFalse,
      );
      expect(find.byKey(const Key('aceite_termos_previa')), findsNothing);
    });

    testWidgets('marcar a caixa abre o modal; cancelar deixa desmarcada', (
      tester,
    ) async {
      Uint8List? recebida;
      var chamadas = 0;

      await montar(
        tester,
        assinatura: null,
        onChanged: (valor) {
          recebida = valor;
          chamadas++;
        },
      );

      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pumpAndSettle();

      expect(find.byType(SignaturePadDialog), findsOneWidget);

      await tester.tap(find.byKey(const Key('assinatura_cancelar')));
      await tester.pumpAndSettle();

      expect(chamadas, 0);
      expect(recebida, isNull);
    });

    testWidgets('com assinatura mostra a prévia e desmarcar a limpa', (
      tester,
    ) async {
      // 1x1 px transparente.
      final png = base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
      );

      var limpou = false;

      await montar(
        tester,
        assinatura: png,
        onChanged: (valor) => limpou = valor == null,
      );

      expect(
        tester
            .widget<Checkbox>(find.byKey(const Key('aceite_termos_checkbox')))
            .value,
        isTrue,
      );
      expect(find.byKey(const Key('aceite_termos_previa')), findsOneWidget);

      await tester.tap(find.byKey(const Key('aceite_termos_checkbox')));
      await tester.pump();

      expect(limpou, isTrue);
    });

    testWidgets('o link abre a página de Termos e Condições', (tester) async {
      // Tela alta para a lista mostrar todas as seções.
      tester.view.physicalSize = const Size(800, 6000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await montar(tester, assinatura: null, onChanged: (_) {});

      await tester.tap(find.byKey(const Key('aceite_termos_link')));
      await tester.pumpAndSettle();

      expect(find.text('Termos e Condições'), findsWidgets);
      expect(find.byKey(const Key('termos_versao')), findsOneWidget);
      expect(find.text('Versão 1.0'), findsOneWidget);
      expect(find.textContaining('estritamente'), findsOneWidget);
    });
  });

  group('card da assinatura da empresa', () {
    Future<FakeApiAdapter> montar(
      WidgetTester tester, {
      required FakeResponse Function(RequestOptions) handler,
      required Future<Uint8List?> Function() escolher,
    }) async {
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
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: AssinaturaEmpresaCard(escolherArquivo: escolher),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return adapter;
    }

    const semAssinatura = FakeResponse(404, {
      'success': false,
      'message': 'Nenhuma assinatura cadastrada.',
      'code': 'SIGNATURE_NOT_FOUND',
    });

    testWidgets('sem assinatura mostra o aviso e o botão de enviar', (
      tester,
    ) async {
      await montar(
        tester,
        handler: (_) => semAssinatura,
        escolher: () async => null,
      );

      expect(find.byKey(const Key('assinatura_empresa_vazia')), findsOneWidget);
      expect(find.text('Enviar assinatura'), findsOneWidget);
      expect(find.byKey(const Key('assinatura_empresa_remover')), findsNothing);
    });

    testWidgets('envia um PNG 3:1 válido para a API em base64', (tester) async {
      final arquivo = pngComTamanho(900, 300);

      final adapter = await montar(
        tester,
        handler: (request) => request.method == 'PUT'
            ? const FakeResponse(200, {
                'success': true,
                'data': {'tem_assinatura': true},
              })
            : semAssinatura,
        escolher: () async => arquivo,
      );

      await tester.tap(find.byKey(const Key('assinatura_empresa_enviar')));
      await tester.pumpAndSettle();

      final put = adapter.requests.singleWhere((r) => r.method == 'PUT');
      expect(put.path, '/cacambeiros/me/assinatura');
      expect(
        sentBody(put)['assinatura_base64'],
        'data:image/png;base64,${base64Encode(arquivo)}',
      );
      expect(find.text('Assinatura atualizada.'), findsOneWidget);
    });

    testWidgets('arquivo fora da regra não chega a ser enviado', (
      tester,
    ) async {
      final adapter = await montar(
        tester,
        handler: (_) => semAssinatura,
        escolher: () async => pngComTamanho(600, 400),
      );

      await tester.tap(find.byKey(const Key('assinatura_empresa_enviar')));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      expect(find.textContaining('3:1'), findsWidgets);
    });

    testWidgets('cancelar a escolha do arquivo não faz nada', (tester) async {
      final adapter = await montar(
        tester,
        handler: (_) => semAssinatura,
        escolher: () async => null,
      );

      await tester.tap(find.byKey(const Key('assinatura_empresa_enviar')));
      await tester.pumpAndSettle();

      expect(adapter.requests.where((r) => r.method != 'GET'), isEmpty);
    });
  });
}
