import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../theme/app_theme.dart';
import 'mad_card.dart';

/// Dashboard stat card - Responsive and adaptive version
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final double? change;
  final String? subtitle;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.change,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isPositive = change != null && change! > 0;
    final isNegative = change != null && change! < 0;

    return MadCard(
      onTap: onTap,
      hoverable: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Adapt padding and sizes based on available space
          final isNarrowWidth = constraints.maxWidth < 150;
          final isVeryNarrowWidth = constraints.maxWidth < 120;
          final isShortHeight = constraints.maxHeight < 120;
          final isVeryShortHeight = constraints.maxHeight < 100;
          
          final padding = isVeryNarrowWidth || isVeryShortHeight ? 8.0 : 
                         (isNarrowWidth || isShortHeight ? 10.0 : 14.0);
          final iconSize = isVeryNarrowWidth || isVeryShortHeight ? 24.0 : 
                          (isNarrowWidth || isShortHeight ? 28.0 : 32.0);
          final iconInnerSize = isVeryNarrowWidth || isVeryShortHeight ? 12.0 : 
                               (isNarrowWidth || isShortHeight ? 14.0 : 16.0);
          final titleSize = isVeryShortHeight ? 8.0 : (isShortHeight ? 9.0 : 10.0);
          final valueSize = isVeryShortHeight ? 16.0 : (isShortHeight ? 18.0 : 22.0);
          final showIcon = !isVeryNarrowWidth && !isVeryShortHeight;
          final showSubtitle = !isVeryShortHeight;

          return Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header row with title and icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (icon != null && showIcon)
                      Container(
                        width: iconSize,
                        height: iconSize,
                        decoration: BoxDecoration(
                          color: iconBackgroundColor ?? (iconColor ?? AppTheme.primaryColor).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(child: Icon(icon, color: iconColor ?? AppTheme.primaryColor, size: iconInnerSize)),
                      ),
                  ],
                ),
                // Value - use Flexible to prevent overflow
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: valueSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                // Change indicator and subtitle
                if ((change != null || subtitle != null) && showSubtitle)
                  _buildChangeRow(isDark, isPositive, isNegative, isNarrowWidth || isShortHeight)
                else
                  const SizedBox.shrink(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildChangeRow(bool isDark, bool isPositive, bool isNegative, bool isCompact) {
    final fontSize = isCompact ? 8.0 : 9.0;
    final iconSize = isCompact ? 8.0 : 10.0;

    return Row(
      children: [
        if (change != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 2 : 3, vertical: 1),
            decoration: BoxDecoration(
              color: isPositive
                  ? (isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7))
                  : isNegative
                      ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
                  size: iconSize,
                  color: isPositive
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF166534))
                      : (isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B)),
                ),
                const SizedBox(width: 1),
                Text(
                  '${change!.abs()}%',
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w500,
                    color: isPositive
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF166534))
                        : (isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B)),
                  ),
                ),
              ],
            ),
          ),
        if (change != null && subtitle != null)
          const SizedBox(width: 4),
        if (subtitle != null)
          Expanded(
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}
