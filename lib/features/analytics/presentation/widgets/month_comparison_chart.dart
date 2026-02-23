import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../providers/analytics_state.dart';

class MonthComparisonChart extends StatelessWidget {
  const MonthComparisonChart({
    super.key,
    required this.current,
    required this.previous,
  });

  final MonthSummary current;
  final MonthSummary? previous;

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final chartHeight  = context.heightFraction(0.28).clamp(160.0, 240.0);
    final barWidth     = context.widthFraction(0.14).clamp(32.0, 60.0);
    final axisFontSize = context.widthFraction(0.025).clamp(9.0, 12.0);
    final labelFontSize = context.widthFraction(0.030).clamp(10.0, 13.0);
    final leftReserved = context.widthFraction(0.12).clamp(36.0, 52.0);
    final cornerRadius = Radius.circular(barWidth * 0.12);

    final currentAmount  = current.totalSpent;
    final previousAmount = previous?.totalSpent ?? 0;

    final maxY = ([
              currentAmount,
              previousAmount,
              current.totalBudget,
              previous?.totalBudget ?? 0,
            ].fold(0.0, (max, v) => v > max ? v : max) *
            1.25)
        .ceilToDouble();
    final yMax      = maxY <= 0 ? 100.0 : maxY;
    final yInterval = (yMax / 4).ceilToDouble();

    final monthFmt      = DateFormat.MMM();
    final currentLabel  = monthFmt.format(current.month);
    final previousLabel = previous != null
        ? monthFmt.format(previous!.month)
        : 'Prev';

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          alignment: BarChartAlignment.spaceEvenly,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label =
                    groupIndex == 0 ? currentLabel : previousLabel;
                return BarTooltipItem(
                  '$label\n\$${rod.toY.toStringAsFixed(2)}',
                  TextStyle(
                    color: Colors.white,
                    fontSize: axisFontSize,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize:
                    context.heightFraction(0.04).clamp(24.0, 36.0),
                getTitlesWidget: (value, meta) {
                  final label =
                      value.toInt() == 0 ? currentLabel : previousLabel;
                  return Padding(
                    padding: EdgeInsets.only(
                      top: context.heightFraction(0.006).clamp(3.0, 6.0),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: leftReserved,
                interval: yInterval,
                getTitlesWidget: (value, meta) => Text(
                  '\$${value.toInt()}',
                  style: TextStyle(
                    fontSize: axisFontSize,
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(
              color: theme.colorScheme.outlineVariant,
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: [
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: currentAmount,
                  width: barWidth,
                  color: AppColors.primary,
                  borderRadius: BorderRadius.vertical(top: cornerRadius),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: current.totalBudget > 0,
                    toY: current.totalBudget,
                    color: AppColors.primary.withOpacity(0.12),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: previousAmount,
                  width: barWidth,
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.vertical(top: cornerRadius),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: (previous?.totalBudget ?? 0) > 0,
                    toY: previous?.totalBudget ?? 0,
                    color: AppColors.secondary.withOpacity(0.12),
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