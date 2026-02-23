import 'package:freezed_annotation/freezed_annotation.dart';

part 'analytics_state.freezed.dart';

/// Aggregated data for one month — used in charts.
@freezed
class MonthSummary with _$MonthSummary {
  const factory MonthSummary({
    required DateTime month,
    required double totalSpent,
    required double totalBudget,

    /// Spending broken down by category name → amount spent.
    required Map<String, double> spentByCategory,
  }) = _MonthSummary;
}

@freezed
sealed class AnalyticsState with _$AnalyticsState {
  const factory AnalyticsState.initial()          = AnalyticsInitial;
  const factory AnalyticsState.loading()          = AnalyticsLoading;

  const factory AnalyticsState.loaded({
    /// Current month summary for pie chart.
    required MonthSummary currentMonth,

    /// Previous month summary for comparison bar chart.
    MonthSummary? previousMonth,
  }) = AnalyticsLoaded;

  const factory AnalyticsState.error(String message) = AnalyticsError;
}