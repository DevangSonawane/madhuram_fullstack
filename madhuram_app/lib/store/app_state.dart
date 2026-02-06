// App State - Matching React app structure
import 'package:flutter/material.dart';

/// Authentication State
class AuthState {
  final Map<String, dynamic>? user;
  final bool isAuthenticated;
  final bool loading;
  final String? error;

  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.loading = false,
    this.error,
  });

  AuthState copyWith({
    Map<String, dynamic>? user,
    bool? isAuthenticated,
    bool? loading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      loading: loading ?? this.loading,
      error: error,
    );
  }

  // Helper getters for user properties
  String? get userName => user?['name'] as String?;
  String? get userEmail => user?['email'] as String?;
  String? get userRole => user?['role'] as String?;
  String? get userPhone => user?['phone_number'] as String?;
  String? get userAvatar => user?['avatar'] as String?;
  bool get isAdmin => userRole == 'admin';
}

/// Project State - Matching React ProjectContext
class ProjectState {
  final List<Map<String, dynamic>> projects;
  final Map<String, dynamic>? selectedProject;
  final bool loading;
  final String? error;

  const ProjectState({
    this.projects = const [],
    this.selectedProject,
    this.loading = false,
    this.error,
  });

  ProjectState copyWith({
    List<Map<String, dynamic>>? projects,
    Map<String, dynamic>? selectedProject,
    bool? loading,
    String? error,
    bool clearSelectedProject = false,
  }) {
    return ProjectState(
      projects: projects ?? this.projects,
      selectedProject: clearSelectedProject ? null : (selectedProject ?? this.selectedProject),
      loading: loading ?? this.loading,
      error: error,
    );
  }

  // Helper getters
  String? get selectedProjectId => 
      selectedProject?['id']?.toString() ?? 
      selectedProject?['project_id']?.toString();
  
  String? get selectedProjectName => selectedProject?['name'] as String?;
}

/// Theme Mode enum matching React ThemeContext
enum AppThemeMode { light, dark, system }

/// Theme State - Matching React ThemeContext
class ThemeState {
  final AppThemeMode mode;

  const ThemeState({this.mode = AppThemeMode.system});

  ThemeState copyWith({AppThemeMode? mode}) {
    return ThemeState(mode: mode ?? this.mode);
  }

  ThemeMode get flutterThemeMode {
    switch (mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }
}

/// Notification item model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool read;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.read = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    bool? read,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      read: read ?? this.read,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      time: json['time'] as String? ?? '',
      read: json['read'] as bool? ?? false,
    );
  }
}

/// Notification State - Matching React NotificationContext
class NotificationState {
  final List<NotificationItem> notifications;
  final bool loading;

  const NotificationState({
    this.notifications = const [],
    this.loading = false,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    bool? loading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      loading: loading ?? this.loading,
    );
  }

  int get unreadCount => notifications.where((n) => !n.read).length;
}

/// Main App State combining all slices
class AppState {
  final AuthState auth;
  final ProjectState project;
  final ThemeState theme;
  final NotificationState notification;

  const AppState({
    required this.auth,
    required this.project,
    required this.theme,
    required this.notification,
  });

  AppState copyWith({
    AuthState? auth,
    ProjectState? project,
    ThemeState? theme,
    NotificationState? notification,
  }) {
    return AppState(
      auth: auth ?? this.auth,
      project: project ?? this.project,
      theme: theme ?? this.theme,
      notification: notification ?? this.notification,
    );
  }

  static AppState initial() => const AppState(
        auth: AuthState(),
        project: ProjectState(),
        theme: ThemeState(),
        notification: NotificationState(),
      );
}
