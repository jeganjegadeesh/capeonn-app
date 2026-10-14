import 'package:flutter/material.dart';

/// Standard breakpoint widths across Capeonn.
/// - Mobile: < 600px (smartphones)
/// - Tablet: 600px - 1023px (tablets, foldables, small window mode)
/// - Desktop: 1024px - 1439px (laptops, standard desktop monitors)
/// - Wide Desktop: >= 1440px (ultra-wide monitors, 2K/4K displays)
class Breakpoints {
  const Breakpoints._();

  static const double mobileMax = 599.0;
  static const double tabletMin = 600.0;
  static const double tabletMax = 1023.0;
  static const double desktopMin = 1024.0;
  static const double wideDesktopMin = 1440.0;

  static const double maxContentWidth = 1400.0;
}

/// Convenience extensions on [BuildContext] to inspect layout breakpoints.
extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  bool get isMobile => screenWidth < Breakpoints.tabletMin;
  bool get isTablet =>
      screenWidth >= Breakpoints.tabletMin && screenWidth <= Breakpoints.tabletMax;
  bool get isDesktop => screenWidth >= Breakpoints.desktopMin;
  bool get isWideDesktop => screenWidth >= Breakpoints.wideDesktopMin;

  /// Returns true if the screen is compact (mobile or small tablet portrait).
  bool get isCompact => screenWidth < 900.0;

  /// Returns a responsive value based on current breakpoint.
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? wideDesktop,
  }) {
    if (isWideDesktop && wideDesktop != null) return wideDesktop;
    if (isDesktop && desktop != null) return desktop;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}

/// A responsive container that applies horizontal centering and max content
/// width bounding on wide screens to prevent unreadable stretching.
class ResponsiveContentContainer extends StatelessWidget {
  const ResponsiveContentContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: content,
      ),
    );
  }
}

/// A responsive builder widget that yields distinct child trees based on breakpoint.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
    this.wideDesktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;
  final WidgetBuilder? wideDesktop;

  @override
  Widget build(BuildContext context) {
    if (context.isWideDesktop && wideDesktop != null) {
      return wideDesktop!(context);
    }
    if (context.isDesktop && desktop != null) {
      return desktop!(context);
    }
    if (context.isTablet && tablet != null) {
      return tablet!(context);
    }
    return mobile(context);
  }
}
