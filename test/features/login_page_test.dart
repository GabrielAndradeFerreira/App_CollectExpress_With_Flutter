import 'package:app_collect_express_with_flutter/core/network/api_client.dart';
import 'package:app_collect_express_with_flutter/core/network/api_providers.dart';
import 'package:app_collect_express_with_flutter/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_api.dart';

Future<FakeApiAdapter> _abrirLogin(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1200, 2000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final tokens = InMemoryTokenStorage();
  final adapter = FakeApiAdapter((_) => const FakeResponse(500, null));

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        tokenStorageProvider.overrideWithValue(tokens),
        apiClientProvider.overrideWith(
          (ref) => ApiClient(storage: tokens, adapter: adapter),
        ),
      ],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
  await tester.pumpAndSettle();
  return adapter;
}

/// Diz se o foco do teclado está no controle que contém [finder].
bool _temFoco(WidgetTester tester, Finder finder) =>
    Focus.of(tester.element(finder)).hasPrimaryFocus;

bool _campoTemFoco(WidgetTester tester, int indice) => tester
    .widget<EditableText>(find.byType(EditableText).at(indice))
    .focusNode
    .hasPrimaryFocus;

void main() {
  testWidgets('login: campos vazios mostram as mensagens e não chamam a API', (
    tester,
  ) async {
    final api = await _abrirLogin(tester);

    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Informe seu e-mail'), findsOneWidget);
    expect(find.text('Informe sua senha'), findsOneWidget);
    expect(api.requests, isEmpty);
  });

  testWidgets('login: e-mail inválido e senha curta são recusados', (
    tester,
  ) async {
    final api = await _abrirLogin(tester);

    await tester.enterText(find.byType(TextFormField).at(0), 'joao@');
    await tester.enterText(find.byType(TextFormField).at(1), '123');
    await tester.tap(find.text('ENTRAR'));
    await tester.pumpAndSettle();

    expect(find.text('Informe um e-mail válido'), findsOneWidget);
    expect(
      find.text('A senha deve possuir pelo menos 6 caracteres'),
      findsOneWidget,
    );
    expect(api.requests, isEmpty);
  });

  testWidgets('login: a tecla Tab percorre os controles em ordem lógica', (
    tester,
  ) async {
    await _abrirLogin(tester);

    await tester.tap(find.byType(TextFormField).at(0));
    await tester.pump();
    expect(_campoTemFoco(tester, 0), isTrue, reason: 'e-mail');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_campoTemFoco(tester, 1), isTrue, reason: 'senha');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      _temFoco(tester, find.byIcon(Icons.visibility_outlined)),
      isTrue,
      reason: 'botão de mostrar senha',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      _temFoco(tester, find.text('Esqueci minha senha')),
      isTrue,
      reason: 'esqueci minha senha',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_temFoco(tester, find.text('ENTRAR')), isTrue, reason: 'ENTRAR');

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      _temFoco(tester, find.text('Cadastre-se')),
      isTrue,
      reason: 'Cadastre-se',
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(
      _temFoco(tester, find.text('ACESSO ADMINISTRATIVO')),
      isTrue,
      reason: 'acesso administrativo',
    );
  });

  testWidgets('login: o botão de mostrar senha tem nome acessível', (
    tester,
  ) async {
    await _abrirLogin(tester);

    expect(find.byTooltip('Mostrar senha'), findsOneWidget);

    await tester.tap(find.byTooltip('Mostrar senha'));
    await tester.pump();

    expect(find.byTooltip('Ocultar senha'), findsOneWidget);
  });
}
