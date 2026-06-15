class AppSizes {
  AppSizes._();

  // Spacing scale (4-pt grid)
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;
  static const double s10 = 40.0;
  static const double s12 = 48.0;
  static const double s16 = 64.0;

  // Aliases kept for back-compat
  static const double xs = s1;
  static const double sm = s2;
  static const double md = s3;
  static const double lg = s4;
  static const double xl = s5;
  static const double xxl = s6;
  static const double xxxl = s8;
  static const double huge = s12;

  // Border radius
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;
  static const double radiusFull = 999.0;

  // Convenience aliases
  static const double radiusCard = radiusLg;
  static const double radiusChip = radiusXl;
  static const double radiusButton = radiusMd;
  static const double radiusInput = radiusMd;
  static const double radiusBottomSheet = radiusXxl;

  // Component heights
  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;

  // Icon sizes
  static const double iconXs = 14.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 48.0;

  // Layout
  static const double pageHorizontalPadding = 16.0;
  static const double cardPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double listItemSpacing = 10.0;

  // Shadow (used in AppShadows)
  static const double shadowBlur = 8.0;
  static const double shadowSpread = 0.0;
  static const double shadowOffsetY = 2.0;

  // Deprecated aliases (remove gradually)
  static const double cardRadius = radiusCard;
  static const double chipRadius = radiusChip;
  static const double buttonRadius = radiusButton;
  static const double inputRadius = radiusInput;
  static const double appBarElevation = 0.0;
}
