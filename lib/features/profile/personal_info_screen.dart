import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/constants/app_colors.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/widgets/custom_input.dart';
import 'package:loyallig_flutter/core/widgets/app_date_picker_dialog.dart';
import 'package:loyallig_flutter/core/widgets/swipe_back_wrapper.dart';
import 'package:loyallig_flutter/features/auth/widgets/primary_button.dart';
import 'package:loyallig_flutter/features/profile/models/update_profile_request.dart';
import 'package:loyallig_flutter/features/profile/models/user_profile.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  final UserProfile? profile;
  const PersonalInfoScreen({this.profile, super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final ProfileService _profileService = ProfileService();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _dobController;

  String? _nameError;
  String? _phoneError;
  int? _selectedGender;
  bool _loading = false;

  String? _avatarFileId;
  File? _avatarLocalFile;
  bool _uploadingAvatar = false;

  String _formatDateForDisplay(String? date) {
    if (date == null || date.trim().isEmpty) return '';
    try {
      final dt = DateTime.tryParse(date.trim());
      if (dt != null) {
        final d = dt.day.toString().padLeft(2, '0');
        final m = dt.month.toString().padLeft(2, '0');
        return '$d/$m/${dt.year}';
      }
    } catch (_) {}
    return date.replaceAll('.', '/').replaceAll('-', '/');
  }

  int? _parseGender(dynamic gender) {
    if (gender == null) return null;
    if (gender is int) return gender;
    final str = gender.toString().trim().toLowerCase();
    if (str == '1' || str == 'male' || str == 'kisi' || str == 'kişi') {
      return 1;
    }
    if (str == '2' || str == 'female' || str == 'qadin' || str == 'qadın') {
      return 2;
    }
    return int.tryParse(str);
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return tr('personal_phone_required');
    }
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final azPattern = RegExp(r'^(\+?994|0)?(10|50|51|55|60|70|77|99)\d{7}$');
    final generalPattern = RegExp(r'^\+?[0-9]{9,15}$');

    if (azPattern.hasMatch(clean) || generalPattern.hasMatch(clean)) {
      return null;
    }
    return tr('personal_phone_error');
  }

  String _normalizePhone(String value) {
    final clean = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (clean.startsWith('+994')) return clean;
    if (clean.startsWith('994')) return '+$clean';
    if (clean.startsWith('0') && clean.length == 10) {
      return '+994${clean.substring(1)}';
    }
    if (clean.length == 9) {
      return '+994$clean';
    }
    return clean.startsWith('+') ? clean : '+$clean';
  }

  void _onFieldChanged() {
    if (_nameError != null || _phoneError != null) {
      setState(() {
        _nameError = null;
        _phoneError = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p?.firstName ?? '');
    _surnameController = TextEditingController(text: p?.lastName ?? '');
    _phoneController = TextEditingController(text: p?.phoneNumber ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _dobController = TextEditingController(
      text: _formatDateForDisplay(p?.birthDate),
    );
    _selectedGender = _parseGender(p?.gender) ?? _parseGender(p?.genderName);
    _avatarFileId = p?.avatarFileId;

    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);

    if (p == null) {
      _loadProfile();
    }
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _profileService.getMyProfile();
      if (mounted && p != null) {
        setState(() {
          _nameController.text = p.firstName ?? '';
          _surnameController.text = p.lastName ?? '';
          _phoneController.text = p.phoneNumber ?? '';
          _emailController.text = p.email ?? '';
          _dobController.text = _formatDateForDisplay(p.birthDate);
          _selectedGender = _parseGender(p.gender) ?? _parseGender(p.genderName);
          _avatarFileId = p.avatarFileId;
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _phoneController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime(1995, 1, 1);
    final text = _dobController.text.trim();
    if (text.isNotEmpty) {
      final cleanText = text.replaceAll('.', '/').replaceAll('-', '/');
      final parts = cleanText.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null &&
            m != null &&
            y != null &&
            y >= 1930 &&
            y <= DateTime.now().year) {
          initialDate = DateTime(y, m, d);
        }
      } else {
        final parsed = DateTime.tryParse(text);
        if (parsed != null) initialDate = parsed;
      }
    }

    final picked = await showAppDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1930),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      final year = picked.year.toString();
      setState(() {
        _dobController.text = '$day/$month/$year';
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) return;

      final file = File(picked.path);

      setState(() {
        _avatarLocalFile = file;
        _uploadingAvatar = true;
      });

      final response = await _profileService.uploadAvatar(file);

      if (!mounted) return;

      setState(() => _uploadingAvatar = false);

      if (response.isSuccess &&
          response.fileId != null &&
          response.fileId!.isNotEmpty) {
        setState(() {
          _avatarFileId = response.fileId;
        });
        _showSnackbar(tr('personal_avatar_success'), isError: false);
      } else {
        setState(() {
          _avatarLocalFile = null;
        });
        _showSnackbar(
          response.errorMessage ?? tr('personal_avatar_error'),
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadingAvatar = false;
        _avatarLocalFile = null;
      });
      _showSnackbar('${tr('personal_avatar_pick_error')}: $e', isError: true);
    }
  }

  void _showImagePickerModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3F3F46) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                tr('personal_avatar_title'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.base),
                ),
                title: Text(
                  tr('personal_avatar_gallery'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAvatar(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.base),
                ),
                title: Text(
                  tr('personal_avatar_camera'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadAvatar(ImageSource.camera);
                },
              ),
              if (_avatarLocalFile != null ||
                  (_avatarFileId != null && _avatarFileId!.isNotEmpty)) ...[
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: AppColors.error),
                  ),
                  title: Text(
                    tr('personal_avatar_delete'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    setState(() {
                      _avatarLocalFile = null;
                      _avatarFileId = null;
                    });
                    _showSnackbar(tr('personal_avatar_deleted'));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    final firstName = _nameController.text.trim();
    final lastName = _surnameController.text.trim();
    final phone = _phoneController.text.trim();

    String? nameErr;
    if (firstName.isEmpty) {
      nameErr = tr('personal_first_name_error');
    }

    final phoneErr = _validatePhone(phone);

    if (nameErr != null || phoneErr != null) {
      setState(() {
        _nameError = nameErr;
        _phoneError = phoneErr;
      });
      _showSnackbar(nameErr ?? phoneErr!, isError: true);
      return;
    }

    setState(() => _loading = true);

    // Tarixi "YYYY-MM-DD" formatına çeviririk
    String? birthDateFormatted;
    final dobText = _dobController.text.trim();
    if (dobText.isNotEmpty) {
      final cleanText = dobText.replaceAll('.', '/').replaceAll('-', '/');
      final parts = cleanText.split('/');
      if (parts.length == 3 && parts[2].length == 4) {
        final d = parts[0].padLeft(2, '0');
        final m = parts[1].padLeft(2, '0');
        final y = parts[2];
        birthDateFormatted = '$y-$m-$d';
      } else {
        birthDateFormatted = dobText;
      }
    }

    try {
      final request = UpdateProfileRequest(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: _normalizePhone(phone),
        birthDate: birthDateFormatted,
        gender: _selectedGender,
        avatarFileId: _avatarFileId,
      );

      final response = await _profileService.updateProfile(request);

      if (!mounted) return;
      setState(() => _loading = false);

      if (response.statusCode == 200) {
        _showSnackbar(tr('personal_save_success'), isError: false);
        Navigator.of(context).pop(true);
      } else {
        _showSnackbar(tr('personal_save_error'), isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);

      String errorMsg = tr('personal_save_error');
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map) {
          errorMsg = data['errorMessage']?.toString() ??
              data['message']?.toString() ??
              data['title']?.toString() ??
              errorMsg;
        }
      }
      _showSnackbar(errorMsg, isError: true);
    }
  }

  Widget _buildGenderOption({
    required String title,
    required IconData icon,
    required int value,
    required bool isDark,
  }) {
    final isSelected = _selectedGender == value;
    final cardBg = isDark ? const Color(0xFF18181B) : const Color(0xFFF9FAFB);
    final activeBg = isDark
        ? AppColors.base.withValues(alpha: 0.15)
        : AppColors.base.withValues(alpha: 0.08);
    final borderColor = isSelected
        ? AppColors.base
        : (isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB));
    final contentColor = isSelected
        ? AppColors.base
        : (isDark ? const Color(0xFFA1A1AA) : const Color(0xFF4B5563));

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: contentColor,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: contentColor,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: AppColors.base,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? const Color(0xFF000000) : Colors.white;
    final cardBg = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? const Color(0xFFFFFFFF) : const Color(0xFF111827);
    final secondaryTextColor =
        isDark ? const Color(0xFFA1A1AA) : const Color(0xFF6B7280);

    return SwipeBackWrapper(
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.centerLeft,
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    tr('personal_info_title'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // Avatar Section
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _uploadingAvatar ? null : _showImagePickerModal,
                            child: Stack(
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: cardBg,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: isDark ? 0.3 : 0.08,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: _buildAvatarImage(isDark),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColors.base,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: backgroundColor,
                                        width: 3,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: _uploadingAvatar
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _uploadingAvatar ? null : _showImagePickerModal,
                            child: Text(
                              _uploadingAvatar
                                  ? tr('personal_avatar_uploading')
                                  : tr('personal_avatar_update'),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _uploadingAvatar
                                    ? AppColors.base
                                    : secondaryTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Name & Surname row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomInput(
                            label: tr('personal_first_name'),
                            controller: _nameController,
                            hint: tr('personal_first_name_hint'),
                            error: _nameError,
                            marginBottom: 16,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomInput(
                            label: tr('personal_last_name'),
                            controller: _surnameController,
                            hint: tr('personal_last_name_hint'),
                            marginBottom: 16,
                          ),
                        ),
                      ],
                    ),

                    // Phone
                    CustomInput(
                      label: tr('personal_phone'),
                      controller: _phoneController,
                      hint: tr('personal_phone_hint'),
                      error: _phoneError,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d\+\s\-\(\)]')),
                      ],
                      marginBottom: 16,
                    ),

                    // Email (Dəyişdirilə bilməz - Disabled & ReadOnly)
                    CustomInput(
                      label: tr('personal_email'),
                      controller: _emailController,
                      hint: 'example@gmail.com',
                      enabled: false,
                      readOnly: true,
                      rightIcon: Icons.lock_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      marginBottom: 16,
                    ),

                    // Date of Birth
                    CustomInput(
                      label: tr('personal_birth_date'),
                      controller: _dobController,
                      hint: tr('personal_birth_date_hint'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        DateInputFormatter(),
                      ],
                      rightIcon: Icons.calendar_today_outlined,
                      onRightIconPress: _pickDate,
                      marginBottom: 16,
                    ),

                    // Gender Selection (Cins)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tr('personal_gender'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _buildGenderOption(
                                title: tr('personal_male'),
                                icon: Icons.male_rounded,
                                value: 1,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildGenderOption(
                                title: tr('personal_female'),
                                icon: Icons.female_rounded,
                                value: 2,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),

                    // Save Button
                    PrimaryButton(
                      label: _loading ? tr('common_loading') : tr('common_save'),
                      onPressed: _loading ? () {} : _handleSave,
                      height: 52,
                      borderRadius: 14,
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildAvatarImage(bool isDark) {
    if (_uploadingAvatar && _avatarLocalFile != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            _avatarLocalFile!,
            fit: BoxFit.cover,
            width: 100,
            height: 100,
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.4),
            alignment: Alignment.center,
            child: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            ),
          ),
        ],
      );
    }

    if (_avatarLocalFile != null) {
      return Image.file(
        _avatarLocalFile!,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
      );
    }

    final avatarUrl = (_avatarFileId != null && _avatarFileId!.isNotEmpty)
        ? '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(_avatarFileId!)}'
        : widget.profile?.avatarUrl;

    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Image.network(
        avatarUrl,
        headers: ApiClient.instance.authHeaders,
        fit: BoxFit.cover,
        width: 100,
        height: 100,
        errorBuilder: (context, error, stackTrace) =>
            _buildPlaceholderAvatar(isDark),
      );
    }

    return _buildPlaceholderAvatar(isDark);
  }

  Widget _buildPlaceholderAvatar(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF27272A) : const Color(0xFFE5E7EB),
      child: Icon(
        Icons.person_rounded,
        size: 54,
        color: isDark ? const Color(0xFF71717A) : const Color(0xFF9CA3AF),
      ),
    );
  }
}
