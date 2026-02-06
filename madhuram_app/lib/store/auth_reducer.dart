// Auth Reducer - Updated to work with new AppState structure
import 'package:redux/redux.dart';
import 'app_state.dart';
import 'auth_actions.dart';
import 'project_reducer.dart';
import 'theme_reducer.dart';
import 'notification_reducer.dart';

// Combined App Reducer
AppState appReducer(AppState state, dynamic action) {
  return AppState(
    auth: authReducer(state.auth, action),
    project: projectReducer(state.project, action),
    theme: themeReducer(state.theme, action),
    notification: notificationReducer(state.notification, action),
  );
}

// Auth-specific reducer
final Reducer<AuthState> authReducer = combineReducers<AuthState>([
  TypedReducer<AuthState, LoginStart>(_onLoginStart),
  TypedReducer<AuthState, LoginSuccess>(_onLoginSuccess),
  TypedReducer<AuthState, LoginFailure>(_onLoginFailure),
  TypedReducer<AuthState, Logout>(_onLogout),
]);

AuthState _onLoginStart(AuthState state, LoginStart action) {
  return state.copyWith(loading: true, error: null);
}

AuthState _onLoginSuccess(AuthState state, LoginSuccess action) {
  return state.copyWith(
    user: action.user,
    isAuthenticated: true,
    loading: false,
    error: null,
  );
}

AuthState _onLoginFailure(AuthState state, LoginFailure action) {
  return state.copyWith(
    user: null,
    isAuthenticated: false,
    loading: false,
    error: action.error,
  );
}

AuthState _onLogout(AuthState state, Logout action) {
  return const AuthState(
    user: null,
    isAuthenticated: false,
    loading: false,
    error: null,
  );
}
