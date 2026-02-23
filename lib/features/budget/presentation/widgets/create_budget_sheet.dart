import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../providers/budget_notifier.dart';
import '../providers/budget_state.dart';

class CreateBudgetSheet extends ConsumerStatefulWidget {
  const CreateBudgetSheet({super.key, required this.month});

  final DateTime month;

  @override
  ConsumerState<CreateBudgetSheet> createState() => _CreateBudgetSheetState();
}

class _CreateBudgetSheetState extends ConsumerState<CreateBudgetSheet> {
  final _formKey    = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(budgetNotifierProvider(widget.month).notifier)
        .createBudget(
          month: widget.month,
          totalBudget: double.parse(_amountCtrl.text),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(budgetNotifierProvider(widget.month))
        is BudgetLoading;
    final theme     = Theme.of(context);

    // Sheet occupies at most 40% of screen height (plus keyboard inset)
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.heightFraction(0.40) + context.bottomInset,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          context.horizontalPadding,
          context.heightFraction(0.02).clamp(12.0, 20.0),
          context.horizontalPadding,
          context.bottomInset +
              context.heightFraction(0.03).clamp(12.0, 24.0),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SheetHandle(),
                SizedBox(
                  height: context.heightFraction(0.02).clamp(12.0, 20.0),
                ),
                Text(
                  'Create Budget',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: context.heightFraction(0.008).clamp(4.0, 8.0),
                ),
                Text(
                  'Set your total spending limit for this month.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                SizedBox(
                  height: context.heightFraction(0.02).clamp(12.0, 20.0),
                ),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Total Budget',
                    prefixText: '\$ ',
                    hintText: '0.00',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Amount is required';
                    final parsed = double.tryParse(v);
                    if (parsed == null || parsed <= 0) {
                      return 'Enter a valid amount';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: context.heightFraction(0.025).clamp(14.0, 24.0),
                ),
                LoadingButton(
                  label: 'Create Budget',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}