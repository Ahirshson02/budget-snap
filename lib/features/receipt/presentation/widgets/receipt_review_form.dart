import 'dart:io';

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
  ConsumerState<ReceiptReviewForm> createState() =>
      _ReceiptReviewFormState();
}

class _ReceiptReviewFormState extends ConsumerState<ReceiptReviewForm> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for top-level receipt fields
  late final _merchantCtrl =
      TextEditingController(text: widget.parsed.merchant ?? '');
  late final _totalCtrl = TextEditingController(
    text: widget.parsed.total?.toStringAsFixed(2) ?? '',
  );
  late final _commentCtrl = TextEditingController();

  // Selected date — defaults to parsed date or today
  late DateTime _selectedDate =
      widget.parsed.date ?? DateTime.now();

  // Top-level category for the whole expense
  String? _selectedCategoryId;

  // Per-item editable data: controllers and category selections
  late final List<TextEditingController> _itemNameControllers;
  late final List<TextEditingController> _itemPriceControllers;
  late final List<String?> _itemCategoryIds;

  @override
  void initState() {
    super.initState();
    _itemNameControllers = widget.parsed.items
        .map((i) => TextEditingController(text: i.name))
        .toList();
    _itemPriceControllers = widget.parsed.items
        .map((i) => TextEditingController(text: i.price.toStringAsFixed(2)))
        .toList();
    _itemCategoryIds = List.filled(widget.parsed.items.length, null);

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
    _merchantCtrl.dispose();
    _totalCtrl.dispose();
    _commentCtrl.dispose();
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
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
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

    final success = await ref
        .read(receiptParseNotifierProvider.notifier)
        .saveExpense(
          categoryId: _selectedCategoryId,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
          items: items,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expense saved successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _addItem() {
    setState(() {
      _itemNameControllers.add(TextEditingController());
      _itemPriceControllers.add(TextEditingController());
      _itemCategoryIds.add(null);
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
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        ref.watch(receiptParseNotifierProvider) is ReceiptParseSaving;
    final categories = _getCategories();
    final theme      = Theme.of(context);
    final hPad       = context.horizontalPadding;

    return Form(
      key: _formKey,
      child: ListView(
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
          InkWell(
            onTap: _selectDate,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Date',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                suffixIcon: Icon(Icons.edit_calendar_outlined),
              ),
              child: Text(
                DateFormat.yMMMd().format(_selectedDate),
                style: theme.textTheme.bodyLarge,
              ),
            ),
          ),
          SizedBox(height: context.heightFraction(0.015).clamp(8.0, 14.0)),

          TextFormField(
            controller: _totalCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total',
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
          _CategoryDropdown(
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
              (index) => _LineItemRow(
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

          LoadingButton(
            label: 'Save Expense',
            isLoading: isSaving,
            onPressed: _submit,
          ),
          SizedBox(height: context.heightFraction(0.02).clamp(10.0, 20.0)),
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

// ----------------------------------------------------------------
// Category dropdown
// ----------------------------------------------------------------

class _CategoryDropdown extends StatelessWidget {
  const _CategoryDropdown({
    required this.label,
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final List<Category> categories;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.category_outlined),
      ),
      isExpanded: true,
      items: [
        const DropdownMenuItem(
          value: null,
          child: Text('No category'),
        ),
        ...categories.map(
          (cat) => DropdownMenuItem(
            value: cat.id,
            child: Text(
              cat.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

// ----------------------------------------------------------------
// Line item row
// ----------------------------------------------------------------

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({
    required this.index,
    required this.nameController,
    required this.priceController,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
    required this.onRemove,
  });

  final int index;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme    = Theme.of(context);
    final innerPad = context.widthFraction(0.03).clamp(10.0, 16.0);

    return Card(
      margin: EdgeInsets.only(
        bottom: context.heightFraction(0.012).clamp(6.0, 12.0),
      ),
      child: Padding(
        padding: EdgeInsets.all(innerPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Item header with number and remove button
            Row(
              children: [
                Text(
                  'Item ${index + 1}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: onRemove,
                  visualDensity: VisualDensity.compact,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
            SizedBox(height: context.heightFraction(0.008).clamp(4.0, 8.0)),

            // Name and price on the same row on wider screens,
            // stacked on narrow screens
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 360;

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _NameField(controller: nameController),
                      ),
                      SizedBox(width: context.widthFraction(0.02)),
                      Expanded(
                        flex: 2,
                        child: _PriceField(controller: priceController),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _NameField(controller: nameController),
                    SizedBox(
                        height: context.heightFraction(0.01).clamp(6.0, 10.0)),
                    _PriceField(controller: priceController),
                  ],
                );
              },
            ),

            if (categories.isNotEmpty) ...[
              SizedBox(
                  height: context.heightFraction(0.01).clamp(6.0, 10.0)),
              _CategoryDropdown(
                label: 'Item Category',
                value: selectedCategoryId,
                categories: categories,
                onChanged: onCategoryChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      decoration: const InputDecoration(
        labelText: 'Item Name',
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Required';
        return null;
      },
    );
  }
}

class _PriceField extends StatelessWidget {
  const _PriceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: const InputDecoration(
        labelText: 'Price',
        prefixText: '\$ ',
        isDense: true,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (double.tryParse(v) == null) return 'Invalid';
        return null;
      },
    );
  }
}