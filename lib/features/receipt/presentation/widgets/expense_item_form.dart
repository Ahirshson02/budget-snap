import 'package:budget_snap/core/theme/app_theme.dart';
import 'package:budget_snap/core/utils/currency_input_formatter.dart';
import 'package:budget_snap/core/utils/responsive.dart';
import 'package:budget_snap/core/utils/validators.dart';
import 'package:budget_snap/features/budget/domain/models/category.dart';
import 'package:budget_snap/features/receipt/presentation/widgets/category_dropdown.dart';
import 'package:flutter/material.dart';


class LineItemRow extends StatelessWidget {
  const LineItemRow({
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
    final theme = Theme.of(context);
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
                        child: NameField(controller: nameController),
                      ),
                      SizedBox(width: context.widthFraction(0.02)),
                      Expanded(
                        flex: 2,
                        child: PriceField(controller: priceController),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    NameField(controller: nameController),
                    SizedBox(
                        height: context.heightFraction(0.01).clamp(6.0, 10.0)),
                    PriceField(controller: priceController),
                  ],
                );
              },
            ),

            // if (categories.isNotEmpty) ...[
            //   SizedBox(height: context.heightFraction(0.01).clamp(6.0, 10.0)),
            //   CategoryDropdown(
            //     label: 'Item Category',
            //     value: selectedCategoryId,
            //     categories: categories,
            //     onChanged: onCategoryChanged,
            //   ),
            // ],
          ],
        ),
      ),
    );
  }
}



class NameField extends StatelessWidget {
  const NameField({required this.controller});

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

class PriceField extends StatelessWidget {
  const PriceField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [CurrencyInputFormatter()],
      decoration: const InputDecoration(
        labelText: 'Price',
        prefixText: '\$ ',
        isDense: true,
      ),
      validator: Validators.compose([
        Validators.required('Required'),
        Validators.positiveAmount(),
      ]),
    );
  }
}