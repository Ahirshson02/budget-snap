import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/snackbar_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../../domain/models/category.dart';
import '../providers/budget_notifier.dart';
import '../providers/budget_state.dart';

class EditCategorySheet extends ConsumerStatefulWidget {
  const EditCategorySheet({
    super.key,
    required this.month,
    required this.category,
  });

  final DateTime month;
  final Category category;

  @override
  ConsumerState<EditCategorySheet> createState() =>
      _EditCategorySheetState();
}

class _EditCategorySheetState extends ConsumerState<EditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(
    text: widget.category.name,
  );
  late final _amountCtrl = TextEditingController(
    text: widget.category.allocatedAmount.toStringAsFixed(2),
  );

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref
        .read(budgetNotifierProvider(widget.month).notifier)
        .updateCategory(
          categoryId: widget.category.id,
          name: _nameCtrl.text.trim(),
          allocatedAmount: double.parse(_amountCtrl.text),
        );

    if (!mounted) return;

    final state = ref.read(budgetNotifierProvider(widget.month));
    if (state is BudgetError) {
      SnackBarService.showError(context, state.message);
    } else {
      SnackBarService.showSuccess(context, 'Category updated');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(budgetNotifierProvider(widget.month))
        is BudgetLoading;
    final theme     = Theme.of(context);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            context.heightFraction(0.55) + context.bottomInset,
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
                  height:
                      context.heightFraction(0.02).clamp(12.0, 20.0),
                ),
                Text(
                  'Edit Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height:
                      context.heightFraction(0.02).clamp(12.0, 20.0),
                ),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                  ),
                  validator:
                      Validators.required('Category name is required'),
                ),
                SizedBox(
                  height:
                      context.heightFraction(0.015).clamp(10.0, 16.0),
                ),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [CurrencyInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'Allocated Amount',
                    prefixText: '\$ ',
                  ),
                  validator: Validators.compose([
                    Validators.required('Amount is required'),
                    Validators.positiveAmount(),
                  ]),
                ),
                SizedBox(
                  height:
                      context.heightFraction(0.025).clamp(14.0, 24.0),
                ),
                LoadingButton(
                  label: 'Save Changes',
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