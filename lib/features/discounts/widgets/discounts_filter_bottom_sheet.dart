import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/models/lookup_item.dart';
import 'package:loyallig_flutter/features/discounts/services/discounts_service.dart';

class DiscountsFilterResult {
  final String? partnerId;
  final String? partnerName;
  final String? offerTypeId;
  final String? offerTypeName;

  const DiscountsFilterResult({
    this.partnerId,
    this.partnerName,
    this.offerTypeId,
    this.offerTypeName,
  });

  bool get hasActiveFilter =>
      (partnerId != null && partnerId!.isNotEmpty) ||
      (offerTypeId != null && offerTypeId!.isNotEmpty);
}

class DiscountsFilterBottomSheet extends StatefulWidget {
  const DiscountsFilterBottomSheet({
    this.initialPartnerId,
    this.initialOfferTypeId,
    super.key,
  });

  final String? initialPartnerId;
  final String? initialOfferTypeId;

  static Future<DiscountsFilterResult?> show(
    BuildContext context, {
    String? initialPartnerId,
    String? initialOfferTypeId,
  }) {
    return showModalBottomSheet<DiscountsFilterResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiscountsFilterBottomSheet(
        initialPartnerId: initialPartnerId,
        initialOfferTypeId: initialOfferTypeId,
      ),
    );
  }

  @override
  State<DiscountsFilterBottomSheet> createState() =>
      _DiscountsFilterBottomSheetState();
}

class _DiscountsFilterBottomSheetState
    extends State<DiscountsFilterBottomSheet> {
  final DiscountsService _discountsService = DiscountsService();

  List<LookupItem> _partners = [];
  List<LookupItem> _offerTypes = [];
  bool _loading = true;

  String? _selectedPartnerId;
  String? _selectedOfferTypeId;

  @override
  void initState() {
    super.initState();
    _selectedPartnerId = widget.initialPartnerId;
    _selectedOfferTypeId = widget.initialOfferTypeId;

    if (DiscountsService.hasLookupsCache) {
      _partners = DiscountsService.cachedPartners ?? [];
      _offerTypes = DiscountsService.cachedOfferTypes ?? [];
      _loading = false;
    } else {
      _loadLookups();
    }
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _discountsService.getLookupPartners(),
        _discountsService.getLookupOfferTypes(),
      ]);

      if (mounted) {
        setState(() {
          _partners = results[0];
          _offerTypes = results[1];
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedPartnerId = null;
      _selectedOfferTypeId = null;
    });
  }

  void _applyFilters() {
    String? partnerName;
    if (_selectedPartnerId != null) {
      for (final p in _partners) {
        if (p.value == _selectedPartnerId) {
          partnerName = p.label;
          break;
        }
      }
    }

    String? offerTypeName;
    if (_selectedOfferTypeId != null) {
      for (final o in _offerTypes) {
        if (o.value == _selectedOfferTypeId) {
          offerTypeName = o.label;
          break;
        }
      }
    }

    Navigator.of(context).pop(
      DiscountsFilterResult(
        partnerId: _selectedPartnerId,
        partnerName: partnerName,
        offerTypeId: _selectedOfferTypeId,
        offerTypeName: offerTypeName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final chipBg = isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6);
    final borderColor =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final hasChanges = (_selectedPartnerId != null &&
            _selectedPartnerId!.isNotEmpty) ||
        (_selectedOfferTypeId != null && _selectedOfferTypeId!.isNotEmpty);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Title + Clear
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('discounts_filters_title'),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (hasChanges)
                  GestureDetector(
                    onTap: _clearFilters,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Text(
                        tr('filter_reset'),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.base,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.base,
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Təklif Növü (Offer Types)
                        Text(
                          tr('discounts_offer_type'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSelectableChip(
                              label: tr('filter_all'),
                              isSelected: _selectedOfferTypeId == null,
                              onTap: () =>
                                  setState(() => _selectedOfferTypeId = null),
                              chipBg: chipBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            ..._offerTypes.map(
                              (item) => _buildSelectableChip(
                                label: item.label,
                                isSelected: _selectedOfferTypeId == item.value,
                                onTap: () {
                                  setState(() {
                                    if (_selectedOfferTypeId == item.value) {
                                      _selectedOfferTypeId = null;
                                    } else {
                                      _selectedOfferTypeId = item.value;
                                    }
                                  });
                                },
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // 2. Tərəfdaşlar (Partners)
                        Text(
                          tr('history_filter_partner'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSelectableChip(
                              label: tr('discounts_all_partners'),
                              isSelected: _selectedPartnerId == null,
                              onTap: () =>
                                  setState(() => _selectedPartnerId = null),
                              chipBg: chipBg,
                              borderColor: borderColor,
                              textColor: textColor,
                            ),
                            ..._partners.map(
                              (item) => _buildSelectableChip(
                                label: item.label,
                                isSelected: _selectedPartnerId == item.value,
                                onTap: () {
                                  setState(() {
                                    if (_selectedPartnerId == item.value) {
                                      _selectedPartnerId = null;
                                    } else {
                                      _selectedPartnerId = item.value;
                                    }
                                  });
                                },
                                chipBg: chipBg,
                                borderColor: borderColor,
                                textColor: textColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),

          // Bottom Action: Tətbiq et
          Container(
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              16 + (bottomInset > 0 ? bottomInset : 12),
            ),
            decoration: BoxDecoration(
              color: bg,
              border: Border(top: BorderSide(color: borderColor, width: 1)),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.base,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  tr('filter_apply'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectableChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color chipBg,
    required Color borderColor,
    required Color textColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.base : chipBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.base : borderColor,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}
