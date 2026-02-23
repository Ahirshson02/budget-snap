import '../../../../core/theme/app_theme.dart';
import '../../../budget/domain/models/budget.dart';
import '../../presentation/providers/analytics_state.dart';
import '../models/chart_data.dart';

abstract class ChartMapper {
  /// Builds pie slices from the category spending map.
  /// Categories with zero spend are excluded to keep the chart readable.
  static List<PieSliceData> toPieSlices(MonthSummary summary) {
    final entries = summary.spentByCategory.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // largest slice first

    return List.generate(entries.length, (i) {
      final color = AppColors.chartPalette[i % AppColors.chartPalette.length];
      return PieSliceData(
        label: entries[i].key,
        value: entries[i].value,
        color: color,
      );
    });
  }

  /// Builds grouped bars — one per category showing spent vs allocated.
  /// Requires the budget to get allocated amounts.
  static List<CategoryBarData> toCategoryBars(
    MonthSummary summary,
    Budget? budget,
  ) {
    if (budget == null) {
      // No budget — show only spending bars without an allocation reference
      return summary.spentByCategory.entries
          .where((e) => e.value > 0)
          .map((e) => CategoryBarData(
                label: e.key,
                spent: e.value,
                allocated: 0,
              ))
          .toList();
    }

    return budget.categories.map((cat) {
      final spent = summary.spentByCategory[cat.name] ?? 0;
      return CategoryBarData(
        label: cat.name,
        spent: spent,
        allocated: cat.allocatedAmount,
      );
    }).toList();
  }

  /// Builds the month-over-month comparison data.
  static List<MonthComparisonData> toMonthComparison(
    MonthSummary current,
    MonthSummary? previous,
  ) {
    return [
      MonthComparisonData(
        label: 'This Month',
        currentAmount: current.totalSpent,
        previousAmount: previous?.totalSpent ?? 0,
      ),
    ];
  }
}