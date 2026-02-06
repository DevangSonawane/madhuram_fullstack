/// Notification model matching React app
class AppNotification {
  final String id;
  final String title;
  final String? message;
  final String? type;
  final bool isRead;
  final DateTime? createdAt;
  final String? userId;
  final String? projectId;
  final Map<String, dynamic>? data;

  const AppNotification({
    required this.id,
    required this.title,
    this.message,
    this.type,
    this.isRead = false,
    this.createdAt,
    this.userId,
    this.projectId,
    this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['notification_id'] ?? json['id'] ?? '').toString(),
      title: json['title'] ?? '',
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] == true || json['isRead'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
      userId: json['user_id']?.toString(),
      projectId: json['project_id']?.toString(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
    'notification_id': id,
    'title': title,
    'message': message,
    'type': type,
    'is_read': isRead,
    'user_id': userId,
    'project_id': projectId,
    'data': data,
  };

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    String? type,
    bool? isRead,
    DateTime? createdAt,
    String? userId,
    String? projectId,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
      projectId: projectId ?? this.projectId,
      data: data ?? this.data,
    );
  }
}
