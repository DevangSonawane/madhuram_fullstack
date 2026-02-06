import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../theme/app_theme.dart';

/// Skeleton loading component matching shadcn/ui Skeleton
class MadSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final bool circle;

  const MadSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.circle = false,
  });

  /// Create a text skeleton
  factory MadSkeleton.text({
    double width = 200,
    double height = 16,
    double borderRadius = 4,
  }) {
    return MadSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  /// Create a circular skeleton (avatar)
  factory MadSkeleton.circle({double size = 40}) {
    return MadSkeleton(
      width: size,
      height: size,
      circle: true,
    );
  }

  /// Create a rectangular skeleton (card, image)
  factory MadSkeleton.rect({
    double? width,
    double height = 100,
    double borderRadius = 8,
  }) {
    return MadSkeleton(
      width: width,
      height: height,
      borderRadius: borderRadius,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseColor = isDark
        ? AppTheme.darkMuted.withOpacity(0.5)
        : AppTheme.lightMuted.withOpacity(0.5);
    final highlightColor = isDark
        ? AppTheme.darkMuted
        : AppTheme.lightMuted;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: circle ? null : BorderRadius.circular(borderRadius),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}

/// Skeleton for table rows
class MadTableSkeleton extends StatelessWidget {
  final int rows;
  final int columns;
  final double rowHeight;
  final double columnSpacing;

  const MadTableSkeleton({
    super.key,
    this.rows = 5,
    this.columns = 4,
    this.rowHeight = 48,
    this.columnSpacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Container(
          height: rowHeight,
          padding: EdgeInsets.symmetric(horizontal: columnSpacing),
          child: Row(
            children: List.generate(columns, (colIndex) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: colIndex < columns - 1 ? columnSpacing : 0),
                  child: MadSkeleton.text(
                    width: double.infinity,
                    height: 16,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

/// Skeleton for cards
class MadCardSkeleton extends StatelessWidget {
  final double? width;
  final double height;
  final bool showAvatar;
  final bool showImage;
  final int textLines;

  const MadCardSkeleton({
    super.key,
    this.width,
    this.height = 200,
    this.showAvatar = false,
    this.showImage = true,
    this.textLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showImage)
            MadSkeleton.rect(
              width: double.infinity,
              height: 120,
              borderRadius: 0,
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAvatar)
                  Row(
                    children: [
                      MadSkeleton.circle(size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            MadSkeleton.text(width: 120, height: 14),
                            const SizedBox(height: 4),
                            MadSkeleton.text(width: 80, height: 12),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  MadSkeleton.text(width: 150, height: 18),
                const SizedBox(height: 12),
                ...List.generate(textLines, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MadSkeleton.text(
                      width: index == textLines - 1 ? 200 : double.infinity,
                      height: 14,
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for list items
class MadListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool showAvatar;
  final bool showAction;

  const MadListSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 72,
    this.showAvatar = true,
    this.showAction = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(itemCount, (index) {
        return Container(
          height: itemHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (showAvatar) ...[
                MadSkeleton.circle(size: 40),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MadSkeleton.text(width: 180, height: 16),
                    const SizedBox(height: 8),
                    MadSkeleton.text(width: 120, height: 12),
                  ],
                ),
              ),
              if (showAction)
                MadSkeleton.rect(width: 60, height: 32, borderRadius: 6),
            ],
          ),
        );
      }),
    );
  }
}

/// Skeleton for stat cards
class MadStatCardSkeleton extends StatelessWidget {
  const MadStatCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? AppTheme.darkBorder : AppTheme.lightBorder).withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MadSkeleton.text(width: 100, height: 14),
              MadSkeleton.circle(size: 24),
            ],
          ),
          const SizedBox(height: 16),
          MadSkeleton.text(width: 80, height: 28),
          const SizedBox(height: 8),
          MadSkeleton.text(width: 120, height: 12),
        ],
      ),
    );
  }
}
