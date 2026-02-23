import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

/// The pill-shaped drag handle shown at the top of every bottom sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        // Width is a fraction of screen width, clamped to a sensible range
        width: context.widthFraction(0.1).clamp(32.0, 48.0),
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
    );
  }
}