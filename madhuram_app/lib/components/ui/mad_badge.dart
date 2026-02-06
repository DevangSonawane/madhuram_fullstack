import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

enum BadgeVariant { primary, secondary, destructive, outline, success, warning, default_ }

/// Badge component matching shadcn/ui Badge
class MadBadge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final Widget? icon;

  const MadBadge({
    super.key,
    required this.text,
    this.variant = BadgeVariant.primary,
    this.padding,
    this.textStyle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    Color? borderColor;

    switch (variant) {
      case BadgeVariant.primary:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        break;
      case BadgeVariant.secondary:
        backgroundColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
        textColor = isDark ? AppTheme.darkForeground : AppTheme.lightForeground;
        break;
      case BadgeVariant.destructive:
        backgroundColor = const Color(0xFFEF4444);
        textColor = Colors.white;
        break;
      case BadgeVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = isDark ? AppTheme.darkForeground : AppTheme.lightForeground;
        borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        break;
      case BadgeVariant.success:
        backgroundColor = isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7);
        textColor = isDark ? const Color(0xFF34D399) : const Color(0xFF166534);
        break;
      case BadgeVariant.warning:
        backgroundColor = isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7);
        textColor = isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309);
        break;
      case BadgeVariant.default_:
        backgroundColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
        textColor = isDark ? AppTheme.darkForeground : AppTheme.lightForeground;
        break;
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9999),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: textStyle ?? TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge with predefined colors
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    BadgeVariant variant;
    
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
      case 'completed':
      case 'paid':
      case 'received':
        variant = BadgeVariant.success;
        break;
      case 'pending':
      case 'draft':
      case 'planning':
        variant = BadgeVariant.warning;
        break;
      case 'rejected':
      case 'cancelled':
      case 'failed':
        variant = BadgeVariant.destructive;
        break;
      case 'in progress':
      case 'submitted':
        variant = BadgeVariant.primary;
        break;
      default:
        variant = BadgeVariant.secondary;
    }

    return MadBadge(text: status, variant: variant);
  }
}
