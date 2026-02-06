import 'package:flutter/material.dart';

/// Card component matching shadcn/ui Card
class MadCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool hoverable;

  const MadCard({
    super.key,
    this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
    this.onTap,
    this.hoverable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? theme.cardTheme.color,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: padding != null
              ? Padding(padding: padding!, child: child)
              : child,
        ),
      ),
    );

    if (onTap != null || hoverable) {
      card = MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Card header matching shadcn/ui CardHeader
class MadCardHeader extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final Widget? action;
  final EdgeInsetsGeometry? padding;

  const MadCardHeader({
    super.key,
    this.title,
    this.subtitle,
    this.action,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) title!,
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  subtitle!,
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Card content matching shadcn/ui CardContent
class MadCardContent extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const MadCardContent({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: child,
    );
  }
}

/// Card footer matching shadcn/ui CardFooter
class MadCardFooter extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const MadCardFooter({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
          ),
        ),
      ),
      padding: padding ?? const EdgeInsets.all(24),
      child: child,
    );
  }
}

/// Title widget for card
class MadCardTitle extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MadCardTitle(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.titleLarge,
    );
  }
}

/// Description widget for card
class MadCardDescription extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MadCardDescription(this.text, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: style ?? Theme.of(context).textTheme.bodySmall,
    );
  }
}
