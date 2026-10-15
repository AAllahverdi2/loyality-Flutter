import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/home/models/app_banner.dart';

class BannerService {
  final ApiClient _client = ApiClient.instance;

  /// Bütün banner-ləri gətirir (GET /api/AppBanners/getAll)
  Future<List<AppBanner>> getBanners({
    bool? isActive,
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final queryParams = <String, dynamic>{
        'languageCode': lang,
      };
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }

      final response = await _client.get(
        ApiEndpoints.appBannersGetAll,
        queryParameters: queryParams,
      );

      debugPrint('📦 [APP_BANNERS GET_ALL CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic>? list;

        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) {
            list = result;
          }
        } else if (data is List) {
          list = data;
        }

        if (list != null) {
          final banners = list
              .map((item) =>
                  AppBanner.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();

          banners.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          return banners;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [APP_BANNERS GET_ALL XƏTASI]: $e');
      rethrow;
    }
  }
}
