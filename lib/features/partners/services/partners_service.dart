import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/partners/models/partner.dart';
import 'package:loyallig_flutter/features/partners/models/partner_category.dart';

class PartnersService {
  final ApiClient _client = ApiClient.instance;

  static final ValueNotifier<Set<String>> favoriteIdsNotifier =
      ValueNotifier<Set<String>>({});

  static final ValueNotifier<int> favoritesVersionNotifier =
      ValueNotifier<int>(0);

  static void notifyFavoritesChanged() {
    favoritesVersionNotifier.value++;
  }

  Future<List<Partner>> getAllPartners({
    String? partnerCategoryId,
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final queryParams = <String, dynamic>{
        'languageCode': lang,
      };
      if (partnerCategoryId != null && partnerCategoryId.isNotEmpty) {
        queryParams['partnerCategoryId'] = partnerCategoryId;
      }

      final response = await _client.get(
        ApiEndpoints.partnersGetAll,
        queryParameters: queryParams,
      );

      debugPrint('📦 [PARTNERS GET_ALL CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<Partner> partners = [];
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) {
            partners = result
                .map((item) =>
                    Partner.fromJson(Map<String, dynamic>.from(item as Map)))
                .toList();
          }
        } else if (data is List) {
          partners = data
              .map((item) =>
                  Partner.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }

        final currentFavs = Set<String>.from(favoriteIdsNotifier.value);
        for (final p in partners) {
          if (p.isFavorite) {
            currentFavs.add(p.id);
          }
        }
        favoriteIdsNotifier.value = currentFavs;

        return partners;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [PARTNERS GET_ALL XƏTASI]: $e');
      rethrow;
    }
  }

  Future<Partner?> getPartnerById({
    required String id,
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.partnersGetById,
        queryParameters: {
          'id': id,
          'languageCode': lang,
        },
      );

      debugPrint('📦 [PARTNERS GET_BY_ID CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result != null && result is Map) {
            return Partner.fromJson(
                Map<String, dynamic>.from(result));
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [PARTNERS GET_BY_ID XƏTASI]: $e');
      rethrow;
    }
  }

  Future<List<PartnerCategory>> getCategories({
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.partnerCategoriesGetAll,
        queryParameters: {
          'languageCode': lang,
        },
      );

      debugPrint(
          '📦 [PARTNER_CATEGORIES GET_ALL CAVABI]: ${response.statusCode}');

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
          return list
              .map((item) => PartnerCategory.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [PARTNER_CATEGORIES GET_ALL XƏTASI]: $e');
      rethrow;
    }
  }

  Future<List<Partner>> getMyFavorites({
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.myFavorites,
        queryParameters: {
          'languageCode': lang,
        },
      );

      debugPrint('📦 [PARTNERS MY_FAVORITES CAVABI]: ${response.statusCode}');

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
          final partners = list
              .map((item) =>
                  Partner.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();

          favoriteIdsNotifier.value = partners.map((p) => p.id).toSet();
          return partners;
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [PARTNERS MY_FAVORITES XƏTASI]: $e');
      rethrow;
    }
  }

  Future<bool> addToFavorites(String partnerId) async {
    final current = Set<String>.from(favoriteIdsNotifier.value);
    current.add(partnerId);
    favoriteIdsNotifier.value = current;

    try {
      final response = await _client.post(
        ApiEndpoints.addPartnerToFavorites(partnerId),
        data: '',
      );

      debugPrint('❤️ [PARTNER ADD TO FAVORITES CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (response.data is Map) {
          final isSuccess = response.data['isSuccess'];
          if (isSuccess != null && isSuccess != true) {
            final rollback = Set<String>.from(favoriteIdsNotifier.value)
              ..remove(partnerId);
            favoriteIdsNotifier.value = rollback;
            notifyFavoritesChanged();
            return false;
          }
        }
        notifyFavoritesChanged();
        return true;
      }
      final rollback = Set<String>.from(favoriteIdsNotifier.value)
        ..remove(partnerId);
      favoriteIdsNotifier.value = rollback;
      notifyFavoritesChanged();
      return false;
    } catch (e) {
      debugPrint('❌ [PARTNER ADD TO FAVORITES XƏTASI]: $e');
      final rollback = Set<String>.from(favoriteIdsNotifier.value)
        ..remove(partnerId);
      favoriteIdsNotifier.value = rollback;
      notifyFavoritesChanged();
      return false;
    }
  }

  Future<bool> removeFromFavorites(String partnerId) async {
    final current = Set<String>.from(favoriteIdsNotifier.value);
    current.remove(partnerId);
    favoriteIdsNotifier.value = current;

    try {
      final response = await _client.delete(
        ApiEndpoints.removePartnerFromFavorites(partnerId),
      );

      debugPrint(
          '💔 [PARTNER REMOVE FROM FAVORITES CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.data is Map) {
          final isSuccess = response.data['isSuccess'];
          if (isSuccess != null && isSuccess != true) {
            final rollback = Set<String>.from(favoriteIdsNotifier.value)
              ..add(partnerId);
            favoriteIdsNotifier.value = rollback;
            notifyFavoritesChanged();
            return false;
          }
        }
        notifyFavoritesChanged();
        return true;
      }
      final rollback = Set<String>.from(favoriteIdsNotifier.value)
        ..add(partnerId);
      favoriteIdsNotifier.value = rollback;
      notifyFavoritesChanged();
      return false;
    } catch (e) {
      debugPrint('❌ [PARTNER REMOVE FROM FAVORITES XƏTASI]: $e');
      final rollback = Set<String>.from(favoriteIdsNotifier.value)
        ..add(partnerId);
      favoriteIdsNotifier.value = rollback;
      notifyFavoritesChanged();
      return false;
    }
  }

  Future<bool> toggleFavorite({
    required String partnerId,
    required bool isCurrentlyFavorite,
  }) async {
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(partnerId);
    } else {
      return await addToFavorites(partnerId);
    }
  }
}
