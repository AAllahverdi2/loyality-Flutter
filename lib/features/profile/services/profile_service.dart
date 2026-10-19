import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
          final result = data['result'];
          String? b;
          if (result is Map) {
            b = result['barcode']?.toString();
          } else if (result is String && result.isNotEmpty) {
            b = result;
          } else if (data['barcode'] != null) {
            b = data['barcode'].toString();
          }

          if (b != null && b.isNotEmpty) {
            cachedBarcode = b;
            TokenStorage.saveBarcode(b);
            return b;
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MY_BARCODE XƏTASI]: $e');
    }

    // Əgər myBarcode alınmadısa, ehtiyat olaraq myProfile-dan yoxlayırıq
    try {
      final profile = await getMyProfile();
      if (profile?.barcode != null && profile!.barcode!.isNotEmpty) {
        debugPrint('✅ [BARCODE MY_PROFILE-DAN GÖTÜRÜLDÜ]: ${profile.barcode}');
        cachedBarcode = profile.barcode;
        TokenStorage.saveBarcode(profile.barcode!);
        return profile.barcode;
      }
    } catch (e) {
      debugPrint('⚠️ [MY_PROFILE FALLBACK XƏTASI]: $e');
    }

    return null;
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
        if (data is Map && data['result'] is List) {
          list = data['result'] as List<dynamic>;
        } else if (data is List) {
          list = data;
        }

        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => TermsAndCondition.fromJson(item))
            .where((item) => item.isActive)
            .toList();
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

  /// Profil şəklini silmək (DELETE /api/File/delete/{avatarFileId})
  Future<bool> deleteAvatar(String avatarFileId) async {
    return await FileService().deleteFile(avatarFileId);
  }
}
