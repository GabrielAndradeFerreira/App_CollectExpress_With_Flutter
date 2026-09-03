import 'package:app_collect_express_with_flutter/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('exibe a tela inicial', (tester) async {
    await tester.pumpWidget(const CollectApp());

    expect(find.text('O que você vai descartar?'), findsOneWidget);
  });
}