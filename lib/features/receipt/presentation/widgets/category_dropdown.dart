import 'package:budget_snap/features/budget/domain/models/category.dart';
import 'package:flutter/material.dart';

class CategoryDropdown extends StatelessWidget {
  const CategoryDropdown({
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



