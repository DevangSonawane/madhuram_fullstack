import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Textarea component matching shadcn/ui Textarea
class MadTextarea extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool readOnly;
  final int minLines;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final bool showCharacterCount;

  const MadTextarea({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.readOnly = false,
    this.minLines = 3,
    this.maxLines,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.showCharacterCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (labelText != null) ...[
          Text(
            labelText!,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          readOnly: readOnly,
          minLines: minLines,
          maxLines: maxLines ?? minLines + 2,
          maxLength: maxLength,
          onChanged: onChanged,
          onEditingComplete: onEditingComplete,
          focusNode: focusNode,
          autofocus: autofocus,
          textInputAction: textInputAction,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? AppTheme.darkForeground : AppTheme.lightForeground,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            errorText: errorText,
            counterText: showCharacterCount ? null : '',
            filled: true,
            fillColor: (isDark ? AppTheme.darkMuted : AppTheme.lightMuted).withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.lightDestructive),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.lightDestructive),
            ),
            contentPadding: const EdgeInsets.all(12),
          ),
        ),
        if (helperText != null && errorText == null) ...[
          const SizedBox(height: 4),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.darkMutedForeground : AppTheme.lightMutedForeground,
            ),
          ),
        ],
      ],
    );
  }
}
