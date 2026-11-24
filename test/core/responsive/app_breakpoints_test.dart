import 'package:app_collect_express_with_flutter/core/responsive/app_breakpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppBreakpoints', () {
    test('seleciona limites de largura para cada categoria', () {
      expect(AppBreakpoints.maxContentWidthFor(360), isNull);
      expect(AppBreakpoints.maxContentWidthFor(390), isNull);
      expect(AppBreakpoints.maxContentWidthFor(430), isNull);
      expect(
        AppBreakpoints.maxContentWidthFor(768),
        AppBreakpoints.tabletContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(1366),
        AppBreakpoints.desktopContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(2560),
        AppBreakpoints.desktopContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(1920),
        AppBreakpoints.desktopContentMaxWidth,
      );
    });

    test('aplica os breakpoints nas larguras de transição', () {
      expect(AppBreakpoints.maxContentWidthFor(599), isNull);
      expect(
        AppBreakpoints.maxContentWidthFor(600),
        AppBreakpoints.tabletContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(1023),
        AppBreakpoints.tabletContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(1024),
        AppBreakpoints.desktopContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(1439),
        AppBreakpoints.desktopContentMaxWidth,
      );
      expect(
        AppBreakpoints.maxContentWidthFor(1440),
        AppBreakpoints.desktopContentMaxWidth,
      );
    });
  });
}
