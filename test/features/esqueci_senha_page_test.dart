import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin_auth/presentation/pages/admin_login_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/esqueci_senha_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:dio/dio.dart' show RequestOptions;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _pedido({
  String requestId = 'req-1',
  String? codigoDeTeste,
}) => {
  'success': true,
  'message': 'Se os dados estiverem cadastrados, você receberá um código de recuperação.',
  'data': {
    'request_id': requestId,
    'destination_masked': 'ma***@reformas.com',
    'development_code': ?codigoDeTeste,
  },
};

const _senhaTrocada = FakeResponse(200, {
  'success': true,
  'message': 'Senha atualizada com sucesso.',
  'data': null,
});

/// Abre [tela] (o login, por padrão) com a rota do "Esqueci minha senha".
Future<FakeApiAdapter> _abrir(
  WidgetTester tester,
  FakeResponse Function(RequestOptions request) handler, {
  Widget tela = const LoginPage(),
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage();
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
        routes: {AppRoutes.forgotPassword: (_) => const EsqueciSenhaPage()},
      ),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

Finder _naTela(Finder f) =>
    find.descendant(of: find.byType(EsqueciSenhaPage), matching: f);

Finder _campo(int indice) => _naTela(find.byType(TextFormField)).at(indice);

Future<void> _tocar(WidgetTester tester, Finder alvo) async {
  await tester.ensureVisible(alvo);
  await tester.tap(alvo);
  await tester.pumpAndSettle();
}

/// Do login até o segundo passo, com o e-mail da Maria.
Future<void> _pedirCodigo(WidgetTester tester) async {
  await _tocar(tester, find.text('Esqueci minha senha'));
  await tester.enterText(_campo(0), 'maria@reformas.com');
  await _tocar(tester, find.text('ENVIAR CÓDIGO'));
}

Future<void> _preencherNovaSenha(
  WidgetTester tester, {
  String codigo = '482913',
  String senha = 'NovaSenha1',
  String? confirmacao,
}) async {
  await tester.enterText(_campo(0), codigo);
  await tester.enterText(_campo(1), senha);
  await tester.enterText(_campo(2), confirmacao ?? senha);
}

void main() {
  testWidgets('o login abre o "Esqueci minha senha" com o e-mail digitado', (
    tester,
  ) async {
    final api = await _abrir(tester, (_) => const FakeResponse(500, null));

    await tester.enterText(
      find.byType(TextFormField).first,
      'maria@reformas.com',
    );
    await _tocar(tester, find.text('Esqueci minha senha'));

    expect(find.byType(EsqueciSenhaPage), findsOneWidget);
    expect(
      tester.widget<TextFormField>(_campo(0)).controller!.text,
      'maria@reformas.com',
    );
    expect(api.requests, isEmpty);
  });

  testWidgets('o login administrativo também tem o "Esqueci minha senha"', (
    tester,
  ) async {
    await _abrir(
      tester,
      (_) => const FakeResponse(500, null),
      tela: const AdminLoginPage(),
    );

    await _tocar(tester, find.text('Esqueci minha senha'));

    expect(find.byType(EsqueciSenhaPage), findsOneWidget);
  });

  testWidgets('e-mail vazio ou inválido não chama a API', (tester) async {
    final api = await _abrir(tester, (_) => const FakeResponse(500, null));
    await _tocar(tester, find.text('Esqueci minha senha'));

    await _tocar(tester, find.text('ENVIAR CÓDIGO'));
    expect(find.text('Informe seu e-mail'), findsOneWidget);

    await tester.enterText(_campo(0), 'maria@');
    await _tocar(tester, find.text('ENVIAR CÓDIGO'));
    expect(find.text('Informe um e-mail válido'), findsOneWidget);

    expect(api.requests, isEmpty);
  });

  testWidgets(
    'fluxo completo: código, senha nova e volta ao login com o e-mail',
    (tester) async {
      final api = await _abrir(tester, (request) {
        if (request.path == '/auth/forgot-password') {
          return FakeResponse(200, _pedido());
        }
        expect(sentBody(request), {
          'request_id': 'req-1',
          'code': '482913',
          'nova_senha': 'NovaSenha1',
        });
        return _senhaTrocada;
      });

      await _pedirCodigo(tester);

      expect(find.text('Crie uma senha nova'), findsOneWidget);
      expect(find.textContaining('ma***@reformas.com'), findsOneWidget);
      expect(find.textContaining('Modo de teste'), findsNothing);

      await _preencherNovaSenha(tester);
      await _tocar(tester, find.text('REDEFINIR SENHA'));

      expect(api.paths, [
        'POST /auth/forgot-password',
        'POST /auth/reset-password',
      ]);
      expect(api.requests.every((r) => bearer(r) == null), isTrue);
      expect(find.byType(EsqueciSenhaPage), findsNothing);
      expect(
        find.text('Senha alterada! Entre com a senha nova.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'maria@reformas.com',
      );
    },
  );

  testWidgets('código inválido aparece no campo e a tela continua', (
    tester,
  ) async {
    await _abrir(tester, (request) {
      if (request.path == '/auth/forgot-password') {
        return FakeResponse(200, _pedido());
      }
      return const FakeResponse(400, {
        'success': false,
        'message': 'Código inválido, expirado ou já utilizado.',
        'code': 'INVALID_RECOVERY_CODE',
      });
    });

    await _pedirCodigo(tester);
    await _preencherNovaSenha(tester, codigo: '000000');
    await _tocar(tester, find.text('REDEFINIR SENHA'));

    expect(
      _naTela(find.text('Código inválido, expirado ou já utilizado.')),
      findsOneWidget,
    );
    expect(find.text('REDEFINIR SENHA'), findsOneWidget);
  });

  testWidgets('senha fraca ou diferente da confirmação não chama a API', (
    tester,
  ) async {
    final api = await _abrir(tester, (_) => FakeResponse(200, _pedido()));
    await _pedirCodigo(tester);

    await _preencherNovaSenha(tester, senha: 'fraca');
    await _tocar(tester, find.text('REDEFINIR SENHA'));
    expect(
      find.text('A senha deve possuir pelo menos 8 caracteres'),
      findsOneWidget,
    );

    await _preencherNovaSenha(tester, confirmacao: 'OutraSenha1');
    await _tocar(tester, find.text('REDEFINIR SENHA'));
    expect(find.text('As senhas não conferem'), findsOneWidget);

    await _preencherNovaSenha(tester, codigo: '123');
    await _tocar(tester, find.text('REDEFINIR SENHA'));
    expect(find.text('O código tem 6 números'), findsOneWidget);

    expect(api.paths, ['POST /auth/forgot-password']);
  });

  testWidgets('no modo de teste, mostra o código e preenche com um toque', (
    tester,
  ) async {
    await _abrir(
      tester,
      (_) => FakeResponse(200, _pedido(codigoDeTeste: '482913')),
    );
    await _pedirCodigo(tester);

    expect(find.textContaining('Seu código é 482913'), findsOneWidget);

    await _tocar(tester, find.text('Usar este código'));

    expect(tester.widget<TextFormField>(_campo(0)).controller!.text, '482913');
  });

  testWidgets('reenviar código passa a usar o pedido novo', (tester) async {
    var pedidos = 0;
    String? pedidoUsado;
    await _abrir(tester, (request) {
      if (request.path == '/auth/forgot-password') {
        pedidos++;
        return FakeResponse(200, _pedido(requestId: 'req-$pedidos'));
      }
      pedidoUsado = sentBody(request)['request_id'] as String?;
      return _senhaTrocada;
    });
    await _pedirCodigo(tester);

    await _tocar(tester, find.text('Reenviar código'));
    expect(
      find.text('Enviamos um código novo. O anterior não vale mais.'),
      findsOneWidget,
    );

    await _preencherNovaSenha(tester);
    await _tocar(tester, find.text('REDEFINIR SENHA'));

    expect(pedidos, 2);
    expect(pedidoUsado, 'req-2');
  });

  testWidgets('erro da API ao pedir o código aparece e fica no 1º passo', (
    tester,
  ) async {
    await _abrir(
      tester,
      (_) => const FakeResponse(429, {
        'success': false,
        'message': 'Muitas tentativas. Tente novamente mais tarde.',
        'code': 'TOO_MANY_REQUESTS',
      }),
    );
    await _pedirCodigo(tester);

    expect(
      find.text('Muitas tentativas. Tente novamente mais tarde.'),
      findsOneWidget,
    );
    expect(find.text('ENVIAR CÓDIGO'), findsOneWidget);
  });
}
