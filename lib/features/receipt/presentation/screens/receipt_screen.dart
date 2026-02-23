import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading_indicator.dart';
import '../providers/receipt_parse_notifier.dart';
import '../providers/receipt_parse_state.dart';
import '../widgets/receipt_review_form.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parseState = ref.watch(receiptParseNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipts'),
        actions: [
          // Show reset button when in review so user can start over
          if (parseState is ReceiptParseReview ||
              parseState is ReceiptParseError)
            TextButton(
              onPressed: () =>
                  ref.read(receiptParseNotifierProvider.notifier).reset(),
              child: const Text('Start Over'),
            ),
        ],
      ),
      body: switch (parseState) {
        ReceiptParseIdle() => _IdleView(),
        ReceiptParseCapturing() => const _StatusView(
            icon: Icons.camera_alt_outlined,
            message: 'Opening camera...',
          ),
        ReceiptParseParsing() => const _StatusView(
            icon: Icons.document_scanner_outlined,
            message: 'Reading receipt...',
          ),
        ReceiptParseSaving() => const _StatusView(
            icon: Icons.cloud_upload_outlined,
            message: 'Saving expense...',
          ),
        ReceiptParseError(:final message) => AppErrorWidget(
            message: message,
            onRetry: () =>
                ref.read(receiptParseNotifierProvider.notifier).reset(),
          ),
        ReceiptParseReview(:final parsed, :final imagePath) =>
          ReceiptReviewForm(
            parsed: parsed,
            imagePath: imagePath,
          ),
      },
    );
  }
}

// ----------------------------------------------------------------
// Idle view — source picker
// ----------------------------------------------------------------

class _IdleView extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(receiptParseNotifierProvider.notifier);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.horizontalPadding,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: (context.screenWidth * 0.20).clamp(64.0, 96.0),
              color: Theme.of(context).colorScheme.outline,
            ),
            SizedBox(height: context.heightFraction(0.03)),
            Text(
              'Scan a Receipt',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            SizedBox(height: context.heightFraction(0.01)),
            Text(
              'Take a photo or choose from your gallery to automatically parse your receipt.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            SizedBox(height: context.heightFraction(0.05)),
            _SourceButton(
              icon: Icons.camera_alt_outlined,
              label: 'Take Photo',
              onTap: notifier.captureFromCamera,
            ),
            SizedBox(height: context.heightFraction(0.02)),
            _SourceButton(
              icon: Icons.photo_library_outlined,
              label: 'Choose from Gallery',
              onTap: notifier.captureFromGallery,
              filled: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Text(label),
      ],
    );

    return SizedBox(
      width: double.infinity,
      child: filled
          ? ElevatedButton(onPressed: onTap, child: child)
          : OutlinedButton(onPressed: onTap, child: child),
    );
  }
}

// ----------------------------------------------------------------
// In-progress status view
// ----------------------------------------------------------------

class _StatusView extends StatelessWidget {
  const _StatusView({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: context.heightFraction(0.03)),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}