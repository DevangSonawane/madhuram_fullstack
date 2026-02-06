import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Checkbox component matching shadcn/ui Checkbox
class MadCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final String? label;
  final String? description;
  final bool disabled;
  final bool error;

  const MadCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.description,
    this.disabled = false,
    this.error = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: disabled ? null : () => onChanged?.call(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value
                  ? AppTheme.primaryColor
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: error
                    ? AppTheme.lightDestructive
                    : value
                        ? AppTheme.primaryColor
                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                width: 1.5,
              ),
            ),
            child: value
                ? const Icon(
                    Icons.check,
                    size: 14,
                    color: Colors.white,
                  )
                : null,
          ),
          if (label != null || description != null) ...[
            const SizedBox(width: 10),
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
        ],
      ),
    );
  }
}

/// Checkbox group
class MadCheckboxGroup<T> extends StatelessWidget {
  final List<MadCheckboxOption<T>> options;
  final Set<T> values;
  final ValueChanged<Set<T>>? onChanged;
  final String? label;
  final bool disabled;
  final Axis direction;
  final double spacing;

  const MadCheckboxGroup({
    super.key,
    required this.options,
    required this.values,
    this.onChanged,
    this.label,
    this.disabled = false,
    this.direction = Axis.vertical,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final children = options.map((option) {
      final isChecked = values.contains(option.value);
      return MadCheckbox(
        value: isChecked,
        label: option.label,
        description: option.description,
        disabled: disabled || option.disabled,
        onChanged: (checked) {
          final newValues = Set<T>.from(values);
          if (checked) {
            newValues.add(option.value);
          } else {
            newValues.remove(option.value);
          }
          onChanged?.call(newValues);
        },
      );
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
            ),
          ),
          const SizedBox(height: 12),
        ],
        direction == Axis.vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children
                    .map((child) => Padding(
                          padding: EdgeInsets.only(bottom: spacing),
                          child: child,
                        ))
                    .toList(),
              )
            : Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: children,
              ),
      ],
    );
  }
}

/// Option for checkbox group
class MadCheckboxOption<T> {
  final T value;
  final String label;
  final String? description;
  final bool disabled;

  const MadCheckboxOption({
    required this.value,
    required this.label,
    this.description,
    this.disabled = false,
  });
}
