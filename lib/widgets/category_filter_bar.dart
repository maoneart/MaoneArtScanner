import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/document_provider.dart';
import '../utils/app_theme.dart';

class CategoryFilterBar extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kDocumentCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = kDocumentCategories[index];
          final isSelected = category.toLowerCase() == selectedCategory.toLowerCase();

          return GestureDetector(
            onTap: () => onCategorySelected(category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.textMain : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppTheme.textMain : AppTheme.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  category,
                  style: GoogleFonts.plusJakartaSans(
                    color: isSelected ? const Color(0xFF09090B) : AppTheme.textMuted,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
