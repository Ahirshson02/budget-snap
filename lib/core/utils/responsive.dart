import 'package:flutter/material.dart';

/// Centralized responsive sizing utilities.
///
/// Every dimension in the app should derive from these helpers
/// rather than from hardcoded constants. This ensures the layout
/// adapts correctly across phones, tablets, and varying font scales.
extension ResponsiveContext on BuildContext {
  /// Full screen width via MediaQuery.
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Full screen height via MediaQuery.
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Horizontal padding that scales with screen width.
  /// Phones get 4% each side, tablets get 8%.
  double get horizontalPadding =>
      screenWidth < 600 ? screenWidth * 0.04 : screenWidth * 0.08;

  /// A fraction of the screen height — useful for bottom sheets,
  /// cards, and containers that should feel proportional.
  double heightFraction(double fraction) => screenHeight * fraction;

  /// A fraction of the screen width.
  double widthFraction(double fraction) => screenWidth * fraction;

  /// True when the device is tablet-sized (600dp+).
  bool get isTablet => screenWidth >= 600;

  /// Safe bottom inset (home indicator / keyboard).
  double get bottomInset => MediaQuery.viewInsetsOf(this).bottom;

  /// Safe area padding.
  EdgeInsets get safePadding => MediaQuery.paddingOf(this);
}

/// Builds different layouts based on available width.
/// Drop this anywhere you need a column-vs-grid decision.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
  });

  final Widget mobile;
  final Widget? tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600 && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}