import 'package:flutter/material.dart';

/// Lightweight responsive helpers. Use via `Responsive.xxx(context)`.
class Responsive {
  Responsive._();

  static double screenWidth(BuildContext context) => MediaQuery.sizeOf(context).width;
  static double screenHeight(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// shortestSide >= 600 → tablet.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).shortestSide >= 600;

  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  static bool isSmallPhone(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// Grid cross-axis count — [tablet] columns on tablets, [mobile] otherwise.
  static int gridColumns(BuildContext context, {int mobile = 2, int tablet = 3}) =>
      isTablet(context) ? tablet : mobile;

  /// Width for horizontal-scroll cards (featured deals, etc.).
  static double featuredCardWidth(BuildContext context) {
    final w = screenWidth(context);
    if (w < 360) return 130;
    if (w < 600) return 160;
    return 200;
  }

  /// Maximum content width for forms on tablets (allows centred layout).
  static double maxFormWidth(BuildContext context) =>
      isTablet(context) ? 520 : double.infinity;

  /// Hero image gallery height — shrinks in landscape and on small phones.
  static double galleryHeight(BuildContext context) {
    final h = screenHeight(context);
    if (isLandscape(context)) return (h * 0.65).clamp(200, 400);
    return (h * 0.38).clamp(220, 320);
  }

  /// Safe top padding (status bar) — use instead of hardcoding dp values.
  static double statusBarHeight(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  /// Login / splash header height — smaller in landscape.
  static double authHeaderHeight(BuildContext context) {
    if (isLandscape(context)) return 160;
    final h = screenHeight(context);
    return (h * 0.34).clamp(180, 300);
  }
}
