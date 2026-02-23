import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/currency_text.dart';
import '../providers/analytics_state.dart';

class AnalyticsSummaryCard extends StatelessWidget {
  const AnalyticsSummaryCard({
    super.key,
    required this.current,
    required this.previous,
  });

  final MonthSummary current;
  final MonthSummary? previous;

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final innerPad   = context.widthFraction(0.04).clamp(12.0, 24.0);
    final vGapSm     = context.heightFraction(0.006).clamp(3.0, 6.0);
    final vGapMd     = context.heightFraction(0.012).clamp(6.0, 12.0);

    final headlineFontSize =
        context.widthFraction(0.07).clamp(24.0, 36.0);

    final percentUsed = current.totalBudget > 0
        ? (current.totalSpent / current.totalBudget * 100)
            .clamp(0, 999)
            .toStringAsFixed(1)
        : '—';

    final delta = previous != null && previous!.totalSpent > 0
        ? current.totalSpent - previous!.totalSpent
        : null;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat.yMMMM().format(current.month),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            SizedBox(height: vGapSm),
            CurrencyText(
              current.totalSpent,
              style: TextStyle(
                fontSize: headlineFontSize,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: vGapSm),
            Text(
              current.totalBudget > 0
                  ? '$percentUsed% of \$${current.totalBudget.toStringAsFixed(2)} budget used'
                  : 'No budget set for this month',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (delta != null) ...[
              SizedBox(height: vGapMd),
              _DeltaBadge(
                delta: delta,
                iconSize: context.widthFraction(0.035).clamp(12.0, 16.0),
                fontSize: context.widthFraction(0.028).clamp(10.0, 12.0),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DeltaBadge extends StatelessWidget {
  const _DeltaBadge({
    required this.delta,
    required this.iconSize,
    required this.fontSize,
  });

  final double delta;
  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final isUp   = delta > 0;
    final color  = isUp ? AppColors.error : AppColors.success;
    final icon   = isUp
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final prefix = isUp ? '+' : '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: color),
        SizedBox(width: context.widthFraction(0.01).clamp(2.0, 4.0)),
        Text(
          '$prefix\$${delta.abs().toStringAsFixed(2)} vs last month',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: fontSize,
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}