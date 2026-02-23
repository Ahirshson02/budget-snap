import 'package:budget_snap/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../../../budget/data/providers/budget_repository_provider.dart';
import '../../../budget/domain/models/budget.dart';
import '../mappers/chart_mapper.dart';
import '../providers/analytics_notifier.dart';
import '../providers/analytics_state.dart';
import '../widgets/analytics_summary_card.dart';
import '../widgets/category_bar_chart.dart';
import '../widgets/chart_section_card.dart';
import '../widgets/month_comparison_chart.dart';
import '../widgets/spending_pie_chart.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    ref
        .read(analyticsNotifierProvider.notifier)
        .loadAnalytics(_selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(analyticsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Column(
        children: [
          _MonthSelector(
            month: _selectedMonth,
            onPrevious: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month - 1,
                );
              });
              _load();
            },
            onNext: () {
              setState(() {
                _selectedMonth = DateTime(
                  _selectedMonth.year,
                  _selectedMonth.month + 1,
                );
              });
              _load();
            },
          ),
          Expanded(
            child: switch (analyticsState) {
              AnalyticsLoading() || AnalyticsInitial() =>
                const AppLoadingIndicator(),
              AnalyticsError(:final message) => AppErrorWidget(
                  message: message,
                  onRetry: _load,
                ),
              AnalyticsLoaded(:final currentMonth, :final previousMonth) =>
                _AnalyticsContent(
                  current: currentMonth,
                  previous: previousMonth,
                ),
            },
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Month selector
// ----------------------------------------------------------------

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({
    required this.month,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.horizontalPadding,
        vertical: context.heightFraction(0.01).clamp(6.0, 12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: onPrevious,
          ),
          Text(
            DateFormat.yMMMM().format(month),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Main content
// ----------------------------------------------------------------

class _AnalyticsContent extends ConsumerWidget {
  const _AnalyticsContent({
    required this.current,
    required this.previous,
  });

  final MonthSummary current;
  final MonthSummary? previous;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hPad    = context.horizontalPadding;
    final vGap    = context.heightFraction(0.02).clamp(10.0, 20.0);
    final vPad    = context.heightFraction(0.015).clamp(8.0, 16.0);
    final bottomPad = context.heightFraction(0.04).clamp(20.0, 40.0);

    final pieSlices = ChartMapper.toPieSlices(current);

    final budgetAsync = ref.watch(
      _budgetForMonthProvider(current.month),
    );

    final categoryBars = ChartMapper.toCategoryBars(
      current,
      budgetAsync.valueOrNull,
    );

    if (current.totalSpent == 0) {
      return const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No spending data',
        subtitle: 'Add expenses this month to see your analytics.',
      );
    }

    return ListView(
      padding: EdgeInsets.symmetric(
        horizontal: hPad,
        vertical: vPad,
      ),
      children: [
        AnalyticsSummaryCard(current: current, previous: previous),
        SizedBox(height: vGap),

        if (pieSlices.isNotEmpty) ...[
          ChartSectionCard(
            title: 'Spending by Category',
            subtitle: 'Tap a slice to see details',
            child: SpendingPieChart(
              slices: pieSlices,
              totalSpent: current.totalSpent,
            ),
          ),
          SizedBox(height: vGap),
        ],

        if (categoryBars.isNotEmpty) ...[
          ChartSectionCard(
            title: 'Budget vs Spending',
            subtitle: 'Solid = spent  ·  Light = allocated',
            child: CategoryBarChart(bars: categoryBars),
          ),
          SizedBox(height: vGap),
        ],

        ChartSectionCard(
          title: 'Month over Month',
          subtitle: previous != null
              ? 'Comparing ${DateFormat.MMM().format(current.month)} '
                  'vs ${DateFormat.MMM().format(previous!.month)}'
              : 'No previous month data yet',
          child: MonthComparisonChart(
            current: current,
            previous: previous,
          ),
        ),
        SizedBox(height: vGap),

        ChartSectionCard(
          title: 'Category Breakdown',
          subtitle: 'All spending this month',
          child: _CategoryBreakdownList(summary: current),
        ),

        SizedBox(height: bottomPad),
      ],
    );
  }
}

// ----------------------------------------------------------------
// Budget provider scoped to a specific month
// ----------------------------------------------------------------

final _budgetForMonthProvider =
    FutureProvider.autoDispose.family<Budget?, DateTime>((ref, month) async {
  final repo = ref.watch(budgetRepositoryProvider);
  return repo.getBudgetByMonth(month);
});

// ----------------------------------------------------------------
// Category breakdown list
// ----------------------------------------------------------------

class _CategoryBreakdownList extends StatelessWidget {
  const _CategoryBreakdownList({required this.summary});

  final MonthSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme   = Theme.of(context);
    final dotSize = context.widthFraction(0.022).clamp(8.0, 12.0);
    final dotGap  = context.widthFraction(0.02).clamp(6.0, 10.0);
    final pctGap  = context.widthFraction(0.02).clamp(6.0, 10.0);
    final rowGap  = context.heightFraction(0.012).clamp(6.0, 12.0);

    final entries = summary.spentByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: context.heightFraction(0.02).clamp(10.0, 20.0),
          ),
          child: Text(
            'No categorized spending.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(entries.length, (i) {
        final entry = entries[i];
        final color =
            AppColors.chartPalette[i % AppColors.chartPalette.length];
        final pct = summary.totalSpent > 0
            ? (entry.value / summary.totalSpent * 100)
            : 0.0;

        return Padding(
          padding: EdgeInsets.only(bottom: rowGap),
          child: Row(
            children: [
              Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: dotGap),
              Expanded(
                child: Text(
                  entry.key,
                  style: theme.textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              SizedBox(width: pctGap),
              Text(
                '\$${entry.value.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}