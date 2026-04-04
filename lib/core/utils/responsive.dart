import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BREAKPOINTS
// ─────────────────────────────────────────────────────────────────────────────
enum ScreenSize { mobile, tablet, desktop }

class Responsive {
  Responsive._();

  // Breakpoint thresholds
  static const double mobileMax = 599;
  static const double tabletMax = 1024;

  // Web content max widths
  static const double contentMaxWidth = 1200.0;
  static const double formMaxWidth = 480.0;
  static const double cardMaxWidth = 600.0;

  // 8-pt spacing grid
  static const double sp1 = 4.0;
  static const double sp2 = 8.0;
  static const double sp3 = 12.0;
  static const double sp4 = 16.0;
  static const double sp5 = 20.0;
  static const double sp6 = 24.0;
  static const double sp8 = 32.0;
  static const double sp10 = 40.0;
  static const double sp12 = 48.0;

  // ── Screen size helpers ──────────────────────────────────────────────────

  static ScreenSize sizeOf(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w <= mobileMax) return ScreenSize.mobile;
    if (w <= tabletMax) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      sizeOf(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) =>
      sizeOf(context) == ScreenSize.tablet;

  static bool isDesktop(BuildContext context) =>
      sizeOf(context) == ScreenSize.desktop;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width > mobileMax;

  // ── Adaptive value selector ──────────────────────────────────────────────

  /// Returns one of three values depending on current screen size.
  static T adaptive<T>(
    BuildContext context, {
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    switch (sizeOf(context)) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }

  // ── Spacing ───────────────────────────────────────────────────────────────

  /// Horizontal page padding – grows on wider screens.
  static EdgeInsets pagePadding(BuildContext context) => adaptive(
        context,
        mobile: const EdgeInsets.symmetric(horizontal: sp5, vertical: sp4),
        tablet: const EdgeInsets.symmetric(horizontal: sp8, vertical: sp5),
        desktop: const EdgeInsets.symmetric(horizontal: sp10, vertical: sp6),
      );

  /// Horizontal padding value only.
  static double horizontalPadding(BuildContext context) => adaptive(
        context,
        mobile: sp5,
        tablet: sp8,
        desktop: sp10,
      );

  // ── Grid columns ─────────────────────────────────────────────────────────

  static int gridColumns(BuildContext context) => adaptive(
        context,
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );

  static int authGridColumns(BuildContext context) => adaptive(
        context,
        mobile: 1,
        tablet: 2,
        desktop: 3,
      );

  // ── Typography scale ─────────────────────────────────────────────────────

  static double headlineFontSize(BuildContext context) => adaptive(
        context,
        mobile: 24.0,
        tablet: 28.0,
        desktop: 32.0,
      );

  static double titleFontSize(BuildContext context) => adaptive(
        context,
        mobile: 18.0,
        tablet: 20.0,
        desktop: 22.0,
      );

  static double bodyFontSize(BuildContext context) => adaptive(
        context,
        mobile: 14.0,
        tablet: 15.0,
        desktop: 16.0,
      );

  // ── FAB offset ───────────────────────────────────────────────────────────

  static EdgeInsets fabPadding(BuildContext context) {
    return isWide(context)
        ? const EdgeInsets.only(bottom: 24)
        : const EdgeInsets.only(bottom: 90);
  }

  // ── List bottom padding (clears nav bar) ─────────────────────────────────

  static EdgeInsets listPadding(BuildContext context) => EdgeInsets.fromLTRB(
        horizontalPadding(context),
        0,
        horizontalPadding(context),
        isWide(context) ? sp6 : 120,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE BUILDER WIDGET
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience widget – builds one of three layouts based on screen width.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context) mobile;
  final Widget Function(BuildContext context)? tablet;
  final Widget Function(BuildContext context) desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final w = constraints.maxWidth;
        if (w > Responsive.tabletMax) return desktop(ctx);
        if (w > Responsive.mobileMax) return (tablet ?? desktop)(ctx);
        return mobile(ctx);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CENTERED WEB CONTENT WRAPPER
// ─────────────────────────────────────────────────────────────────────────────

/// Constrains content to [maxWidth] and centres it – used on tablet/desktop.
class WebContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const WebContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = Responsive.contentMaxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RESPONSIVE GRID
// ─────────────────────────────────────────────────────────────────────────────

/// A grid that automatically switches column count based on screen width.
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double mobileItemExtent;
  final double tabletItemExtent;
  final double desktopItemExtent;
  final EdgeInsets? padding;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileItemExtent = 120,
    this.tabletItemExtent = 150,
    this.desktopItemExtent = 160,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final size = Responsive.sizeOf(context);
    final cols = Responsive.gridColumns(context);
    final extent = size == ScreenSize.mobile
        ? mobileItemExtent
        : size == ScreenSize.tablet
            ? tabletItemExtent
            : desktopItemExtent;

    return GridView.builder(
      padding: padding ?? Responsive.listPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisExtent: extent,
        crossAxisSpacing: Responsive.sp3,
        mainAxisSpacing: Responsive.sp3,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }
}
