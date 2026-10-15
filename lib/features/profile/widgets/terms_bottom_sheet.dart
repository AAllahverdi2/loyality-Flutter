import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/profile/models/terms_and_condition.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';
import 'package:url_launcher/url_launcher.dart';

class TermsBottomSheet extends StatefulWidget {
  const TermsBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TermsBottomSheet(),
    );
  }

  @override
  State<TermsBottomSheet> createState() => _TermsBottomSheetState();
}

class _TermsBottomSheetState extends State<TermsBottomSheet> {
  final ProfileService _profileService = ProfileService();
  bool _loading = true;
  List<TermsAndCondition> _terms = [];

  static final List<TermsAndCondition> _defaultTerms = [
    const TermsAndCondition(
      id: '1',
      title: '1. Ümumi Müddəalar',
      description:
          'Bu "İstifadəçi Razılaşması" (bundan sonra "Razılaşma") sizin "Azera" mobil tətbiqindən istifadənizi tənzimləyir. Tətbiqi yükləməklə və ya istifadə etməklə siz bu şərtləri qəbul etmiş sayılırsınız.',
    ),
    const TermsAndCondition(
      id: '2',
      title: '2. Qeydiyyat və Təhlükəsizlik',
      description:
          'Tətbiqdən tam istifadə etmək üçün hesab yaratmalısınız. Hesab məlumatlarınızın məxfiliyini qorumaq sizin məsuliyyətinizdədir. Şifrənizi üçüncü şəxslərlə paylaşmayın.',
    ),
    const TermsAndCondition(
      id: '3',
      title: '3. Bonus və Loyallıq Sistemi',
      description:
          'Qazanılan bonuslar real pula çevrilə bilməz. Bonuslar yalnız tərəfdaş mağazalarda və ya tətbiq daxilində təklif olunan xidmətlər üçün istifadə edilə bilər.',
    ),
    const TermsAndCondition(
      id: '4',
      title: '4. Məxfilik və Məlumatların Qorunması',
      description:
          'İstifadəçilərin şəxsi məlumatları qanunvericiliyin tələblərinə uyğun olaraq qorunur və üçüncü tərəflərə ötürülmür. Məlumatlar yalnız xidmət keyfiyyətinin artırılması məqsədilə emal edilir.',
    ),
    const TermsAndCondition(
      id: '5',
      title: '5. Dəyişikliklər və Xitam',
      description:
          'Şirkət istənilən vaxt qaydalar və şərtlərə dəyişiklik etmək hüququnu özündə saxlayır. Yenilənmiş şərtlər tətbiqdə dərc edildiyi andan qüvvəyə minir.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchTerms();
  }

  Future<void> _fetchTerms() async {
    setState(() {
      _loading = true;
    });

    try {
      final items = await _profileService.getTermsAndConditions(
        languageCode: AppLocalizations.currentLanguageCode,
      );
      if (mounted) {
        setState(() {
          _terms = items.isNotEmpty ? items : _defaultTerms;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _terms = _defaultTerms;
          _loading = false;
        });
      }
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  List<String> _extractUrls(String? text) {
    if (text == null || text.isEmpty) return [];
    final matches = RegExp(r'https?://[^\s<>"]+').allMatches(text);
    return matches.map((m) => m.group(0)!).toSet().toList();
  }

  String _formatTitle(int index, String title) {
    final trimmed = title.trim();
    if (RegExp(r'^\d+[\.\-\)]').hasMatch(trimmed)) {
      return trimmed;
    }
    return '${index + 1}. $trimmed';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final modalBg = isDark ? const Color(0xFF18181B) : Colors.white;
    final cardBg = isDark ? const Color(0xFF22242A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final bodyTextColor =
        isDark ? const Color(0xFFD1D5DB) : const Color(0xFF4B5563);
    final borderColor =
        isDark ? const Color(0xFF333742) : const Color(0xFFE5E7EB);
    final handleColor =
        isDark ? const Color(0xFF3F3F46) : const Color(0xFFD1D5DB);
    const iconBgColor = Color(0xFFEFF6FF);
    const iconColor = Color(0xFF2563EB);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.90,
      ),
      decoration: BoxDecoration(
        color: modalBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: handleColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                24 + (bottomInset > 0 ? bottomInset : 12),
              ),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : iconBgColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.description_rounded,
                      size: 26,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    tr('terms_title'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),

                  // Last updated
                  Text(
                    tr('terms_last_updated'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: secondaryTextColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Description prompt
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      tr('terms_subtitle'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: secondaryTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Loading or Cards
                  if (_loading && _terms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: iconColor,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._terms.asMap().entries.map((entry) {
                      final index = entry.key;
                      final term = entry.value;
                      final title = _formatTitle(index, term.title);
                      final plain = term.plainDescription;
                      final urls = _extractUrls(term.description);

                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: borderColor,
                            width: 1.2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (plain.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                plain,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.55,
                                  color: bodyTextColor,
                                ),
                              ),
                            ],
                            if (urls.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: urls.map((url) {
                                  return InkWell(
                                    onTap: () => _openUrl(url),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.open_in_new_rounded,
                                            size: 14,
                                            color: iconColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              url,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: iconColor,
                                                decoration:
                                                    TextDecoration.underline,
                                                decorationColor: iconColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
