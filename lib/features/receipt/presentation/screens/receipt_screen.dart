import 'package:flutter/material.dart';
import '../../../../core/widgets/app_empty_state.dart';

class ReceiptScreen extends StatelessWidget {
  const ReceiptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipts')),
      body: const AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'No receipts yet',
        subtitle: 'Scan a receipt to log an expense instantly.',
      ),
    );
  }
}