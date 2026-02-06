// Theme Actions - Matching React ThemeContext
import 'app_state.dart';

class SetTheme {
  final AppThemeMode mode;
  SetTheme(this.mode);
}

class LoadTheme {
  final AppThemeMode mode;
  LoadTheme(this.mode);
}
