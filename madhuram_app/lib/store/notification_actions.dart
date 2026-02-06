// Notification Actions - Matching React NotificationContext
import 'app_state.dart';

class FetchNotificationsStart {}

class FetchNotificationsSuccess {
  final List<NotificationItem> notifications;
  FetchNotificationsSuccess(this.notifications);
}

class MarkNotificationAsRead {
  final String notificationId;
  MarkNotificationAsRead(this.notificationId);
}

class MarkAllNotificationsAsRead {}

class ClearNotifications {}
