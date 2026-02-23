import 'package:flutter/material.dart';
import '../utils/responsive.dart';
import '../theme/app_theme.dart';

/// Wraps the entire app to catch unhandled widget tree errors.
///
/// Flutter's default red error screen is never shown in production.
/// Instead, we show a friendly recovery UI with a restart option.
///
/// Usage: wrap [BudgetAiApp] in [AppErrorBoundary] inside main().
class AppErrorBoundary extends StatefulWidget {
  const AppErrorBoundary({super.key, required this.child});

  final Widget child;

  @override
  State<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends State<AppErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    // Override Flutter's default error handling
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (mounted) setState(() => _error = details.exception);
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: _ErrorRecoveryScreen(
          onRestart: () => setState(() => _error = null),
        ),
      );
    }
    return widget.child;
  }
}

class _ErrorRecoveryScreen extends StatelessWidget {
  const _ErrorRecoveryScreen({required this.onRestart});

  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 64,
                  color: AppColors.warning,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'An unexpected error occurred. Tap below to restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRestart,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Restart App'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}