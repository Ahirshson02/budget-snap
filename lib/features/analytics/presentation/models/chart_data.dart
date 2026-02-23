import 'package:flutter/material.dart';

/// A single slice of a pie chart.
class PieSliceData {
  const PieSliceData({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  /// Percentage of this slice relative to [total].
  double percentage(double total) =>
      total <= 0 ? 0 : (value / total * 100);
}

/// A single grouped bar — one category with spent and allocated amounts.
class CategoryBarData {
  const CategoryBarData({
    required this.label,
    required this.spent,
    required this.allocated,
  });

  final String label;
  final double spent;
  final double allocated;
}

/// Two bars side by side — current month vs previous month total.
class MonthComparisonData {
  const MonthComparisonData({
    required this.label,
    required this.currentAmount,
    required this.previousAmount,
  });

  final String label;
  final double currentAmount;
  final double previousAmount;
}