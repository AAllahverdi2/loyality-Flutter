import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/favorites/partner_detail_screen.dart';
import 'package:loyallig_flutter/features/favorites/widgets/favorite_card.dart';
import 'package:loyallig_flutter/features/favorites/widgets/favorites_header.dart';
import 'package:loyallig_flutter/features/favorites/widgets/favorites_skeleton.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({
    this.isActive = true,
    super.key,
  });

  final bool isActive;

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final PartnersService _partnersService = PartnersService();
  List<Partner> _favorites = [];
  bool _loading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    PartnersService.favoritesVersionNotifier.addListener(_onFavoritesUpdated);
    _loadFavorites();
  }

  @override
  void didUpdateWidget(covariant FavoritesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      // İstifadəçi menyudan Sevimlilər tabına keçən kimi siyahını avtomatik ən son vəziyyətə gətirsin
      _loadFavorites(showLoading: _favorites.isEmpty);
    }
  }

  @override
  void dispose() {
    PartnersService.favoritesVersionNotifier.removeListener(_onFavoritesUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onFavoritesUpdated() {
    if (!mounted) return;
    // Sevimlilərdə kənardan dəyişiklik olanda arxa planda dərhal təzələnsin
    _loadFavorites(showLoading: false);
  }

  /// Real API-dən istifadəçinin sevimlilər siyahısını gətirir (/api/Partners/myFavorites)
  Future<void> _loadFavorites({bool showLoading = true}) async {
    if (showLoading && _favorites.isEmpty) {
      setState(() => _loading = true);
    }
    try {
      final list = await _partnersService.getMyFavorites();
      if (mounted) {
        setState(() {
          _favorites = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  /// Axtarış sözünə görə filtrlənmiş tərəfdaşlar
  List<Partner> get _filteredPartners {
    if (_searchQuery.trim().isEmpty) {
      return _favorites;
    }
    final query = _searchQuery.toLowerCase().trim();
    return _favorites.where((partner) {
      final name = partner.name.toLowerCase();
      final category = (partner.categoryName ?? '').toLowerCase();
      final desc = (partner.description ?? '').toLowerCase();
      final discount = (partner.discount ?? '').toLowerCase();
      return name.contains(query) ||
          category.contains(query) ||
          desc.contains(query) ||
          discount.contains(query);
    }).toList();
  }

  /// Tərəfdaşı sevimlilərdən silir (/api/Partners/myFavorites/remove/{partnerId})
  Future<void> _removeFavorite(Partner partner) async {
    final originalList = List<Partner>.from(_favorites);

    // 1. Optimistic UI update: Siyahıdan dərhal silinsin
    setState(() {
      _favorites.removeWhere((item) => item.id == partner.id);
    });

    // 2. Serverə DELETE sorğusu göndərilir
    final success = await _partnersService.removeFromFavorites(partner.id);

    // 3. Əgər uğursuz olarsa, geri qaytarılır (rollback)
    if (!success && mounted) {
      setState(() {
        _favorites = originalList;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xəta baş verdi. Zəhmət olmasa yenidən cəhd edin.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildEmptyState(bool isDark, Color textColor, Color secondaryTextColor) {
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1F2937)
                    : AppColors.base.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.favorite_border_rounded,
                size: 38,
                color: isSearching ? secondaryTextColor : AppColors.base,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching
                  ? 'Axtarışa uyğun tərəfdaş tapılmadı'
                  : tr('favorites_empty_title'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Fərqli açar sözlərlə axtarmağı yoxlayın.'
                  : tr('favorites_empty_desc'),
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: secondaryTextColor,
              ),
              textAlign: TextAlign.center,
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
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 30),
            child: FavoritesSkeleton(),
          ),
        ),
      );
    }

    final items = _filteredPartners;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _loadFavorites,
          color: AppColors.base,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: 30,
            ),
            itemCount: items.isEmpty ? 2 : items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return FavoritesHeader(
                  title: tr('favorites_title'),
                  searchHint: tr('discounts_search'),
                  searchController: _searchController,
                  onSearchChanged: (query) {
                    setState(() => _searchQuery = query);
                  },
                );
              }

              if (items.isEmpty) {
                return _buildEmptyState(isDark, textColor, secondaryTextColor);
              }

              final partner = items[index - 1];
              return FavoriteCard(
                partner: partner,
                isFavorite: true,
                onFavoriteToggle: () => _removeFavorite(partner),
                onTap: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute<bool>(
                      builder: (_) => PartnerDetailScreen(
                        id: partner.id,
                        initialPartner: partner,
                      ),
                    ),
                  );
                  // Əgər detal səhifəsində sevimli statusu dəyişibsə və ya qayıdılıbsa, siyahını sinxron saxlayırıq
                  if (result == false && mounted) {
                    setState(() {
                      _favorites.removeWhere((item) => item.id == partner.id);
                    });
                  } else if (mounted) {
                    _loadFavorites(showLoading: false);
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
