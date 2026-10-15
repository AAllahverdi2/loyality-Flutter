import 'package:flutter/material.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/theme/app_theme.dart';
import 'package:loyallig_flutter/features/notifications/notifications_screen.dart';
import 'package:loyallig_flutter/features/profile/widgets/language_bottom_sheet.dart';
import 'package:loyallig_flutter/features/profile/widgets/profile_header.dart';
import 'package:loyallig_flutter/features/profile/widgets/profile_item.dart';
import 'package:loyallig_flutter/features/profile/widgets/profile_section.dart';
import 'package:loyallig_flutter/features/profile/widgets/profile_skeleton.dart';
import 'package:loyallig_flutter/features/profile/widgets/terms_bottom_sheet.dart';
import 'package:loyallig_flutter/features/profile/widgets/theme_bottom_sheet.dart';
import 'package:loyallig_flutter/features/profile/widgets/user_card.dart';
import 'package:loyallig_flutter/features/auth/login_screen.dart';
import 'package:loyallig_flutter/features/auth/services/auth_service.dart';
import 'package:loyallig_flutter/features/profile/models/user_profile.dart';
import 'package:loyallig_flutter/features/profile/personal_info_screen.dart';
import 'package:loyallig_flutter/features/profile/security_screen.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  String _themeMode = AppTheme.currentModeString;
  final AuthService _authService = AuthService();
  final ProfileService _profileService = ProfileService();
  UserProfile? _profile;

  String get _language => AppLocalizations.currentLanguageLabel;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getMyProfile();
      if (mounted) {
        setState(() {
          _profile = profile;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _handleLogout() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('profile_logout')),
        content: Text(tr('profile_logout_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(tr('common_cancel')),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();

              // Çıxış zamanı yüklənmə pəncərəsi
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Serverdən və yerli yaddaşdan çıxış edirik
              await _authService.logout();

              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute<void>(
                  builder: (_) => const LoginScreen(),
                ),
                (route) => false,
              );
            },
            child: Text(
              tr('profile_logout'),
              style: const TextStyle(color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  String get _themeModeLabel => switch (_themeMode) {
        'light' => tr('profile_theme_light'),
        'dark' => tr('profile_theme_dark'),
        _ => tr('profile_theme_system'),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : const Color(0xFFF8F9FA);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    if (_loading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const SafeArea(
          bottom: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: 30),
            child: ProfileSkeleton(),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileHeader(),

              UserCard(
                name: _profile?.displayName ?? 'İstifadəçi',
                role: _profile?.email ?? '',
                status: (_profile?.isPremium == true)
                    ? tr('home_premium_member')
                    : tr('home_standard_member'),
                avatarUrl: _profile?.avatarUrl,
                onEditTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PersonalInfoScreen(profile: _profile),
                    ),
                  ).then((_) => _loadProfile());
                },
              ),

              // Account Settings
              ProfileSection(
                title: tr('profile_account_settings'),
                children: [
                  ProfileItem(
                    icon: Icons.person_outline_rounded,
                    title: tr('profile_personal_info'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PersonalInfoScreen(profile: _profile),
                        ),
                      ).then((_) => _loadProfile());
                    },
                  ),
                  ProfileItem(
                    icon: Icons.shield_outlined,
                    title: tr('security_title'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const SecurityScreen(),
                        ),
                      );
                    },
                  ),
                  ProfileItem(
                    icon: Icons.notifications_none_rounded,
                    title: tr('profile_notifications'),
                    showBadge: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              // App Settings
              ProfileSection(
                title: tr('profile_app_settings'),
                children: [
                  ProfileItem(
                    icon: Icons.language_rounded,
                    title: tr('profile_language'),
                    value: _language,
                    onTap: () {
                      LanguageBottomSheet.show(
                        context,
                        currentLanguage: _language,
                        onSelect: (lang) {
                          setState(() {});
                        },
                      );
                    },
                  ),
                  ProfileItem(
                    icon: Icons.palette_outlined,
                    title: tr('profile_theme'),
                    value: _themeModeLabel,
                    onTap: () {
                      ThemeBottomSheet.show(
                        context,
                        currentMode: _themeMode,
                        onSelect: (mode) {
                          setState(() => _themeMode = mode);
                          AppTheme.setThemeMode(mode);
                        },
                      );
                    },
                  ),
                  ProfileItem(
                    icon: Icons.description_outlined,
                    title: tr('profile_terms'),
                    onTap: () {
                      TermsBottomSheet.show(context);
                    },
                  ),
                ],
              ),

              // Logout Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: isDark
                      ? const Color(0xFFDC2626).withValues(alpha: 0.2)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: _handleLogout,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.logout_rounded,
                            size: 20,
                            color: Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr('profile_logout'),
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Version Text
              Center(
                child: Text(
                  'Versiya 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
