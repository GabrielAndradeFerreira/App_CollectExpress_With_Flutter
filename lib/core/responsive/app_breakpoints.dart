abstract final class AppBreakpoints {
  static const mobile = 600.0;
  static const tablet = 1024.0;
  static const desktop = 1440.0;

  static const tabletContentMaxWidth = 1024.0;
  static const desktopContentMaxWidth = 1200.0;

  static double? maxContentWidthFor(double width) {
    if (width < mobile) return null;
    if (width < tablet) return tabletContentMaxWidth;
    return desktopContentMaxWidth;
  }
}
