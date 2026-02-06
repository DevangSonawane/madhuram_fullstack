import 'package:intl/intl.dart';

/// Formatting utilities
class Formatters {
  // Currency formatting
  static final _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final _compactCurrencyFormat = NumberFormat.compactCurrency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 1,
  );

  /// Format as currency
  static String currency(num? value) {
    if (value == null) return '₹0.00';
    return _currencyFormat.format(value);
  }

  /// Format as compact currency (e.g., ₹1.2L, ₹5.3Cr)
  static String compactCurrency(num? value) {
    if (value == null) return '₹0';
    return _compactCurrencyFormat.format(value);
  }

  /// Format large numbers with Indian notation
  static String indianNumber(num? value) {
    if (value == null) return '0';
    final format = NumberFormat('#,##,##,###.##', 'en_IN');
    return format.format(value);
  }

  // Number formatting
  static final _decimalFormat = NumberFormat('#,##0.##');
  static final _integerFormat = NumberFormat('#,##0');

  /// Format number with commas
  static String number(num? value, {int? decimals}) {
    if (value == null) return '0';
    if (decimals != null) {
      return value.toStringAsFixed(decimals);
    }
    return _decimalFormat.format(value);
  }

  /// Format integer
  static String integer(num? value) {
    if (value == null) return '0';
    return _integerFormat.format(value.round());
  }

  /// Format percentage
  static String percentage(num? value, {int decimals = 1}) {
    if (value == null) return '0%';
    return '${value.toStringAsFixed(decimals)}%';
  }

  // Date formatting
  static final _dateFormat = DateFormat('dd/MM/yyyy');
  static final _dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final _timeFormat = DateFormat('HH:mm');
  static final _fullDateFormat = DateFormat('d MMMM yyyy');
  static final _shortDateFormat = DateFormat('d MMM yyyy');
  static final _monthYearFormat = DateFormat('MMMM yyyy');

  /// Format date as dd/MM/yyyy
  static String date(DateTime? value) {
    if (value == null) return '-';
    return _dateFormat.format(value);
  }

  /// Format date and time
  static String dateTime(DateTime? value) {
    if (value == null) return '-';
    return _dateTimeFormat.format(value);
  }

  /// Format time
  static String time(DateTime? value) {
    if (value == null) return '-';
    return _timeFormat.format(value);
  }

  /// Format as full date (e.g., 5 February 2024)
  static String fullDate(DateTime? value) {
    if (value == null) return '-';
    return _fullDateFormat.format(value);
  }

  /// Format as short date (e.g., 5 Feb 2024)
  static String shortDate(DateTime? value) {
    if (value == null) return '-';
    return _shortDateFormat.format(value);
  }

  /// Format as month year (e.g., February 2024)
  static String monthYear(DateTime? value) {
    if (value == null) return '-';
    return _monthYearFormat.format(value);
  }

  /// Format relative time (e.g., "2 hours ago", "yesterday")
  static String relativeTime(DateTime? value) {
    if (value == null) return '-';
    
    final now = DateTime.now();
    final difference = now.difference(value);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  // File size formatting
  /// Format file size
  static String fileSize(int? bytes) {
    if (bytes == null || bytes == 0) return '0 B';
    
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(unitIndex > 0 ? 1 : 0)} ${units[unitIndex]}';
  }

  // Phone formatting
  /// Format phone number
  static String phone(String? value) {
    if (value == null || value.isEmpty) return '-';
    // Remove all non-numeric characters
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digits.length == 10) {
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    } else if (digits.length == 11 && digits.startsWith('0')) {
      return '${digits.substring(0, 1)} ${digits.substring(1, 6)} ${digits.substring(6)}';
    } else if (digits.length == 12 && digits.startsWith('91')) {
      return '+91 ${digits.substring(2, 7)} ${digits.substring(7)}';
    }
    return value;
  }

  // Text truncation
  /// Truncate text with ellipsis
  static String truncate(String? text, int maxLength) {
    if (text == null) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Capitalize first letter
  static String capitalize(String? text) {
    if (text == null || text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Title case
  static String titleCase(String? text) {
    if (text == null || text.isEmpty) return '';
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  /// Get initials from name
  static String initials(String? name, {int count = 2}) {
    if (name == null || name.isEmpty) return '';
    final words = name.trim().split(RegExp(r'\s+'));
    return words.take(count).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
  }

  // Status formatting
  /// Format status with proper casing
  static String status(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value.replaceAll('_', ' ').split(' ').map((word) => capitalize(word)).join(' ');
  }

  // Quantity with unit
  /// Format quantity with unit
  static String quantity(num? value, String? unit) {
    if (value == null) return '-';
    final formatted = number(value);
    return unit != null ? '$formatted $unit' : formatted;
  }

  // Duration formatting
  /// Format duration
  static String duration(Duration? value) {
    if (value == null) return '-';
    
    if (value.inDays > 0) {
      return '${value.inDays}d ${value.inHours.remainder(24)}h';
    } else if (value.inHours > 0) {
      return '${value.inHours}h ${value.inMinutes.remainder(60)}m';
    } else if (value.inMinutes > 0) {
      return '${value.inMinutes}m';
    } else {
      return '${value.inSeconds}s';
    }
  }
}
