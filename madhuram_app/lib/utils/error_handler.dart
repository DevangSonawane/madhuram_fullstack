import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Error types for categorization
enum ErrorType {
  network,
  server,
  validation,
  authentication,
  authorization,
  notFound,
  unknown,
}

/// Custom app exception
class AppException implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;

  AppException(this.message, {this.type = ErrorType.unknown, this.originalError});

  @override
  String toString() => message;

  factory AppException.network([String? message]) {
    return AppException(
      message ?? 'Network error. Please check your connection.',
      type: ErrorType.network,
    );
  }

  factory AppException.server([String? message]) {
    return AppException(
      message ?? 'Server error. Please try again later.',
      type: ErrorType.server,
    );
  }

  factory AppException.validation(String message) {
    return AppException(message, type: ErrorType.validation);
  }

  factory AppException.authentication([String? message]) {
    return AppException(
      message ?? 'Authentication failed. Please login again.',
      type: ErrorType.authentication,
    );
  }

  factory AppException.authorization([String? message]) {
    return AppException(
      message ?? 'You do not have permission to perform this action.',
      type: ErrorType.authorization,
    );
  }

  factory AppException.notFound([String? message]) {
    return AppException(
      message ?? 'The requested resource was not found.',
      type: ErrorType.notFound,
    );
  }
}

/// Error handler utility
class ErrorHandler {
  /// Get user-friendly error message
  static String getMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    if (error is String) {
      return error;
    }
    return 'An unexpected error occurred';
  }

  /// Get error type from HTTP status code
  static ErrorType getTypeFromStatusCode(int statusCode) {
    if (statusCode == 401) return ErrorType.authentication;
    if (statusCode == 403) return ErrorType.authorization;
    if (statusCode == 404) return ErrorType.notFound;
    if (statusCode >= 400 && statusCode < 500) return ErrorType.validation;
    if (statusCode >= 500) return ErrorType.server;
    return ErrorType.unknown;
  }

  /// Get icon for error type
  static IconData getIcon(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.cloud_off;
      case ErrorType.validation:
        return Icons.warning_amber;
      case ErrorType.authentication:
        return Icons.lock_outline;
      case ErrorType.authorization:
        return Icons.block;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.unknown:
        return Icons.error_outline;
    }
  }

  /// Get color for error type
  static Color getColor(ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return Colors.orange;
      case ErrorType.server:
        return Colors.red;
      case ErrorType.validation:
        return Colors.amber;
      case ErrorType.authentication:
        return Colors.purple;
      case ErrorType.authorization:
        return Colors.red;
      case ErrorType.notFound:
        return Colors.grey;
      case ErrorType.unknown:
        return Colors.red;
    }
  }
}

/// Error display widget
class ErrorDisplay extends StatelessWidget {
  final String message;
  final ErrorType type;
  final VoidCallback? onRetry;
  final bool compact;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.type = ErrorType.unknown,
    this.onRetry,
    this.compact = false,
  });

  factory ErrorDisplay.fromException(dynamic error, {VoidCallback? onRetry, bool compact = false}) {
    if (error is AppException) {
      return ErrorDisplay(
        message: error.message,
        type: error.type,
        onRetry: onRetry,
        compact: compact,
      );
    }
    return ErrorDisplay(
      message: ErrorHandler.getMessage(error),
      onRetry: onRetry,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = ErrorHandler.getColor(type);
    final icon = ErrorHandler.getIcon(type);

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground, fontSize: 14),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(icon, color: color, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state display widget
class EmptyStateDisplay extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const EmptyStateDisplay({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
