import 'package:app_collect_express_with_flutter/core/models/enums.dart';
import 'package:app_collect_express_with_flutter/core/navigation/app_routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRoutes.inicioDoPerfil', () {
    test('cada perfil tem o seu início', () {
      expect(AppRoutes.inicioDoPerfil(TipoPerfil.cacambeiro), AppRoutes.supplierHome);
      expect(AppRoutes.inicioDoPerfil(TipoPerfil.admin), AppRoutes.adminHome);
      expect(AppRoutes.inicioDoPerfil(TipoPerfil.parceiro), AppRoutes.recyclingHome);
    });

    test('cliente e quem não entrou ficam na página inicial', () {
      expect(AppRoutes.inicioDoPerfil(TipoPerfil.consumidor), AppRoutes.home);
      expect(AppRoutes.inicioDoPerfil(null), AppRoutes.home);
    });
  });
}
