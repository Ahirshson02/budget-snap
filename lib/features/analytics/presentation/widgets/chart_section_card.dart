import 'package:flutter/material.dart';

import '../../../../core/utils/responsive.dart';

class ChartSectionCard extends StatelessWidget {
  const ChartSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final innerPad = context.widthFraction(0.04).clamp(12.0, 24.0);
    final vGapSm   = context.heightFraction(0.005).clamp(2.0, 5.0);
    final vGapMd   = context.heightFraction(0.018).clamp(10.0, 20.0);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: vGapSm),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
            SizedBox(height: vGapMd),
            child,
          ],
        ),
      ),
    );
  }
}