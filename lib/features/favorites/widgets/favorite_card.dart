import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/discounts/models/partner_offer.dart';
import 'package:loyallig_flutter/features/favorites/models/favorite_item.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';

class FavoriteCard extends StatelessWidget {
  const FavoriteCard({
    this.item,
    this.partner,
    this.offer,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = true,
    super.key,
  }) : assert(item != null || partner != null || offer != null);

  final FavoriteItem? item;
  final Partner? partner;
  final PartnerOffer? offer;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  Widget _buildLogo(bool isDark, Color inputBg, Color textColor, Color secondaryTextColor) {
    if (offer != null) {
      final imageUrl = offer!.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            headers: ApiClient.instance.authHeaders,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.local_offer_rounded,
              size: 28,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.base,
                  ),
                ),
              );
            },
          ),
        );
      }
      return Icon(
        Icons.local_offer_rounded,
        size: 28,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      );
    }

    if (partner != null) {
      final imageUrl = partner!.imageUrl;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrl,
            headers: ApiClient.instance.authHeaders,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => Icon(
              Icons.storefront_rounded,
              size: 28,
              color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
            ),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.base,
                  ),
                ),
              );
            },
          ),
        );
      }
      return Icon(
        Icons.storefront_rounded,
        size: 28,
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
      );
    }

    if (item != null) {
      return Image.asset(
        item!.image,
        fit: BoxFit.contain,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final inputBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF3F4F6);
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    final title = offer?.title ?? partner?.name ?? item?.name ?? '';
    final category = offer != null
        ? (offer!.partnerName ?? offer!.offerTypeName ?? 'Təklif')
        : (partner?.categoryName ?? item?.category ?? 'Tərəfdaş');
    final discount = offer?.discountText ??
        (offer?.discountPercent != null ? '%${offer!.discountPercent} Endirim' : null) ??
        partner?.discount ??
        item?.discount;
    final description = offer?.description ?? partner?.description;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Logo Alanı: 60x60, borderRadius: 12
                Container(
                  width: 60,
                  height: 60,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: inputBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _buildLogo(isDark, inputBg, textColor, secondaryTextColor),
                ),

                // Bilgi Alanı
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (discount != null && discount.trim().isNotEmpty)
                        Text(
                          discount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.base,
                          ),
                        )
                      else if (description != null && description.trim().isNotEmpty)
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: secondaryTextColor,
                          ),
                        ),
                    ],
                  ),
                ),

                // Sevimlidən çıxartma ürək düyməsi
                if (onFavoriteToggle != null)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onFavoriteToggle,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 24,
                        color: isFavorite
                            ? const Color(0xFFEF4444)
                            : secondaryTextColor,
                      ),
                    ),
                  ),

                // Ok İkonu: chevron-forward
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: secondaryTextColor,
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
