import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive.dart';
import 'mad_button.dart';

/// Dialog component matching shadcn/ui Dialog - Responsive version
class MadDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? content;
  final List<Widget>? actions;
  final double? maxWidth;
  final EdgeInsetsGeometry? contentPadding;
  final bool showCloseButton;
  final bool useFullScreen;

  const MadDialog({
    super.key,
    this.title,
    this.description,
    this.content,
    this.actions,
    this.maxWidth,
    this.contentPadding,
    this.showCloseButton = true,
    this.useFullScreen = false,
  });

  /// Show a dialog
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? description,
    Widget? content,
    List<Widget>? actions,
    double? maxWidth,
    bool barrierDismissible = true,
    bool showCloseButton = true,
    bool? useFullScreen,
  }) {
    final responsive = Responsive(context);
    final shouldUseFullScreen = useFullScreen ?? responsive.isMobile;

    if (shouldUseFullScreen) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => _FullScreenDialog(
            title: title,
            description: description,
            content: content,
            actions: actions,
            showCloseButton: showCloseButton,
          ),
        ),
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => MadDialog(
        title: title,
        description: description,
        content: content,
        actions: actions,
        maxWidth: maxWidth,
        showCloseButton: showCloseButton,
      ),
    );
  }

  /// Show a confirmation dialog
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    String? description,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    bool destructive = false,
  }) async {
    final responsive = Responsive(context);

    if (responsive.isMobile) {
      final result = await showModalBottomSheet<bool>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => _ConfirmBottomSheet(
          title: title,
          description: description,
          confirmText: confirmText,
          cancelText: cancelText,
          destructive: destructive,
        ),
      );
      return result ?? false;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MadDialog(
        title: title,
        description: description,
        showCloseButton: false,
        actions: [
          MadButton(
            text: cancelText,
            variant: ButtonVariant.outline,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          MadButton(
            text: confirmText,
            variant: destructive ? ButtonVariant.destructive : ButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Show an alert dialog
  static Future<void> alert({
    required BuildContext context,
    required String title,
    String? description,
    String buttonText = 'OK',
  }) {
    final responsive = Responsive(context);

    if (responsive.isMobile) {
      return showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppTheme.darkMutedForeground
                            : AppTheme.lightMutedForeground,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  MadButton(
                    text: buttonText,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return showDialog(
      context: context,
      builder: (context) => MadDialog(
        title: title,
        description: description,
        showCloseButton: false,
        actions: [
          MadButton(
            text: buttonText,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsive = Responsive(context);
    final effectiveMaxWidth = maxWidth ?? responsive.dialogWidth();
    final constrainedMaxWidth = effectiveMaxWidth > responsive.screenWidth * 0.9
        ? responsive.screenWidth * 0.9
        : effectiveMaxWidth;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constrainedMaxWidth,
          minWidth: 280,
        ),
        child: Padding(
          padding: contentPadding ?? EdgeInsets.all(responsive.value(mobile: 20, tablet: 22, desktop: 24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              if (title != null || showCloseButton)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title != null)
                            Text(
                              title!,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: responsive.value(mobile: 18, tablet: 19, desktop: 20),
                              ),
                            ),
                          if (description != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              description!,
                              style: TextStyle(
                                fontSize: responsive.value(mobile: 13, tablet: 13, desktop: 14),
                                color: isDark
                                    ? AppTheme.darkMutedForeground
                                    : AppTheme.lightMutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (showCloseButton)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                  ],
                ),

              // Content
              if (content != null) ...[
                const SizedBox(height: 16),
                content!,
              ],

              // Actions
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: actions!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-screen dialog for mobile
class _FullScreenDialog extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? content;
  final List<Widget>? actions;
  final bool showCloseButton;

  const _FullScreenDialog({
    this.title,
    this.description,
    this.content,
    this.actions,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        elevation: 0,
        leading: showCloseButton
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: title != null
            ? Text(
                title!,
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (description != null) ...[
                      Text(
                        description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppTheme.darkMutedForeground
                              : AppTheme.lightMutedForeground,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (content != null) content!,
                  ],
                ),
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: actions!
                      .map((action) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: action,
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Confirmation bottom sheet for mobile
class _ConfirmBottomSheet extends StatelessWidget {
  final String title;
  final String? description;
  final String confirmText;
  final String cancelText;
  final bool destructive;

  const _ConfirmBottomSheet({
    required this.title,
    this.description,
    required this.confirmText,
    required this.cancelText,
    required this.destructive,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? AppTheme.darkMutedForeground
                      : AppTheme.lightMutedForeground,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: MadButton(
                    text: cancelText,
                    variant: ButtonVariant.outline,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MadButton(
                    text: confirmText,
                    variant: destructive ? ButtonVariant.destructive : ButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen dialog for forms - Responsive version
class MadFormDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool loading;
  final double? maxWidth;

  const MadFormDialog({
    super.key,
    required this.title,
    required this.content,
    this.actions,
    this.loading = false,
    this.maxWidth,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    List<Widget>? actions,
    bool loading = false,
    double? maxWidth,
  }) {
    final responsive = Responsive(context);

    // Use full screen on mobile
    if (responsive.isMobile) {
      return Navigator.of(context).push<T>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => _FullScreenFormDialog(
            title: title,
            content: content,
            actions: actions,
            loading: loading,
          ),
        ),
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (context) => MadFormDialog(
        title: title,
        content: content,
        actions: actions,
        loading: loading,
        maxWidth: maxWidth,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final responsive = Responsive(context);
    final effectiveMaxWidth = maxWidth ?? responsive.dialogWidth(large: true);
    final constrainedMaxWidth = effectiveMaxWidth > responsive.screenWidth * 0.9
        ? responsive.screenWidth * 0.9
        : effectiveMaxWidth;

    return Dialog(
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: constrainedMaxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    onPressed: loading ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: content,
              ),
            ),

            // Footer with actions
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!
                      .map((action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen form dialog for mobile
class _FullScreenFormDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget>? actions;
  final bool loading;

  const _FullScreenFormDialog({
    required this.title,
    required this.content,
    this.actions,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: loading ? null : () => Navigator.of(context).pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: content,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkCard : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
                    ),
                  ),
                ),
                child: Row(
                  children: actions!
                      .map((action) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: action,
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
