import 'package:flutter/material.dart';

import 'app_routes.dart';

/// Chaves do `MaterialApp`, para navegar e avisar a pessoa de fora de uma
/// tela (ex.: quando a sessão expira ou um erro não tratado acontece).
abstract final class AppNavigator {
  static final navigator = GlobalKey<NavigatorState>();
  static final messenger = GlobalKey<ScaffoldMessengerState>();

  /// Volta para a tela inicial do app, descartando as telas abertas.
  static void irParaInicio() {
    navigator.currentState?.pushNamedAndRemoveUntil(
      AppRoutes.home,
      (route) => false,
    );
  }

  static void avisar(String texto, {Color? cor}) {
    messenger.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(texto), backgroundColor: cor));
  }
}
