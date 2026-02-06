// Theme Reducer - Handles theme state changes
import 'package:redux/redux.dart';
import 'app_state.dart';
import 'theme_actions.dart';

final Reducer<ThemeState> themeReducer = combineReducers<ThemeState>([
  TypedReducer<ThemeState, SetTheme>(_onSetTheme),
  TypedReducer<ThemeState, LoadTheme>(_onLoadTheme),
]);

ThemeState _onSetTheme(ThemeState state, SetTheme action) {
  return state.copyWith(mode: action.mode);
}

ThemeState _onLoadTheme(ThemeState state, LoadTheme action) {
  return state.copyWith(mode: action.mode);
}
