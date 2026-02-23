import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../models/chart_data.dart';

class CategoryBarChart extends StatelessWidget {
  const CategoryBarChart({
    super.key,
    required this.bars,
  });

  final List<CategoryBarData> bars;

  @override
  Widget build(BuildContext context) {
    if (bars.isEmpty) {
      return Center(
        child: Text(
          'No category data available.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
        ),
      );
    }

    // All sizing derived from screen dimensions
    final chartHeight = context.heightFraction(0.30).clamp(180.0, 280.0);
    final axisFontSize = context.widthFraction(0.025).clamp(9.0, 11.0);
    final leftReserved = context.widthFraction(0.12).clamp(36.0, 52.0);

    // Bar width scales down the more categories there are
    final barWidth = (context.widthFraction(0.06) / bars.length.clamp(1, 8))
        .clamp(8.0, 22.0);

    final maxY = bars
        .expand((b) => [b.spent, b.allocated])
        .fold(0.0, (prev, v) => v > prev ? v : prev);
    final yMax = maxY <= 0 ? 100.0 : (maxY * 1.25).ceilToDouble();
    final yInterval = (yMax / 4).ceilToDouble();

    final theme = Theme.of(context);

    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          maxY: yMax,
          alignment: BarChartAlignment.spaceAround,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final bar   = bars[groupIndex];
                final label = rodIndex == 0 ? 'Spent' : 'Allocated';
                final value = rodIndex == 0 ? bar.spent : bar.allocated;
                return BarTooltipItem(
                  '$label\n\$${value.toStringAsFixed(2)}',
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
                    context.heightFraction(0.045).clamp(28.0, 40.0),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= bars.length) {
                    return const SizedBox.shrink();
                  }
                  final label = bars[index].label;
                  final display =
                      label.length > 6 ? '${label.substring(0, 6)}…' : label;
                  return Padding(
                    padding: EdgeInsets.only(
                      top: context.heightFraction(0.006).clamp(3.0, 6.0),
                    ),
                    child: Text(
                      display,
                      style: TextStyle(
                        fontSize: axisFontSize,
                        color: theme.colorScheme.outline,
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
          barGroups: List.generate(bars.length, (i) {
            final bar   = bars[i];
            final color =
                AppColors.chartPalette[i % AppColors.chartPalette.length];
            // Corner radius scales with bar width
            final cornerRadius = Radius.circular(barWidth * 0.4);

            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: bar.spent,
                  color: color,
                  width: barWidth,
                  borderRadius:
                      BorderRadius.vertical(top: cornerRadius),
                ),
                BarChartRodData(
                  toY: bar.allocated,
                  color: color.withOpacity(0.25),
                  width: barWidth,
                  borderRadius:
                      BorderRadius.vertical(top: cornerRadius),
                  borderSide: BorderSide(color: color.withOpacity(0.5)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}