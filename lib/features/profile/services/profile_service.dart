import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/core/services/file_service.dart';
import 'package:loyallig_flutter/features/profile/models/terms_and_condition.dart';
import 'package:loyallig_flutter/features/profile/models/update_profile_request.dart';
import 'package:loyallig_flutter/features/profile/models/user_profile.dart';

class ProfileService {
  final ApiClient _client = ApiClient.instance;

  static UserProfile? cachedProfile;
  static String? cachedBarcode;

  /// İstifadəçi çıxış etdikdə və ya başqa hesabla daxil olduqda keşi təmizləyir
  static void clearCache() {
    cachedProfile = null;
    cachedBarcode = null;
  }

  // İstifadəçinin şəxsi profil məlumatlarını gətirmək
  Future<UserProfile?> getMyProfile({bool forceRefresh = false}) async {
    if (!forceRefresh && cachedProfile != null) {
      return cachedProfile;
    }

    try {
      final response = await _client.get(ApiEndpoints.myProfile);
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final result = data['result'];
          if (result is Map) {
            final profile =
                UserProfile.fromJson(Map<String, dynamic>.from(result));
            cachedProfile = profile;
            if (profile.barcode != null && profile.barcode!.isNotEmpty) {
              cachedBarcode = profile.barcode;
              TokenStorage.saveBarcode(profile.barcode!);
            }
            await TokenStorage.saveUserName(
              firstName: profile.firstName,
              lastName: profile.lastName,
              fullName: profile.fullName,
            );
            await TokenStorage.setHasPinCode(profile.hasPinCode);
            return profile;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('Profil məlumatı yüklənərkən xəta baş verdi: $e');
      rethrow;
    }
  }

  // Şəxsi profil məlumatlarını yeniləmək (/api/Users/myProfile/update)
  Future<Response> updateProfile(UpdateProfileRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.updateProfile,
        data: request.toJson(),
      );
      cachedProfile = null;
      return response;
    } catch (e) {
      debugPrint('Profil məlumatı yenilənərkən xəta baş verdi: $e');
      rethrow;
    }
  }

  // İstifadəçinin barkodunu gətirmək (/api/Users/myBarcode)
  Future<String?> getMyBarcode({bool forceRefresh = false}) async {
    if (!forceRefresh && cachedBarcode != null && cachedBarcode!.isNotEmpty) {
      return cachedBarcode;
    }

    try {
      final response = await _client.get(ApiEndpoints.myBarcode);
      debugPrint(
          '📦 [MY_BARCODE CAVABI]: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          _ensureSuccess(response);
          final result = data['result'] ?? data['data'];
          String? b;
          if (result is Map) {
            b = (result['barcode'] ??
                    result['code'] ??
                    result['cardNumber'] ??
                    result['value'])
                ?.toString();
          } else if (result is String && result.trim().isNotEmpty) {
            b = result.trim();
          } else if (result is num) {
            b = result.toString();
          } else if (data['barcode'] != null) {
            b = data['barcode'].toString();
          }

          if (b != null && b.trim().isNotEmpty) {
            final clean = b.trim();
            cachedBarcode = clean;
            TokenStorage.saveBarcode(clean);
            return clean;
          }
        } else if (data is String && data.trim().isNotEmpty) {
          final clean = data.trim();
          cachedBarcode = clean;
          TokenStorage.saveBarcode(clean);
          return clean;
        }
      }

      if (forceRefresh) {
        cachedBarcode = null;
      }
      return null;
    } catch (e) {
      debugPrint('❌ [MY_BARCODE XƏTASI]: $e');
      if (forceRefresh) {
        cachedBarcode = null;
      }
      rethrow;
    }
  }

  /// Qaydalar və şərtlər (/api/TermsAndConditions/getAll)
  Future<List<TermsAndCondition>> getTermsAndConditions({
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.termsAndConditionsGetAll,
        queryParameters: {'languageCode': lang},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> list = [];

        if (data is Map) {
          _ensureSuccess(response);
          final result = data['result'] ?? data['data'] ?? data['items'];
          if (result is List) {
            list = result;
          } else if (result is Map) {
            final nestedList =
                result['items'] ?? result['data'] ?? result['list'];
            if (nestedList is List) {
              list = nestedList;
            } else if (result.containsKey('title') ||
                result.containsKey('name') ||
                result.containsKey('description') ||
                result.containsKey('content')) {
              list = [result];
            }
          }
        } else if (data is List) {
          list = data;
        }

        final terms = list
            .whereType<Map>()
            .map(
              (item) => TermsAndCondition.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((item) => item.isActive)
            .toList();

        terms.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        return terms;
      }
      return [];
    } catch (e) {
      debugPrint('Qaydalar və şərtlər gətirilərkən xəta: $e');
      rethrow;
    }
  }

  /// Profil şəklini yükləmək (POST /api/File/upload)
  Future<FileUploadResponse> uploadAvatar(File file) async {
    return await FileService().uploadFile(file);
  }

  /// Cross-platform profil şəklini yükləmək (Web + Mobile)
  Future<FileUploadResponse> uploadAvatarXFile(XFile file) async {
    return await FileService().uploadXFile(file);
  }

  /// Profil şəklini silmək (DELETE /api/File/delete/{avatarFileId})
  Future<bool> deleteAvatar(String avatarFileId) async {
    return await FileService().deleteFile(avatarFileId);
  }

  /// 1. Cari Email-ə təsdiq kodunun göndərilməsi (POST /api/Users/changeEmail/sendCurrentCode)
  Future<void> sendCurrentEmailCode() async {
    final response = await _client.post(
      ApiEndpoints.changeEmailSendCurrentCode,
    );
    _ensureSuccess(response);
  }

  /// 2. Cari Email-ə gələn kodun təsdiqi və token alınması (POST /api/Users/changeEmail/verifyCurrentCode)
  Future<String> verifyCurrentEmailCode(String code) async {
    final response = await _client.post(
      ApiEndpoints.changeEmailVerifyCurrentCode,
      data: {'code': code.trim()},
    );
    _ensureSuccess(response);

    final data = response.data;
    String? token;
    if (data is Map) {
      final result = data['result'];
      if (result is Map) {
        token = result['token']?.toString();
      } else if (result is String && result.trim().isNotEmpty) {
        token = result.trim();
      } else {
        token = data['token']?.toString();
      }
    }

    if (token == null || token.trim().isEmpty) {
      throw Exception(tr('common_error'));
    }
    return token.trim();
  }

  /// 3. Yeni Email ünvanına kodun göndərilməsi (POST /api/Users/changeEmail/sendNewCode)
  Future<void> sendNewEmailCode({
    required String token,
    required String newEmail,
  }) async {
    final response = await _client.post(
      ApiEndpoints.changeEmailSendNewCode,
      data: {
        'token': token.trim(),
        'newEmail': newEmail.trim(),
      },
    );
    _ensureSuccess(response);
  }

  /// 4. Yeni Email-in təsdiqi və tamamlanması (POST /api/Users/changeEmail/confirm)
  Future<void> confirmChangeEmail({
    required String token,
    required String newEmail,
    required String code,
  }) async {
    final response = await _client.post(
      ApiEndpoints.changeEmailConfirm,
      data: {
        'token': token.trim(),
        'newEmail': newEmail.trim(),
        'code': code.trim(),
      },
    );
    _ensureSuccess(response);

    // Keşdəki profili yeniləyirik ki, yeni email dərhal əks olunsun
    if (cachedProfile != null) {
      cachedProfile = UserProfile(
        id: cachedProfile!.id,
        email: newEmail.trim(),
        phoneNumber: cachedProfile!.phoneNumber,
        barcode: cachedProfile!.barcode,
        isPremium: cachedProfile!.isPremium,
        authProvider: cachedProfile!.authProvider,
        lastLoginAt: cachedProfile!.lastLoginAt,
        firstName: cachedProfile!.firstName,
        lastName: cachedProfile!.lastName,
        fullName: cachedProfile!.fullName,
        birthDate: cachedProfile!.birthDate,
        gender: cachedProfile!.gender,
        genderName: cachedProfile!.genderName,
        avatarFileId: cachedProfile!.avatarFileId,
        avatarFileName: cachedProfile!.avatarFileName,
        hasPinCode: cachedProfile!.hasPinCode,
      );
    }
  }

  void _ensureSuccess(Response response) {
    final data = response.data;
    if (data is Map && data['isSuccess'] == false) {
      final errMsg = data['errorMessage']?.toString() ??
          data['message']?.toString() ??
          tr('common_error');
      throw Exception(errMsg);
    }
  }

  static String extractErrorMessage(Object error, [String? fallback]) {
    final defaultMsg = fallback ?? tr('common_error');
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final rawError = data['errorMessage']?.toString() ??
            data['message']?.toString() ??
            data['title']?.toString();
        if (rawError != null && rawError.trim().isNotEmpty) {
          return rawError.trim();
        }
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          return errors.map((e) => e.toString()).join('\n');
        } else if (errors is Map && errors.isNotEmpty) {
          final messages = <String>[];
          for (final val in errors.values) {
            if (val is List) {
              messages.addAll(val.map((item) => item.toString()));
            } else {
              messages.add(val.toString());
            }
          }
          if (messages.isNotEmpty) {
            return messages.join('\n');
          }
        }
      } else if (data is String && data.trim().isNotEmpty) {
        return data.trim();
      }
    }
    final str = error.toString();
    if (str.startsWith('Exception: ')) {
      final cleaned = str.substring('Exception: '.length).trim();
      if (cleaned.isNotEmpty) return cleaned;
    }
    return defaultMsg;
  }
}
