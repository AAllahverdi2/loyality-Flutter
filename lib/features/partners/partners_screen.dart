import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/widgets/app_bottom_nav.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';
import 'package:loyallig_flutter/features/favorites/partner_detail_screen.dart';
import 'package:loyallig_flutter/features/main/main_screen.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';
import 'package:loyallig_flutter/features/partners/models/partner_category.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';

class PartnersScreen extends StatefulWidget {
  const PartnersScreen({super.key});

  @override
  State<PartnersScreen> createState() => _PartnersScreenState();
}

class _PartnersScreenState extends State<PartnersScreen> {
  final PartnersService _partnersService = PartnersService();
  List<Partner> _partners = [];
  List<PartnerCategory> _categories = [];
  bool _categoriesLoading = true;
  bool _partnersLoading = true;
  bool _isRequestInProgress = false;
  DateTime? _lastCategoryTapTime;
  String _selectedCategoryId = 'all';
  final Set<String> _favoritePartnerIds = {};

  @override
  void initState() {
    super.initState();
    _favoritePartnerIds.addAll(PartnersService.favoriteIdsNotifier.value);
    PartnersService.favoriteIdsNotifier.addListener(_onGlobalFavoritesChanged);
    _loadData();
  }

  @override
  void dispose() {
    PartnersService.favoriteIdsNotifier.removeListener(_onGlobalFavoritesChanged);
    super.dispose();
  }

  void _onGlobalFavoritesChanged() {
    if (!mounted) return;
    setState(() {
      _favoritePartnerIds
        ..clear()
        ..addAll(PartnersService.favoriteIdsNotifier.value);
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _categoriesLoading = true;
      _partnersLoading = true;
    });
    try {
      final results = await Future.wait([
        _partnersService.getAllPartners(),
        _partnersService.getCategories(),
      ]);

      if (mounted) {
        final partners = results[0] as List<Partner>;
        final categories = results[1] as List<PartnerCategory>;

        setState(() {
          _partners = partners;
          _categories = categories;
          for (final p in partners) {
            if (p.isFavorite) {
              _favoritePartnerIds.add(p.id);
            }
          }
          _categoriesLoading = false;
          _partnersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { 
          _categoriesLoading = false;
          _partnersLoading = false;
        });
      }
    }
  }

  Future<void> _onCategorySelected(String categoryId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _selectedCategoryId == categoryId) return;

    if (_partnersLoading || _isRequestInProgress) return;
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastCategoryTapTime != null &&
        now.difference(_lastCategoryTapTime!) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastCategoryTapTime = now;
    _isRequestInProgress = true;

    setState(() {
      _selectedCategoryId = categoryId;
      _partnersLoading = true;
    });

    try {
      final partners = await _partnersService.getAllPartners(
        partnerCategoryId: categoryId == 'all' ? null : categoryId,
      );
      if (mounted) {
        setState(() {
          _partners = partners;
          for (final p in partners) {
            if (p.isFavorite) {
              _favoritePartnerIds.add(p.id);
            }
          }
          _partnersLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _partnersLoading = false);
      }
    } finally {
      _isRequestInProgress = false;
    }
  }

  Future<void> _toggleFavorite(String partnerId) async {
    final isCurrentlyFav = _favoritePartnerIds.contains(partnerId);

    // 1. Optimistic UI update: Ürək ikonu dərhal vizual olaraq dəyişsin
    setState(() {
      if (isCurrentlyFav) {
        _favoritePartnerIds.remove(partnerId);
      } else {
        _favoritePartnerIds.add(partnerId);
      }
    });

    // 2. Serverə sorğu göndərilir:
    // isFavorite false idisə -> POST /api/Partners/myFavorites/add/{partnerId}
    // isFavorite true idisə -> DELETE /api/Partners/myFavorites/remove/{partnerId}
    final success = await _partnersService.toggleFavorite(
      partnerId: partnerId,
      isCurrentlyFavorite: isCurrentlyFav,
    );

    // 3. Əgər serverdə xəta baş verərsə, vəziyyət geri qaytarılır (rollback)
    if (!success && mounted) {
      setState(() {
        if (isCurrentlyFav) {
          _favoritePartnerIds.add(partnerId);
        } else {
          _favoritePartnerIds.remove(partnerId);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xəta baş verdi. Zəhmət olmasa yenidən cəhd edin.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<PartnerCategory> get _allCategories {
    return [
      PartnerCategory(id: 'all', name: tr('partners_category_all')),
      ..._categories,
    ];
  }

  String _getPartnerCategoryName(Partner partner) {
    if (partner.categoryName != null &&
        partner.categoryName!.trim().isNotEmpty) {
      return partner.categoryName!.trim();
    }
    if (partner.partnerCategoryId != null) {
      for (final cat in _categories) {
        if (cat.id == partner.partnerCategoryId) {
          return cat.name;
        }
      }
    }
    return tr('partner_default_name');
  }

  Widget _buildSkeletonList(double cardWidth, double cardHeight) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: List.generate(6, (index) {
        return Skeleton(
          width: cardWidth,
          height: cardHeight,
          borderRadius: BorderRadius.circular(20),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor =
        isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);
    final circleBtnBg =
        isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

    final allCategories = _allCategories;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Premium Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: circleBtnBg,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 24,
                        color: textColor,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        tr('partners_title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _partnersLoading
                            ? tr('common_loading')
                            : '${_partners.length} ${tr('partners_title')}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.base,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 36), // Balanced spacer
                ],
              ),
            ),

            // Category Filter Scroll (Loaded from /api/PartnerCategories/getAll)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(
                  bottom: BorderSide(
                    color: borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: _categoriesLoading && _categories.isEmpty
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: List.generate(
                          5,
                          (index) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Skeleton(
                              width: 80,
                              height: 34,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: allCategories.map((category) {
                          final isActive =
                              _selectedCategoryId == category.id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _onCategorySelected(category.id),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.base
                                      : (isDark
                                          ? const Color(0xFF374151)
                                          : const Color(0xFFF3F4F6)),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.2,
                                    color: isActive
                                        ? Colors.white
                                        : secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
            ),

            // Main Content Area with RefreshIndicator
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _onCategorySelected(_selectedCategoryId, forceRefresh: true),
                color: AppColors.base,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('partners_special_title'),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tr('partners_special_desc'),
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.4,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 24),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final cardWidth = (constraints.maxWidth - 16) / 2;
                          final cardHeight = cardWidth / 0.85;

                          if (_partnersLoading) {
                            return _buildSkeletonList(cardWidth, cardHeight);
                          }

                          if (_partners.isNotEmpty) {
                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: _partners.map((partner) {
                                final isFav = _favoritePartnerIds
                                    .contains(partner.id);
                                return _PartnerCard(
                                  partner: partner,
                                  discountBadgeText:
                                      partner.displayDiscountBadge,
                                  categoryName:
                                      _getPartnerCategoryName(partner),
                                  width: cardWidth,
                                  isFavorite: isFav,
                                  onFavoriteToggle: () =>
                                      _toggleFavorite(partner.id),
                                  cardBg: cardBg,
                                  textColor: textColor,
                                  secondaryTextColor: secondaryTextColor,
                                  isDark: isDark,
                                  onTap: () async {
                                    final updatedFavStatus =
                                        await Navigator.of(context).push<bool>(
                                      MaterialPageRoute<bool>(
                                        builder: (_) => PartnerDetailScreen(
                                          id: partner.id,
                                          initialPartner: partner.copyWith(
                                            isFavorite: isFav,
                                          ),
                                        ),
                                      ),
                                    );
                                    if (updatedFavStatus != null && mounted) {
                                      setState(() {
                                        if (updatedFavStatus) {
                                          _favoritePartnerIds.add(partner.id);
                                        } else {
                                          _favoritePartnerIds.remove(partner.id);
                                        }
                                      });
                                    }
                                  },
                                );
                              }).toList(),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: secondaryTextColor,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    tr('partners_empty'),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onTap: (index) => MainScreen.navigateToTab(context, index),
      ),
    );
  }
}

class _PartnerCard extends StatelessWidget {
  const _PartnerCard({
    required this.partner,
    this.discountBadgeText,
    required this.categoryName,
    required this.width,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.cardBg,
    required this.textColor,
    required this.secondaryTextColor,
    required this.isDark,
    required this.onTap,
  });

  final Partner partner;
  final String? discountBadgeText;
  final String categoryName;
  final double width;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final Color cardBg;
  final Color textColor;
  final Color secondaryTextColor;
  final bool isDark;
  final VoidCallback onTap;

  Widget _buildFallback(Partner partner, Color textColor, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.storefront_rounded,
          size: 38,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            partner.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardHeight = width / 0.85;
    final imageUrl = partner.imageUrl;
    final discount = discountBadgeText ?? partner.displayDiscountBadge ?? partner.discount;

    return Container(
      width: width,
      height: cardHeight,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: isDark
            ? Border.all(color: const Color(0xFF374151), width: 1)
            : Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Stack(
            children: [
              // Discount Badge (Top Left with max width and wrapping)
              if (discount != null && discount.trim().isNotEmpty)
                Positioned(
                  top: 10,
                  left: 10,
                  right: 44, // Ürək düyməsi ilə toqquşmanın qarşısını tam alır
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.base.withValues(alpha: 0.22)
                            : AppColors.base.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.local_offer_rounded,
                            size: 11,
                            color: AppColors.base,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              discount.trim(),
                              maxLines: 2,
                              softWrap: true,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.base,
                                height: 1.15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Favorite Heart Button (Top Right)
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onFavoriteToggle,
                  child: Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    child: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 20,
                      color: isFavorite
                          ? const Color(0xFFEF4444)
                          : secondaryTextColor,
                    ),
                  ),
                ),
              ),

              // Center Logo + Footer
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 42, 14, 12),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: FractionallySizedBox(
                          widthFactor: 0.78,
                          heightFactor: 0.78,
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  headers: ApiClient.instance.authHeaders,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallback(
                                          partner, textColor, isDark),
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.base,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : _buildFallback(partner, textColor, isDark),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      partner.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      categoryName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

