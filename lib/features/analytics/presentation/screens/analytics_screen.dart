import 'package:flutter/material.dart';
import '../../../../core/widgets/app_empty_state.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const AppEmptyState(
        icon: Icons.bar_chart_outlined,
        title: 'No data yet',
        subtitle: 'Add expenses to see your spending analytics.',
      ),
    );
  }
}