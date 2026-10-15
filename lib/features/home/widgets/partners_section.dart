import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';

class PartnersSection extends StatefulWidget {
  const PartnersSection({
    this.partners,
    this.onViewAllTap,
    this.onPartnerTap,
    super.key,
  });

  final List<Partner>? partners;
  final VoidCallback? onViewAllTap;
  final ValueChanged<Partner>? onPartnerTap;

  @override
  State<PartnersSection> createState() => _PartnersSectionState();
}

class _PartnersSectionState extends State<PartnersSection> {
  final PartnersService _partnersService = PartnersService();
  List<Partner> _partners = [];
  bool _loading = false;
  VoidCallback? _languageListener;

  @override
  void initState() {
    super.initState();
    _languageListener = () {
      if (widget.partners == null && mounted) {
        _loadPartners();
      }
    };
    AppLocalizations.languageNotifier.addListener(_languageListener!);

    if (widget.partners != null) {
      _partners = widget.partners!;
    } else {
      _loadPartners();
    }
  }

  @override
  void dispose() {
    if (_languageListener != null) {
      AppLocalizations.languageNotifier.removeListener(_languageListener!);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PartnersSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.partners != null && widget.partners != oldWidget.partners) {
      setState(() {
        _partners = widget.partners!;
      });
    }
  }

  Future<void> _loadPartners() async {
    setState(() => _loading = true);
    try {
      final list = await _partnersService.getAllPartners(
        languageCode: AppLocalizations.currentLanguageCode,
      );
      if (mounted) {
        setState(() {
          _partners = list;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildFallback(Partner partner, Color textColor, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.storefront_rounded,
          size: 24,
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        ),
        const SizedBox(height: 4),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final cardBg = isDark ? const Color(0xFF1F1F1F) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    if (!_loading && _partners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tr('home_partners'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: textColor,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onViewAllTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tr('home_view_all'),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.base,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.base,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Horizontal Partners List
          SizedBox(
            height: 70,
            child: _loading
                ? ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: 4,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) => Container(
                      width: 110,
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1F1F1F)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _partners.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final partner = _partners[index];
                      final imageUrl = partner.imageUrl;

                      return Container(
                        width: 110,
                        height: 70,
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => widget.onPartnerTap?.call(partner),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: (imageUrl != null && imageUrl.isNotEmpty)
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        imageUrl,
                                        headers: ApiClient.instance.authHeaders,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildFallback(partner, textColor, isDark),
                                        loadingBuilder:
                                            (context, child, loadingProgress) {
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
                                    )
                                  : _buildFallback(partner, textColor, isDark),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
