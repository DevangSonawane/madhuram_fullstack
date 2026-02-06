import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Switch component matching shadcn/ui Switch
class MadSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;
  final bool disabled;
  final SwitchSize size;

  const MadSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
    this.disabled = false,
    this.size = SwitchSize.md,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    double trackWidth;
    double trackHeight;
    double thumbSize;

    switch (size) {
      case SwitchSize.sm:
        trackWidth = 36;
        trackHeight = 20;
        thumbSize = 16;
        break;
      case SwitchSize.lg:
        trackWidth = 52;
        trackHeight = 28;
        thumbSize = 24;
        break;
      case SwitchSize.md:
        trackWidth = 44;
        trackHeight = 24;
        thumbSize = 20;
    }

    final switchWidget = GestureDetector(
      onTap: disabled ? null : () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: trackWidth,
        height: trackHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(trackHeight / 2),
          color: value
              ? (disabled ? AppTheme.primaryColor.withOpacity(0.5) : AppTheme.primaryColor)
              : (isDark ? AppTheme.darkMuted : AppTheme.lightMuted),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (label == null && description == null) {
      return switchWidget;
    }

    return InkWell(
      onTap: disabled ? null : () => onChanged?.call(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            switchWidget,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: disabled
                            ? (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)
                            : (isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
                      ),
                    ),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum SwitchSize { sm, md, lg }

/// Switch with label on the left
class MadLabeledSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final bool disabled;

  const MadLabeledSwitch({
    super.key,
    required this.value,
    this.onChanged,
    required this.label,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: disabled ? null : () => onChanged?.call(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: disabled
                    ? (isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground)
                    : (isDark ? AppTheme.darkForeground : AppTheme.lightForeground),
              ),
            ),
            MadSwitch(
              value: value,
              onChanged: onChanged,
              disabled: disabled,
            ),
          ],
        ),
      ),
    );
  }
}
