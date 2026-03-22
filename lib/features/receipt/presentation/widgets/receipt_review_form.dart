import 'dart:io';

import 'package:budget_snap/core/utils/currency_input_formatter.dart';
import 'package:budget_snap/core/utils/snackbar_service.dart';
import 'package:budget_snap/core/utils/validators.dart';
import 'package:budget_snap/features/receipt/presentation/widgets/category_dropdown.dart';
import 'package:budget_snap/features/receipt/presentation/widgets/expense_item_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/widgets/currency_text.dart';
import '../../../../core/widgets/loading_button.dart';
import '../../../budget/domain/models/category.dart';
import '../../../budget/presentation/providers/budget_notifier.dart';
import '../../../budget/presentation/providers/budget_state.dart';
import '../../domain/models/parsed_receipt.dart';
import '../providers/receipt_parse_notifier.dart';
import '../providers/receipt_parse_state.dart';

class ReceiptReviewForm extends ConsumerStatefulWidget {
  const ReceiptReviewForm({
    super.key,
    required this.parsed,
    required this.imagePath,
  });

  final ParsedReceipt parsed;
  final String imagePath;

  @override
  ConsumerState<ReceiptReviewForm> createState() => _ReceiptReviewFormState();
}

class _ReceiptReviewFormState extends ConsumerState<ReceiptReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Controllers for top-level receipt fields
  late final _merchantCtrl =
      TextEditingController(text: widget.parsed.merchant ?? '');
  late final _totalCtrl = TextEditingController(
    text: widget.parsed.total?.toStringAsFixed(2) ?? '',
  );
  late final _commentCtrl = TextEditingController();

  // Selected date — source of truth for submit; _dateCtrl mirrors it for display
  late DateTime _selectedDate = widget.parsed.date ?? DateTime.now();
  late final TextEditingController _dateCtrl;

  // Top-level category for the whole expense
  String? _selectedCategoryId;

  // Per-item editable data: controllers and category selections
  late final List<TextEditingController> _itemNameControllers;
  late final List<TextEditingController> _itemPriceControllers;
  late final List<String?> _itemCategoryIds;

  @override
  void initState() {
    super.initState();
    _dateCtrl = TextEditingController(
      text: DateFormat.yMMMd().format(_selectedDate),
    );
    _itemNameControllers = widget.parsed.items
        .map((i) => TextEditingController(text: i.name))
        .toList();
    _itemPriceControllers = widget.parsed.items.map((i) {
      final ctrl = TextEditingController(text: i.price.toStringAsFixed(2));
      ctrl.addListener(_recalculateTotal);
      return ctrl;
    }).toList();
    _itemCategoryIds = List.filled(widget.parsed.items.length, null, growable: true);

    // Load the current month's budget so we can populate category dropdowns
    final now = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(budgetNotifierProvider(DateTime(now.year, now.month)).notifier)
          .loadBudget(DateTime(now.year, now.month));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _merchantCtrl.dispose();
    _totalCtrl.dispose();
    _commentCtrl.dispose();
    _dateCtrl.dispose();
    for (final c in _itemNameControllers) {
      c.dispose();
    }
    for (final c in _itemPriceControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<Category> _getCategories() {
    final now = DateTime.now();
    final budgetState =
        ref.watch(budgetNotifierProvider(DateTime(now.year, now.month)));
    if (budgetState is BudgetLoaded) {
      return budgetState.budget.categories;
    }
    return [];
  }

  Future<void> _selectDate() async {
    print("run selectDate");
    final picked = await showDatePicker(
      context: context,
      //initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _dateCtrl.text = DateFormat.yMMMd().format(picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final items = List.generate(
      _itemNameControllers.length,
      (i) => (
        name: _itemNameControllers[i].text.trim(),
        price: double.tryParse(_itemPriceControllers[i].text) ?? 0,
        categoryId: _itemCategoryIds[i],
      ),
    );

    final double total = double.tryParse(_totalCtrl.text) ??
    items.fold(0.0, (sum, item) => sum + item.price);

    final success =
        await ref.read(receiptParseNotifierProvider.notifier).saveExpense(
              date: _selectedDate,
              total: double.tryParse(_totalCtrl.text) ?? 0,
              merchant: _merchantCtrl.text.trim().isEmpty
                  ? null
                  : _merchantCtrl.text.trim(),
              categoryId: _selectedCategoryId,
              comment: _commentCtrl.text.trim().isEmpty
                  ? null
                  : _commentCtrl.text.trim(),
              items: items,
            );

    if (!mounted) return;

    if (success) {
      final expenseMonth = DateTime(_selectedDate.year, _selectedDate.month);
      ref
          .read(budgetNotifierProvider(expenseMonth).notifier)
          .loadBudget(expenseMonth);
      SnackBarService.showSuccess(context, 'Expense saved successfully');
    } else {
      final state = ref.read(receiptParseNotifierProvider);
      if (state is ReceiptParseError) {
        SnackBarService.showError(context, state.message);
      }
    }
  }

  void _recalculateTotal() {
    final sum = _itemPriceControllers.fold(
      0.0,
      (total, ctrl) => total + (double.tryParse(ctrl.text) ?? 0.0),
    );
    _totalCtrl.text = sum.toStringAsFixed(2);
  }

  void _addItem() {
    final priceCtrl = TextEditingController();
    priceCtrl.addListener(_recalculateTotal);
    setState(() {
      _itemNameControllers.insert(0, TextEditingController());
      _itemPriceControllers.insert(0, priceCtrl);
      _itemCategoryIds.insert(0, null);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemNameControllers[index].dispose();
      _itemPriceControllers[index].dispose();
      _itemNameControllers.removeAt(index);
      _itemPriceControllers.removeAt(index);
      _itemCategoryIds.removeAt(index);
    });
    _recalculateTotal();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        ref.watch(receiptParseNotifierProvider) is ReceiptParseSaving;
    final categories = _getCategories();
    final theme = Theme.of(context);
    final hPad = context.horizontalPadding;

    return Form(
      key: _formKey,
      child: ListView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(
          horizontal: hPad,
          vertical: context.heightFraction(0.015).clamp(8.0, 16.0),
        ),
        children: [
          // ── Receipt image thumbnail ──────────────────────────────
          _ReceiptImageThumbnail(imagePath: widget.imagePath),
          SizedBox(height: context.heightFraction(0.02).clamp(10.0, 20.0)),

          // ── Section: Receipt Details ─────────────────────────────
          _SectionHeader(title: 'Receipt Details'),
          SizedBox(height: context.heightFraction(0.01).clamp(6.0, 12.0)),

          TextFormField(
            controller: _merchantCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Merchant',
              prefixIcon: Icon(Icons.storefront_outlined),
            ),
          ),
          SizedBox(height: context.heightFraction(0.015).clamp(8.0, 14.0)),

          // Date picker row
          TextFormField(
            controller: _dateCtrl,
            readOnly: true,
            onTap: _selectDate,
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(Icons.calendar_today_outlined),
              suffixIcon: Icon(Icons.edit_calendar_outlined),
            ),
          ),
          SizedBox(height: context.heightFraction(0.015).clamp(8.0, 14.0)),

          TextFormField(
            controller: _totalCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Leave blank to auto sum items',
              prefixText: '\$ ',
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Total is required';
              if (double.tryParse(v) == null) return 'Enter a valid amount';
              return null;
            },
          ),
          SizedBox(height: context.heightFraction(0.015).clamp(8.0, 14.0)),

          // Category dropdown for the whole expense
          CategoryDropdown(
            label: 'Category (optional)',
            value: _selectedCategoryId,
            categories: categories,
            onChanged: (id) => setState(() => _selectedCategoryId = id),
          ),
          SizedBox(height: context.heightFraction(0.015).clamp(8.0, 14.0)),

          TextFormField(
            controller: _commentCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Comment (optional)',
              prefixIcon: Icon(Icons.comment_outlined),
              alignLabelWithHint: true,
            ),
          ),
          SizedBox(height: context.heightFraction(0.025).clamp(14.0, 24.0)),

          LoadingButton(
            label: 'Save Expense',
            isLoading: isSaving,
            onPressed: _submit,
          ),
          SizedBox(height: context.heightFraction(0.02).clamp(10.0, 20.0)),
          
          // ── Section: Line Items ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _SectionHeader(title: 'Line Items'),
              TextButton.icon(
                onPressed: _addItem,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item'),
              ),
            ],
          ),
          SizedBox(height: context.heightFraction(0.01).clamp(6.0, 12.0)),

          if (_itemNameControllers.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: context.heightFraction(0.02),
              ),
              child: Center(
                child: Text(
                  'No line items detected. Tap "Add Item" to add manually.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              _itemNameControllers.length,
              (index) => LineItemRow(
                index: index,
                nameController: _itemNameControllers[index],
                priceController: _itemPriceControllers[index],
                categories: categories,
                selectedCategoryId: _itemCategoryIds[index],
                onCategoryChanged: (id) => setState(
                  () => _itemCategoryIds[index] = id,
                ),
                onRemove: () => _removeItem(index),
              ),
            ),

          SizedBox(height: context.heightFraction(0.03).clamp(16.0, 28.0)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------
// Receipt image thumbnail
// ----------------------------------------------------------------

class _ReceiptImageThumbnail extends StatelessWidget {
  const _ReceiptImageThumbnail({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    // Height is 25% of screen height — tall enough to be useful,
    // short enough to leave room for the form
    final thumbHeight = context.heightFraction(0.25).clamp(140.0, 220.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: SizedBox(
        height: thumbHeight,
        width: double.infinity,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: thumbHeight,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
// Section header
// ----------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}
