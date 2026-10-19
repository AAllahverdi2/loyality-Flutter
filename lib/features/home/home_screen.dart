import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/features/chat/chat_topics_screen.dart';
import 'package:loyallig_flutter/features/discounts/discounts_screen.dart';
import 'package:loyallig_flutter/features/favorites/partner_detail_screen.dart';
import 'package:loyallig_flutter/features/notifications/notifications_screen.dart';
import 'package:loyallig_flutter/features/home/barcode_screen.dart';
import 'package:loyallig_flutter/features/partners/partners_screen.dart';
import 'package:loyallig_flutter/features/history/models/wallet_balance.dart';
import 'package:loyallig_flutter/features/history/services/wallet_service.dart';
import 'package:loyallig_flutter/features/home/models/app_banner.dart';
import 'package:loyallig_flutter/features/home/services/banner_service.dart';
import 'package:loyallig_flutter/features/home/widgets/campaign_slider.dart';
import 'package:loyallig_flutter/features/home/widgets/home_header.dart';
import 'package:loyallig_flutter/features/home/widgets/home_skeleton.dart';
import 'package:loyallig_flutter/features/home/widgets/menu_grid.dart';
import 'package:loyallig_flutter/features/home/widgets/partners_section.dart';
import 'package:loyallig_flutter/features/home/widgets/premium_card.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';
import 'package:loyallig_flutter/features/partners/services/partners_service.dart';
import 'package:loyallig_flutter/features/profile/models/user_profile.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    this.onNavigateToTab,
    super.key,
  });

  final ValueChanged<int>? onNavigateToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  final ProfileService _profileService = ProfileService();
  final WalletService _walletService = WalletService();
  final BannerService _bannerService = BannerService();
  final PartnersService _partnersService = PartnersService();

  String? _barcode;
  String? _userName;
  WalletBalance? _walletBalance;
  List<AppBanner>? _banners;
  List<Partner>? _partners;
  bool _loading = true;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    if (ProfileService.cachedBarcode != null) {
      _barcode = ProfileService.cachedBarcode;
    }
    if (WalletService.cachedBalance != null) {
      _walletBalance = WalletService.cachedBalance;
    }
    _initUserName();
    _loadData();
  }

  void _initUserName() {
    final cached = ProfileService.cachedProfile;
    if (cached != null) {
      final name = _getNameFromProfile(cached);
      if (name != null && name.isNotEmpty) {
        _userName = name;
      }
    }
    TokenStorage.getUserFullName().then((name) {
      if (mounted && name != null && name.isNotEmpty && _userName == null) {
        setState(() => _userName = name);
      }
    });
  }

  String? _getNameFromProfile(UserProfile? profile) {
    if (profile == null) return null;
    final first = profile.firstName?.trim() ?? '';
    final last = profile.lastName?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    if (profile.fullName != null && profile.fullName!.trim().isNotEmpty) {
      return profile.fullName!.trim();
    }
    return null;
  }

  Future<void> _loadData({bool force = false}) async {
    // 1. Sorğu artıq icra olunursa, təkrar sorğu göndərmirik
    if (_isFetching) return;

    // 2. Məlumatlar artıq varsa və məcburi yeniləmə deyilsə, şəbəkəyə getmirik
    if (!force &&
        _barcode != null &&
        _walletBalance != null &&
        _banners != null &&
        _partners != null &&
        _userName != null) {
      if (_loading && mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    _isFetching = true;
    try {
      final lang = AppLocalizations.currentLanguageCode;
      final results = await Future.wait([
        _profileService.getMyBarcode(forceRefresh: force).catchError((e) {
          debugPrint('Barkod xətası: $e');
          return null;
        }),
        _walletService.getMyBalance(forceRefresh: force).catchError((e) {
          debugPrint('Balans xətası: $e');
          return null;
        }),
        _bannerService.getBanners(languageCode: lang).catchError((e) {
          debugPrint('Bannerlər xətası: $e');
          return <AppBanner>[];
        }),
        _partnersService.getAllPartners(languageCode: lang).catchError((e) {
          debugPrint('Tərəfdaşlar xətası: $e');
          return <Partner>[];
        }),
        _profileService.getMyProfile(forceRefresh: force).catchError((e) {
          debugPrint('Profil xətası: $e');
          return null;
        }),
      ]);

      if (mounted) {
        final barcode = results[0] as String?;
        final wallet = results[1] as WalletBalance?;
        final banners = results[2] as List<AppBanner>?;
        final partners = results[3] as List<Partner>?;
        final profile = results[4] as UserProfile?;

        setState(() {
          if (barcode != null && barcode.isNotEmpty) {
            _barcode = barcode;
          }
          if (wallet != null) {
            _walletBalance = wallet;
          }
          if (banners != null) {
            _banners = List<AppBanner>.from(banners);
          }
          if (partners != null) {
            _partners = List<Partner>.from(partners);
          }
          final name = _getNameFromProfile(profile);
          if (name != null && name.isNotEmpty) {
            _userName = name;
          }
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    } finally {
      _isFetching = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalizations.languageNotifier,
      builder: (context, currentLang, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final backgroundColor =
            isDark ? const Color(0xFF141414) : const Color(0xFFF9FAFB);

        if (_loading) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: const HomeSkeleton(),
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
        children: [
          HomeHeader(
            userName: _userName,
            onChatTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const ChatTopicsScreen(),
                ),
              );
            },
            onNotificationsTap: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadData(force: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    PremiumCard(
                      cardNumber: _barcode ?? '',
                      bonusAmount: _walletBalance?.formattedBalance ?? '0',
                      onPress: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => BarcodeScreen(barcode: _barcode),
                          ),
                        );
                      },
                    ),
                    CampaignSlider(
                      banners: _banners,
                      onBannerTap: (banner) {
                        // TODO: Kampaniya detalları
                      },
                    ),
                    MenuGrid(
                      onDiscountsTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const DiscountsScreen(),
                          ),
                        );
                      },
                      onHistoryTap: () {
                        widget.onNavigateToTab?.call(1);
                      },
                    ),
                    PartnersSection(
                      partners: _partners,
                      onViewAllTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PartnersScreen(),
                          ),
                        );
                      },
                      onPartnerTap: (partner) {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PartnerDetailScreen(id: partner.id),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
      },
    );
  }
}
