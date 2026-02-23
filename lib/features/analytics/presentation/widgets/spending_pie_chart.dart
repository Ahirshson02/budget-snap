import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/currency_text.dart';
import '../models/chart_data.dart';

class SpendingPieChart extends StatefulWidget {
  const SpendingPieChart({
    super.key,
    required this.slices,
    required this.totalSpent,
  });

  final List<PieSliceData> slices;
  final double totalSpent;

  @override
  State<SpendingPieChart> createState() => _SpendingPieChartState();
}

class _SpendingPieChartState extends State<SpendingPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    // Chart diameter: 55% of screen width, clamped between 160–280
    final chartSize = context.widthFraction(0.55).clamp(160.0, 280.0);

    // Center hole radius: 28% of chart size
    final centerRadius = chartSize * 0.28;

    // Unselected slice radius: 27% of chart size
    final sliceRadius = chartSize * 0.27;

    // Selected slice pops out by an extra 5%
    final selectedRadius = chartSize * 0.32;

    // Legend dot size: 1.5% of screen width
    final dotSize = context.widthFraction(0.015).clamp(8.0, 12.0);

    // Legend font size: 2.5% of screen width
    final legendFontSize = context.widthFraction(0.025).clamp(9.0, 12.0);

    // Gap between legend items
    final legendSpacing = context.widthFraction(0.03).clamp(8.0, 14.0);
    final legendRunSpacing = context.heightFraction(0.006).clamp(4.0, 8.0);

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: chartSize,
          height: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      if (!event.isInterestedForInteractions ||
                          response == null ||
                          response.touchedSection == null) {
                        setState(() => _touchedIndex = -1);
                        return;
                      }
                      setState(() {
                        _touchedIndex = response
                            .touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: centerRadius,
                  sections: List.generate(widget.slices.length, (i) {
                    final slice     = widget.slices[i];
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      value: slice.value,
                      color: slice.color,
                      radius: isTouched ? selectedRadius : sliceRadius,
                      title: '',
                      borderSide: isTouched
                          ? BorderSide(
                              color: slice.color.withOpacity(0.8),
                              width: 3,
                            )
                          : const BorderSide(color: Colors.transparent),
                    );
                  }),
                ),
              ),
              // Center label — constrained so it never overflows the hole
              SizedBox(
                width: centerRadius * 1.6,
                child: _CenterLabel(
                  touchedIndex: _touchedIndex,
                  slices: widget.slices,
                  totalSpent: widget.totalSpent,
                  fontSize: context.widthFraction(0.032).clamp(10.0, 14.0),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: context.heightFraction(0.02).clamp(10.0, 20.0)),
        Wrap(
          spacing: legendSpacing,
          runSpacing: legendRunSpacing,
          alignment: WrapAlignment.center,
          children: List.generate(widget.slices.length, (i) {
            final slice     = widget.slices[i];
            final isTouched = i == _touchedIndex;
            final pct       = slice.percentage(widget.totalSpent);

            return AnimatedOpacity(
              opacity: _touchedIndex == -1 || isTouched ? 1.0 : 0.4,
              duration: const Duration(milliseconds: 150),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: dotSize,
                    height: dotSize,
                    decoration: BoxDecoration(
                      color: slice.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: context.widthFraction(0.01).clamp(3.0, 6.0)),
                  Text(
                    '${slice.label} (${pct.toStringAsFixed(1)}%)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: legendFontSize,
                      fontWeight: isTouched
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _CenterLabel extends StatelessWidget {
  const _CenterLabel({
    required this.touchedIndex,
    required this.slices,
    required this.totalSpent,
    required this.fontSize,
  });

  final int touchedIndex;
  final List<PieSliceData> slices;
  final double totalSpent;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (touchedIndex >= 0 && touchedIndex < slices.length) {
      final slice = slices[touchedIndex];
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slice.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: fontSize * 0.85,
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          CurrencyText(
            slice.value,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: slice.color,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Total',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: fontSize * 0.85,
            color: theme.colorScheme.outline,
          ),
        ),
        CurrencyText(
          totalSpent,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}