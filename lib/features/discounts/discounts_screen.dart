import 'dart:async';
import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/widgets/app_bottom_nav.dart';
import 'package:loyallig_flutter/features/discounts/models/partner_offer.dart';
import 'package:loyallig_flutter/features/discounts/services/discounts_service.dart';
import 'package:loyallig_flutter/features/discounts/widgets/discounts_filter_bottom_sheet.dart';
import 'package:loyallig_flutter/features/favorites/partner_detail_screen.dart';
import 'package:loyallig_flutter/features/favorites/widgets/favorite_card.dart';
import 'package:loyallig_flutter/features/favorites/widgets/favorites_header.dart';
import 'package:loyallig_flutter/features/favorites/widgets/favorites_skeleton.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key});

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  final DiscountsService _discountsService = DiscountsService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  bool _loading = true;
  String? _errorMessage;
  List<PartnerOffer> _offers = [];

  String? _selectedPartnerId;
  String? _selectedOfferTypeId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _selectedPartnerId != null || _selectedOfferTypeId != null;

  Future<void> _loadOffers({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await _discountsService.getPartnerOffers(
        partnerId: _selectedPartnerId,
        offerTypeId: _selectedOfferTypeId,
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      if (mounted) {
        setState(() {
          _offers = items;
          _loading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Məlumatları yükləmək mümkün olmadı: $e';
          _loading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
      });
      _loadOffers(showLoading: false);
    });
  }

  Future<void> _openFilterSheet() async {
    final result = await DiscountsFilterBottomSheet.show(
      context,
      initialPartnerId: _selectedPartnerId,
      initialOfferTypeId: _selectedOfferTypeId,
    );

    if (result != null) {
      setState(() {
        _selectedPartnerId = result.partnerId;
        _selectedOfferTypeId = result.offerTypeId;
      });
      _loadOffers(showLoading: true);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedPartnerId = null;
      _selectedOfferTypeId = null;
    });
    _loadOffers(showLoading: true);
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color secondaryTextColor) {
    final hasCriteria = _hasActiveFilters || _searchQuery.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 34,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              hasCriteria
                  ? tr('discounts_no_offers_found')
                  : tr('discounts_empty_title'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasCriteria
                  ? tr('discounts_empty_search_desc')
                  : tr('discounts_empty_desc'),
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasCriteria) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  _searchQuery = '';
                  _clearFilters();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(tr('discounts_reset_filters')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.base,
                  side: const BorderSide(color: AppColors.base),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 40,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 12),
            Text(
              tr('discounts_error_occurred'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadOffers(showLoading: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.base,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(tr('discounts_retry')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: FavoritesSkeleton(),
          ),
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: 0,
          onTap: (index) => MainScreen.navigateToTab(context, index),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _loadOffers(showLoading: false),
          color: AppColors.base,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 24,
            ),
            itemCount: 1 +
                (_errorMessage != null
                    ? 1
                    : (_offers.isEmpty ? 1 : _offers.length)),
            itemBuilder: (context, index) {
              // 0: Header with search input & filter button
              if (index == 0) {
                return FavoritesHeader(
                  title: tr('discounts_title'),
                  showBackButton: true,
                  searchHint: tr('discounts_search_placeholder'),
                  searchController: _searchController,
                  showFilterButton: true,
                  hasActiveFilters: _hasActiveFilters,
                  onFilterTap: _openFilterSheet,
                  onSearchChanged: _onSearchChanged,
                );
              }

              final contentIndex = index - 1;

              if (_errorMessage != null) {
                return _buildErrorState(isDark, textColor, secondaryTextColor);
              }

              if (_offers.isEmpty) {
                return _buildEmptyState(isDark, textColor, secondaryTextColor);
              }

              final offer = _offers[contentIndex];
              return FavoriteCard(
                offer: offer,
                onTap: () {
                  final targetId = (offer.partnerId != null &&
                          offer.partnerId!.trim().isNotEmpty)
                      ? offer.partnerId!.trim()
                      : offer.id;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PartnerDetailScreen(id: targetId),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) => MainScreen.navigateToTab(context, index),
      ),
    );
  }
}
