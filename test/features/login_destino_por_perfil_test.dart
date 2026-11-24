import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/admin_geral_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/gestao_usuarios_page.dart';
import 'package:app_collect_express_with_flutter/features/admin/presentation/pages/painel_admin_page.dart';
import 'package:app_collect_express_with_flutter/features/admin_auth/presentation/pages/admin_login_page.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/garantir_login.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:app_collect_express_with_flutter/features/institucional/presentation/pages/saiba_mais_page.dart';
import 'package:app_collect_express_with_flutter/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Map<String, dynamic> _usuario(String tipoPerfil) => {
  'id': 'u1',
  'nome_completo': 'Usuário Teste',
  'email': 'teste@email.com',
  'tipo_perfil': tipoPerfil,
  'status': 'ATIVO',
};

/// Abre o app de verdade (com a tabela de rotas do main.dart). O login e o
/// perfil devolvem um usuário [tipoPerfil].
///
/// Com [logado], já há uma sessão salva, como ao reabrir o app. O perfil
/// pode demorar [atrasoDoPerfil] para responder.
Future<void> _abrirApp(
  WidgetTester tester, {
  required String tipoPerfil,
  bool logado = false,
  Duration atrasoDoPerfil = Duration.zero,
  bool esperar = true,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = logado
      ? InMemoryTokenStorage(accessToken: 'token', refreshToken: 'refresh')
      : InMemoryTokenStorage();
  final adapter = FakeApiAdapter((request) {
    if (request.path == '/auth/login') {
      return FakeResponse(200, {
        'success': true,
        'data': {
          'access_token': 'token',
          'refresh_token': 'refresh',
          'usuario': _usuario(tipoPerfil),
        },
      });
    }
    if (request.path == '/usuarios/perfil') {
      return FakeResponse(200, {
        'success': true,
        'data': _usuario(tipoPerfil),
      }, delay: atrasoDoPerfil);
    }
    return const FakeResponse(404, {
      'success': false,
      'error': 'não encontrado',
    });
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
      child: const CollectApp(),
    ),
  );
  if (esperar) await _esperar(tester);
}

Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

NavigatorState _navigator(WidgetTester tester) =>
    tester.state<NavigatorState>(find.byType(Navigator).first);

Future<void> _abrirRota(WidgetTester tester, String rota) async {
  _navigator(tester).pushNamed(rota);
  await _esperar(tester);
}

Future<void> _tocar(WidgetTester tester, String texto) async {
  await tester.ensureVisible(find.text(texto));
  await tester.tap(find.text(texto));
  await _esperar(tester);
}

/// Preenche a tela de login que está à frente e toca em [botao].
Future<void> _entrar(
  WidgetTester tester, {
  Type tela = LoginPage,
  String botao = 'ENTRAR',
}) async {
  // Outras telas continuam na pilha; procura só dentro da tela de login.
  Finder naTela(Finder f) =>
      find.descendant(of: find.byType(tela), matching: f);
  await tester.enterText(
    naTela(find.byType(TextFormField)).at(0),
    'teste@email.com',
  );
  await tester.enterText(naTela(find.byType(TextFormField)).at(1), '123456');
  await tester.tap(naTela(find.text(botao)));
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

/// Tela com uma ação que exige conta, como o "adicionar ao carrinho".
class _AcaoQuePedeLogin extends ConsumerWidget {
  const _AcaoQuePedeLogin(this.aoTerminar);

  final void Function(bool continuar) aoTerminar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async => aoTerminar(await garantirLogin(context, ref)),
          child: const Text('ALUGAR'),
        ),
      ),
    );
  }
}

void main() {
  group('cada perfil cai no seu início', () {
    testWidgets('login comum com ADMIN abre o painel do administrador', (
      tester,
    ) async {
      await _abrirApp(tester, tipoPerfil: 'ADMIN');
      await _abrirRota(tester, AppRoutes.login);

      await _entrar(tester);

      expect(find.byType(AdminGeralPage), findsOneWidget);
      expect(find.byType(PainelAdminPage), findsNothing);
    });

    testWidgets(
      'login do administrador com ADMIN abre o painel do administrador',
      (tester) async {
        await _abrirApp(tester, tipoPerfil: 'ADMIN');
        await _abrirRota(tester, AppRoutes.adminLogin);

        await _entrar(tester, tela: AdminLoginPage, botao: 'ENTRAR NO PAINEL');

        expect(find.byType(AdminGeralPage), findsOneWidget);
        expect(find.byType(PainelAdminPage), findsNothing);
      },
    );

    testWidgets('login comum com CACAMBEIRO abre o painel do fornecedor', (
      tester,
    ) async {
      await _abrirApp(tester, tipoPerfil: 'CACAMBEIRO');
      await _abrirRota(tester, AppRoutes.login);

      await _entrar(tester);

      expect(find.byType(PainelAdminPage), findsOneWidget);
      expect(find.byType(AdminGeralPage), findsNothing);
    });

    testWidgets('cliente: login aberto pelo menu cai no início', (
      tester,
    ) async {
      await _abrirApp(tester, tipoPerfil: 'CONSUMIDOR');
      await _abrirRota(tester, AppRoutes.login);

      await _entrar(tester);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
    });

    testWidgets('cliente: login aberto pelo "Saiba mais" cai no início', (
      tester,
    ) async {
      await _abrirApp(tester, tipoPerfil: 'CONSUMIDOR');
      await _abrirRota(tester, AppRoutes.about);
      await _tocar(tester, 'JÁ TENHO UMA CONTA');

      await _entrar(tester);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SaibaMaisPage), findsNothing);
      expect(find.byType(LoginPage), findsNothing);
    });

    // Ir ao acesso administrativo e voltar deixava dois logins na pilha:
    // o cliente entrava e caía no login de trás.
    testWidgets(
      'cliente: indo ao acesso administrativo e voltando, cai no início',
      (tester) async {
        await _abrirApp(tester, tipoPerfil: 'CONSUMIDOR');
        await _abrirRota(tester, AppRoutes.login);
        await _tocar(tester, 'ACESSO ADMINISTRATIVO');
        await _tocar(tester, 'Acessar como cliente');

        await _entrar(tester);

        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(LoginPage), findsNothing);
      },
    );
  });

  group('reabrindo o app com a sessão salva', () {
    testWidgets('admin abre no painel do admin', (tester) async {
      await _abrirApp(tester, tipoPerfil: 'ADMIN', logado: true);

      expect(find.byType(AdminGeralPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('caçambeiro abre no painel do fornecedor', (tester) async {
      await _abrirApp(tester, tipoPerfil: 'CACAMBEIRO', logado: true);

      expect(find.byType(PainelAdminPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('cliente continua na página inicial', (tester) async {
      await _abrirApp(tester, tipoPerfil: 'CONSUMIDOR', logado: true);

      expect(find.byType(HomePage), findsOneWidget);
    });

    // Na web, um link direto para /admin/usuarios abre essa tela por cima
    // da inicial. A inicial, embaixo, não pode trocá-la pelo painel.
    testWidgets('não troca uma tela de admin aberta por cima da inicial', (
      tester,
    ) async {
      await _abrirApp(
        tester,
        tipoPerfil: 'ADMIN',
        logado: true,
        atrasoDoPerfil: const Duration(milliseconds: 500),
        esperar: false,
      );
      _navigator(tester).pushNamed(AppRoutes.adminUsers);
      for (var i = 0; i < 15; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(GestaoUsuariosPage), findsOneWidget);
      expect(find.byType(AdminGeralPage), findsNothing);
    });
  });

  group('login pedido no meio de uma ação', () {
    testWidgets('cliente volta para a tela e a ação continua', (tester) async {
      bool? continuou;
      await _abrirApp(tester, tipoPerfil: 'CONSUMIDOR');
      _navigator(tester).push(
        MaterialPageRoute<void>(
          builder: (_) => _AcaoQuePedeLogin((valor) => continuou = valor),
        ),
      );
      await _esperar(tester);
      await _tocar(tester, 'ALUGAR');

      expect(find.byType(LoginPage), findsOneWidget);

      await _entrar(tester);

      expect(find.byType(_AcaoQuePedeLogin), findsOneWidget);
      expect(find.byType(LoginPage), findsNothing);
      expect(continuou, isTrue);
    });

    testWidgets('fornecedor vai para o painel e a ação não continua', (
      tester,
    ) async {
      bool? continuou;
      await _abrirApp(tester, tipoPerfil: 'CACAMBEIRO');
      _navigator(tester).push(
        MaterialPageRoute<void>(
          builder: (_) => _AcaoQuePedeLogin((valor) => continuou = valor),
        ),
      );
      await _esperar(tester);
      await _tocar(tester, 'ALUGAR');

      await _entrar(tester);

      expect(find.byType(PainelAdminPage), findsOneWidget);
      expect(find.byType(_AcaoQuePedeLogin), findsNothing);
      expect(continuou, isFalse);
    });

    testWidgets('voltar do login sem entrar não continua a ação', (
      tester,
    ) async {
      bool? continuou;
      await _abrirApp(tester, tipoPerfil: 'CONSUMIDOR');
      _navigator(tester).push(
        MaterialPageRoute<void>(
          builder: (_) => _AcaoQuePedeLogin((valor) => continuou = valor),
        ),
      );
      await _esperar(tester);
      await _tocar(tester, 'ALUGAR');

      _navigator(tester).pop();
      await _esperar(tester);

      expect(find.byType(_AcaoQuePedeLogin), findsOneWidget);
      expect(continuou, isFalse);
    });
  });
}
