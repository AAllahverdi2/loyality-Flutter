import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/widgets/skeleton.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';

class PartnerDetailScreen extends StatefulWidget {
  const PartnerDetailScreen({required this.id, this.initialPartner, super.key});

  final String id;
  final Partner? initialPartner;

  @override
  State<PartnerDetailScreen> createState() => _PartnerDetailScreenState();
}

class _PartnerDetailScreenState extends State<PartnerDetailScreen> {
  final PartnersService _partnersService = PartnersService();
  Partner? _partner;
  String? _categoryName;
  bool _loading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _partner = widget.initialPartner;
    _isFavorite =
        widget.initialPartner?.isFavorite ??
        PartnersService.favoriteIdsNotifier.value.contains(widget.id);
    _categoryName = widget.initialPartner?.categoryName;
    _loadPartnerDetails();
  }

  Future<void> _loadPartnerDetails() async {
    setState(() => _loading = true);
    try {
      final partner = await _partnersService.getPartnerById(id: widget.id);

      if (mounted && partner != null) {
        setState(() {
          _partner = partner;
          _isFavorite =
              partner.isFavorite ||
              PartnersService.favoriteIdsNotifier.value.contains(widget.id);
          _categoryName = partner.categoryName ?? _categoryName;
          _loading = false;
        });
      } else if (mounted) {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  bool _isTogglingFavorite = false;

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;
    _isTogglingFavorite = true;

    final wasFavorite = _isFavorite;
    // 1. Optimistic UI update: Ürək dərhal vizual olaraq dəyişsin
    setState(() {
      _isFavorite = !_isFavorite;
      if (_partner != null) {
        _partner = _partner!.copyWith(isFavorite: _isFavorite);
      }
    });

    // 2. Serverə sorğu göndərilir:
    // Əgər false idisə -> POST /api/Partners/myFavorites/add/{partnerId}
    // Əgər true idisə -> DELETE /api/Partners/myFavorites/remove/{partnerId}
    final success = await _partnersService.toggleFavorite(
      partnerId: widget.id,
      isCurrentlyFavorite: wasFavorite,
    );

    // 3. Əgər serverdə xəta baş verərsə, vəziyyət geri qaytarılır (rollback)
    if (!success && mounted) {
      setState(() {
        _isFavorite = wasFavorite;
        if (_partner != null) {
          _partner = _partner!.copyWith(isFavorite: wasFavorite);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('common_error_retry')),
          duration: const Duration(seconds: 2),
        ),
      );
    }

    _isTogglingFavorite = false;
  }

  Widget _buildSkeleton(BuildContext context, bool isDark, double bottomInset) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: 40 + (bottomInset > 0 ? bottomInset : 16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Skeleton(
              width: double.infinity,
              height: 220,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(
                  width: 200,
                  height: 26,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 12),
                Skeleton(
                  width: 120,
                  height: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 24),
                Skeleton(
                  width: 100,
                  height: 20,
                  borderRadius: BorderRadius.circular(6),
                ),
                const SizedBox(height: 12),
                Skeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Skeleton(
                  width: double.infinity,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Skeleton(
                  width: 250,
                  height: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage(bool isDark, Color textColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.storefront_rounded,
          size: 64,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(height: 8),
        Text(
          _partner?.name ?? tr('partner_default_name'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);
    final textColor = isDark
        ? const Color(0xFFFFFFFF)
        : const Color(0xFF111827);
    final secondaryTextColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF6B7280);
    final borderColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFF3F4F6);
    final dividerColor = isDark
        ? const Color(0xFF333333)
        : const Color(0xFFE5E7EB);
    final imageBg = isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6);

    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final partner = _partner;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_isFavorite);
      },
      child: SwipeBackWrapper(
        onSwipeBack: () => Navigator.of(context).pop(_isFavorite),
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(_isFavorite),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 22,
                            color: textColor,
                          ),
                        ),
                      ),
                      Text(
                        tr('partner_detail_title'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFavorite,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            _isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 24,
                            color: _isFavorite
                                ? const Color(0xFFEF4444)
                                : secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: (_loading && partner == null)
                      ? _buildSkeleton(context, isDark, bottomInset)
                      : RefreshIndicator(
                          onRefresh: _loadPartnerDetails,
                          color: AppColors.base,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.only(
                              bottom: 40 + (bottomInset > 0 ? bottomInset : 16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Image Container (Big Rounded Banner Box)
                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Container(
                                    width: double.infinity,
                                    height: 220,
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: imageBg,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: isDark ? 0.25 : 0.05,
                                          ),
                                          offset: const Offset(0, 4),
                                          blurRadius: 12,
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child:
                                        (partner?.imageUrl != null &&
                                            partner!.imageUrl!.isNotEmpty)
                                        ? Image.network(
                                            partner.imageUrl!,
                                            headers:
                                                ApiClient.instance.authHeaders,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildFallbackImage(
                                                      isDark,
                                                      textColor,
                                                    ),
                                            loadingBuilder:
                                                (
                                                  context,
                                                  child,
                                                  loadingProgress,
                                                ) {
                                                  if (loadingProgress == null) {
                                                    return child;
                                                  }
                                                  return Center(
                                                    child: SizedBox(
                                                      width: 24,
                                                      height: 24,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color:
                                                                AppColors.base,
                                                          ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : _buildFallbackImage(
                                            isDark,
                                            textColor,
                                          ),
                                  ),
                                ),

                                // Info Section (Title + Discount badge + Category)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              partner?.name ?? '',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                          ),
                                          if ((partner?.displayDiscountBadge ??
                                                      partner?.discount) !=
                                                  null &&
                                              (partner!.displayDiscountBadge ??
                                                      partner.discount)!
                                                  .isNotEmpty) ...[
                                            const SizedBox(width: 12),
                                            Flexible(
                                              fit: FlexFit.loose,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.base
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  partner.displayDiscountBadge ??
                                                      partner.discount!,
                                                  softWrap: true,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColors.base,
                                                    height: 1.25,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.local_offer_outlined,
                                            size: 16,
                                            color: secondaryTextColor,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _categoryName ??
                                                partner?.categoryName ??
                                                tr('partner_default_name'),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w500,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Aktiv Təkliflər Siyahısı (discounts massivi varsa)
                                if (partner != null &&
                                    partner.discounts.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${tr('partner_detail_active_offers')} (${partner.discounts.length})',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: textColor,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        ...partner.discounts.map(
                                          (d) => Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF1E1E1E)
                                                  : const Color(0xFFF9FAFB),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              border: Border.all(
                                                color: borderColor,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.base
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: const Icon(
                                                    Icons.local_offer_rounded,
                                                    size: 18,
                                                    color: AppColors.base,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        d.title,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: textColor,
                                                        ),
                                                      ),
                                                      if (d.discountText !=
                                                              null &&
                                                          d.discountText!
                                                              .trim()
                                                              .isNotEmpty &&
                                                          d.discountText !=
                                                              d.title) ...[
                                                        const SizedBox(
                                                          height: 2,
                                                        ),
                                                        Text(
                                                          d.discountText!,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
                                                                color: AppColors
                                                                    .base,
                                                              ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Divider Line
                                Container(
                                  height: 1,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  color: dividerColor,
                                ),

                                // Description Section ("Haqqında")
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tr('partner_detail_about'),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        (partner?.description != null &&
                                                partner!.description!
                                                    .trim()
                                                    .isNotEmpty)
                                            ? partner.description!.trim()
                                            : tr('partner_detail_no_desc'),
                                        textAlign: TextAlign.justify,
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.6,
                                          fontWeight: FontWeight.w400,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
