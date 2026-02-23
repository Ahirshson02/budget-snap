import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../../core/widgets/sheet_handle.dart';
import '../../domain/models/category.dart';
import '../providers/budget_notifier.dart';
import '../providers/budget_state.dart';

class AddCategorySheet extends ConsumerStatefulWidget {
  const AddCategorySheet({super.key, required this.month});

  final DateTime month;

  @override
  ConsumerState<AddCategorySheet> createState() => _AddCategorySheetState();
}

class _AddCategorySheetState extends ConsumerState<AddCategorySheet> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _amountCtrl = TextEditingController();
  PredefinedCategory? _selectedPredefined;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectPredefined(PredefinedCategory cat) {
    setState(() {
      _selectedPredefined = cat;
      _nameCtrl.text = cat.label;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(budgetNotifierProvider(widget.month).notifier)
        .addCategory(
          name: _nameCtrl.text.trim(),
          allocatedAmount: double.parse(_amountCtrl.text),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(budgetNotifierProvider(widget.month))
        is BudgetLoading;
    final theme     = Theme.of(context);

    // Sheet can grow to 75% of screen height to accommodate chip grid
    // and keyboard without overflow
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: context.heightFraction(0.75) + context.bottomInset,
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
                  'Add Category',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(
                  height: context.heightFraction(0.015).clamp(10.0, 16.0),
                ),
                Text(
                  'Quick select',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                SizedBox(
                  height: context.heightFraction(0.01).clamp(6.0, 10.0),
                ),
                // Wrap lets chips flow naturally — no fixed height grid
                Wrap(
                  spacing: context.widthFraction(0.02).clamp(6.0, 10.0),
                  runSpacing: context.heightFraction(0.005).clamp(4.0, 8.0),
                  children: PredefinedCategory.values.map((cat) {
                    return FilterChip(
                      label: Text(cat.label),
                      selected: _selectedPredefined == cat,
                      onSelected: (_) => _selectPredefined(cat),
                    );
                  }).toList(),
                ),
                SizedBox(
                  height: context.heightFraction(0.02).clamp(12.0, 18.0),
                ),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Category Name',
                    hintText: 'e.g. Dining Out',
                  ),
                  onChanged: (_) =>
                      setState(() => _selectedPredefined = null),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    return null;
                  },
                ),
                SizedBox(
                  height: context.heightFraction(0.015).clamp(10.0, 16.0),
                ),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Allocated Amount',
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
                  label: 'Add Category',
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