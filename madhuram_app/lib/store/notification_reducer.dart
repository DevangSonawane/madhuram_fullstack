// Notification Reducer - Handles notification state changes
import 'package:redux/redux.dart';
import 'app_state.dart';
import 'notification_actions.dart';

final Reducer<NotificationState> notificationReducer = combineReducers<NotificationState>([
  TypedReducer<NotificationState, FetchNotificationsStart>(_onFetchNotificationsStart),
  TypedReducer<NotificationState, FetchNotificationsSuccess>(_onFetchNotificationsSuccess),
  TypedReducer<NotificationState, MarkNotificationAsRead>(_onMarkAsRead),
  TypedReducer<NotificationState, MarkAllNotificationsAsRead>(_onMarkAllAsRead),
  TypedReducer<NotificationState, ClearNotifications>(_onClearNotifications),
]);

NotificationState _onFetchNotificationsStart(NotificationState state, FetchNotificationsStart action) {
  return state.copyWith(loading: true);
}

NotificationState _onFetchNotificationsSuccess(NotificationState state, FetchNotificationsSuccess action) {
  return state.copyWith(
    notifications: action.notifications,
    loading: false,
  );
}

NotificationState _onMarkAsRead(NotificationState state, MarkNotificationAsRead action) {
  final updatedNotifications = state.notifications.map((n) {
    if (n.id == action.notificationId) {
      return n.copyWith(read: true);
    }
    return n;
  }).toList();
  
  return state.copyWith(notifications: updatedNotifications);
}

NotificationState _onMarkAllAsRead(NotificationState state, MarkAllNotificationsAsRead action) {
  final updatedNotifications = state.notifications.map((n) {
    return n.copyWith(read: true);
  }).toList();
  
  return state.copyWith(notifications: updatedNotifications);
}

NotificationState _onClearNotifications(NotificationState state, ClearNotifications action) {
  return state.copyWith(notifications: []);
}
