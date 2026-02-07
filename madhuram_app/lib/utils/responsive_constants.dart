/// Responsive constants for consistent spacing, font sizes, and dimensions
/// across the entire application. Based on an 8px grid system.
class ResponsiveConstants {
  // Prevent instantiation
  ResponsiveConstants._();

  // ── Breakpoints ──
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  static const double wideBreakpoint = 1280;

  // ── Spacing scale (based on 4px increments) ──
  static const double space1 = 4.0;
  static const double space2 = 8.0;
  static const double space3 = 12.0;
  static const double space4 = 16.0;
  static const double space5 = 20.0;
  static const double space6 = 24.0;
  static const double space8 = 32.0;
  static const double space10 = 40.0;
  static const double space12 = 48.0;

  // ── Font size scale ──
  static const double fontXS = 10.0;
  static const double fontSM = 12.0;
  static const double fontMD = 14.0;
  static const double fontLG = 16.0;
  static const double fontXL = 18.0;
  static const double font2XL = 20.0;
  static const double font3XL = 24.0;
  static const double font4XL = 32.0;

  // ── Border radius ──
  static const double radiusSM = 4.0;
  static const double radiusMD = 8.0;
  static const double radiusLG = 12.0;
  static const double radiusXL = 16.0;
  static const double radiusFull = 999.0;

  // ── Icon sizes ──
  static const double iconSM = 16.0;
  static const double iconMD = 20.0;
  static const double iconLG = 24.0;
  static const double iconXL = 32.0;

  // ── Min touch target ──
  static const double minTouchTarget = 44.0;

  // ── Max content widths ──
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;
  static const double maxDialogWidth = 500.0;
  static const double maxDialogWidthLarge = 700.0;
}
