import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';

class FavoritesHeader extends StatelessWidget {
  const FavoritesHeader({
    this.title = 'Seçilmişlər',
    this.onSearchChanged,
    this.searchController,
    this.showBackButton = false,
    this.onBackTap,
    this.showFilterButton = false,
    this.onFilterTap,
    this.hasActiveFilters = false,
    this.searchHint = 'Tərəfdaş axtar...',
    super.key,
  });

  final String title;
  final ValueChanged<String>? onSearchChanged;
  final TextEditingController? searchController;
  final bool showBackButton;
  final VoidCallback? onBackTap;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;
  final String searchHint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title: 28px bold, marginTop: 10, marginBottom: 20
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 20),
            child: Row(
              children: [
                if (showBackButton)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onBackTap ?? () => Navigator.of(context).pop(),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 24,
                        color: textColor,
                      ),
                    ),
                  ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),

          // Search + Filter Row (No outer padding or card background)
          Row(
            children: [
              // Search Input Field
              Expanded(
                child: Container(
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: onSearchChanged,
                          textAlignVertical: TextAlignVertical.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                          ),
                          decoration: InputDecoration(
                            hintText: searchHint,
                            hintStyle: TextStyle(
                              fontSize: 15,
                              color: secondaryTextColor,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter Button
              if (showFilterButton) ...[
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onFilterTap,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasActiveFilters
                          ? AppColors.base
                          : inputBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 22,
                          color: hasActiveFilters
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF111827)),
                        ),
                        if (hasActiveFilters)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
