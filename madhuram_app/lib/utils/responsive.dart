import 'package:flutter/material.dart';

/// Responsive breakpoints matching common standards
class Breakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double wide = 1280;
  static const double ultraWide = 1536;
}

/// Device type enum
enum DeviceType { mobile, tablet, desktop }

/// Responsive helper class
class Responsive {
  final BuildContext context;
  late final double screenWidth;
  late final double screenHeight;
  late final DeviceType deviceType;
  late final bool isMobile;
  late final bool isTablet;
  late final bool isDesktop;
  late final bool isPortrait;
  late final bool isLandscape;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    screenWidth = size.width;
    screenHeight = size.height;
    isPortrait = size.height > size.width;
    isLandscape = !isPortrait;
    
    if (screenWidth < Breakpoints.tablet) {
      deviceType = DeviceType.mobile;
      isMobile = true;
      isTablet = false;
      isDesktop = false;
    } else if (screenWidth < Breakpoints.desktop) {
      deviceType = DeviceType.tablet;
      isMobile = false;
      isTablet = true;
      isDesktop = false;
    } else {
      deviceType = DeviceType.desktop;
      isMobile = false;
      isTablet = false;
      isDesktop = true;
    }
  }

  /// Get value based on screen size
  T value<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Grid columns based on screen size
  int get gridColumns {
    if (screenWidth < Breakpoints.mobile) return 1;
    if (screenWidth < Breakpoints.tablet) return 2;
    if (screenWidth < Breakpoints.desktop) return 3;
    if (screenWidth < Breakpoints.wide) return 4;
    return 5;
  }

  /// Responsive padding
  EdgeInsets get padding {
    return EdgeInsets.all(value(mobile: 16, tablet: 24, desktop: 32));
  }

  /// Responsive horizontal padding
  EdgeInsets get horizontalPadding {
    return EdgeInsets.symmetric(
      horizontal: value(mobile: 16, tablet: 24, desktop: 32),
    );
  }

  /// Responsive spacing
  double get spacing {
    return value(mobile: 12, tablet: 16, desktop: 24);
  }

  /// Dialog max width based on content type
  double dialogWidth({bool large = false}) {
    if (isMobile) return screenWidth * 0.95;
    if (isTablet) return large ? 600 : 450;
    return large ? 700 : 500;
  }

  /// Whether to use full screen dialogs
  bool get useFullScreenDialogs => isMobile;
}

/// Extension for easy responsive access
extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive(this);
  
  bool get isMobile => responsive.isMobile;
  bool get isTablet => responsive.isTablet;
  bool get isDesktop => responsive.isDesktop;
  double get screenWidth => responsive.screenWidth;
  double get screenHeight => responsive.screenHeight;
}

/// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, Responsive responsive) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive(context));
  }
}

/// Responsive layout that shows different widgets based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        switch (responsive.deviceType) {
          case DeviceType.mobile:
            return mobile;
          case DeviceType.tablet:
            return tablet ?? mobile;
          case DeviceType.desktop:
            return desktop ?? tablet ?? mobile;
        }
      },
    );
  }
}

/// Responsive grid view
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double spacing;
  final double runSpacing;
  final double? childAspectRatio;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.spacing = 16,
    this.runSpacing = 16,
    this.childAspectRatio,
    this.shrinkWrap = true,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        final columns = responsive.value(
          mobile: mobileColumns ?? 1,
          tablet: tabletColumns ?? 2,
          desktop: desktopColumns ?? 3,
        );

        // Calculate aspect ratio based on available width
        final double aspectRatio = childAspectRatio ?? 
            responsive.value(mobile: 1.2, tablet: 1.3, desktop: 1.4);

        return GridView.count(
          shrinkWrap: shrinkWrap,
          physics: physics ?? const NeverScrollableScrollPhysics(),
          padding: padding,
          crossAxisCount: columns,
          crossAxisSpacing: spacing,
          mainAxisSpacing: runSpacing,
          childAspectRatio: aspectRatio,
          children: children,
        );
      },
    );
  }
}

/// Responsive wrap for horizontal layouts that should wrap on mobile
class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAlignment;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.alignment = WrapAlignment.start,
    this.crossAlignment = WrapCrossAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        if (responsive.isMobile) {
          return Wrap(
            spacing: spacing,
            runSpacing: runSpacing,
            alignment: alignment,
            crossAxisAlignment: crossAlignment,
            children: children,
          );
        }
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: children.map((child) {
            final index = children.indexOf(child);
            if (index == children.length - 1) return child;
            return Padding(
              padding: EdgeInsets.only(right: spacing),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

/// Responsive row/column - shows as row on desktop, column on mobile
class ResponsiveRowColumn extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool reverseOnMobile;

  const ResponsiveRowColumn({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 16,
    this.reverseOnMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveBuilder(
      builder: (context, responsive) {
        final items = reverseOnMobile && responsive.isMobile 
            ? children.reversed.toList() 
            : children;
        
        if (responsive.isMobile) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: items.map((child) {
              final index = items.indexOf(child);
              if (index == items.length - 1) return child;
              return Padding(
                padding: EdgeInsets.only(bottom: spacing),
                child: child,
              );
            }).toList(),
          );
        }
        
        return Row(
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: items.map((child) {
            final index = items.indexOf(child);
            if (index == items.length - 1) return child;
            return Padding(
              padding: EdgeInsets.only(right: spacing),
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}
