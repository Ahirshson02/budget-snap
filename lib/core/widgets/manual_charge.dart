import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../../core/utils/validators.dart';
import '../../features/budget/domain/models/category.dart';
import '../../features/budget/presentation/providers/budget_notifier.dart';
import '../../features/receipt/data/providers/expense_repository_provider.dart';

/// Shows a dialog to add a manual expense charge to [category].
///
/// Call this from any widget that has a BuildContext and WidgetRef:
///
/// ```dart
/// showAddManualExpenseDialog(
///   context: context,
///   ref: ref,
///   category: category,
///   month: _selectedMonth,
/// );
/// ```
Future<void> showAddManualExpenseDialog({
  required BuildContext context,
  required WidgetRef ref,
  Category? category,
  required DateTime month,
}) {
  final merchantCtrl = TextEditingController();
  final totalCtrl    = TextEditingController();
  final formKey      = GlobalKey<FormState>();
  final commentCtrl = TextEditingController();
  var selectedDate   = DateTime.now();
  var isLoading      = false;

  return showDialog(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        return AlertDialog(
         // title: (category != null) ? Text('Add Charge to ${category.name}') : Text("Add Charge to Uncategorized"),
          title: Text("Add charge to ${category?.name ?? "Uncategorized"}"),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                //Amount
                  TextFormField(
                    controller: totalCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [CurrencyInputFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      //prefixText: '\$ ',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: Validators.compose([
                      Validators.required('Amount is required'),
                      Validators.positiveAmount(),
                    ]),
                  ),
                const SizedBox(height: 12),
                // Date picker
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: dialogContext,
                      initialDate: selectedDate,
                      firstDate: month,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      suffixIcon: Icon(Icons.edit_calendar_outlined),
                    ),
                    child: Text(DateFormat.yMMMd().format(selectedDate)),
                  ),
                ),
                const SizedBox(height: 12),
                // Merchant
                TextFormField(
                  controller: merchantCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Merchant (optional)',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: commentCtrl,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    prefixIcon: Icon(Icons.storefront_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading
                  ? null
                  : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() => isLoading = true);

                      try {
                        // Save to database
                        await ref
                            .read(expenseRepositoryProvider)
                            .createExpense(
                              date: selectedDate,
                              total: double.parse(totalCtrl.text),
                              merchant: merchantCtrl.text.trim().isEmpty
                                  ? null
                                  : merchantCtrl.text.trim(),
                              categoryId: category?.id ?? null,
                              comment: commentCtrl.text.trim().isEmpty ? null : commentCtrl.text.trim(),
                              items: [],
                            );

                        // Refresh budget state so spending bars
                        // update immediately on home/budget screens
                        ref
                            .read(budgetNotifierProvider(month).notifier)
                            .loadBudget(month);

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          SnackBarService.showSuccess(
                            context,
                            'Charge added to ${category?.name ?? "Uncategorized"}',
                          );
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (dialogContext.mounted) {
                          SnackBarService.showError(
                            dialogContext,
                            'Failed to save charge. Please try again.',
                          );
                        }
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Add Charge'),
            ),
          ],
        );
      },
    ),
  );
}