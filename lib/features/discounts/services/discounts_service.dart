import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/models/lookup_item.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/discounts/models/partner_offer.dart';

class DiscountsService {
  final ApiClient _client = ApiClient.instance;

  // Lookups üçün in-memory keş
  static List<LookupItem>? _cachedPartners;
  static List<LookupItem>? _cachedOfferTypes;
  static String? _cachedLanguageCode;

  static List<LookupItem>? get cachedPartners => _cachedPartners;
  static List<LookupItem>? get cachedOfferTypes => _cachedOfferTypes;

  static bool get hasLookupsCache =>
      _cachedPartners != null && _cachedOfferTypes != null;

  static void clearLookupsCache() {
    _cachedPartners = null;
    _cachedOfferTypes = null;
    _cachedLanguageCode = null;
  }

  /// Tərəfdaşların lookup siyahısını gətirir (GET /api/Lookups/partners)
  Future<List<LookupItem>> getLookupPartners({
    String? partnerCategoryId,
    String? languageCode,
    bool forceRefresh = false,
  }) async {
    final lang = languageCode ?? AppLocalizations.currentLanguageCode;
    if (!forceRefresh &&
        partnerCategoryId == null &&
        _cachedPartners != null &&
        _cachedLanguageCode == lang) {
      debugPrint('⚡ [LOOKUP PARTNERS (DISCOUNTS)]: Cachedən oxundu');
      return _cachedPartners!;
    }

    try {
      final queryParams = <String, dynamic>{
        'languageCode': lang,
      };
      if (partnerCategoryId != null && partnerCategoryId.isNotEmpty) {
        queryParams['partnerCategoryId'] = partnerCategoryId;
      }

      final response = await _client.get(
        ApiEndpoints.lookupPartners,
        queryParameters: queryParams,
      );

      debugPrint('📦 [LOOKUP PARTNERS CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic>? list;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) list = result;
        } else if (data is List) {
          list = data;
        }

        if (list != null) {
          final items = list
              .map((item) =>
                  LookupItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          if (partnerCategoryId == null) {
            _cachedLanguageCode = lang;
            _cachedPartners = items;
          }
          return items;
        }
      }
      return _cachedPartners ?? [];
    } catch (e) {
      debugPrint('❌ [LOOKUP PARTNERS XƏTASI]: $e');
      return _cachedPartners ?? [];
    }
  }

  /// Təklif növlərinin lookup siyahısını gətirir (GET /api/Lookups/offerTypes)
  Future<List<LookupItem>> getLookupOfferTypes({
    String? languageCode,
    bool forceRefresh = false,
  }) async {
    final lang = languageCode ?? AppLocalizations.currentLanguageCode;
    if (!forceRefresh &&
        _cachedOfferTypes != null &&
        _cachedLanguageCode == lang) {
      debugPrint('⚡ [LOOKUP OFFER_TYPES]: Cachedən oxundu');
      return _cachedOfferTypes!;
    }

    try {
      final response = await _client.get(
        ApiEndpoints.lookupOfferTypes,
        queryParameters: {
          'languageCode': lang,
        },
      );

      debugPrint('📦 [LOOKUP OFFER_TYPES CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic>? list;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) list = result;
        } else if (data is List) {
          list = data;
        }

        if (list != null) {
          _cachedLanguageCode = lang;
          _cachedOfferTypes = list
              .map((item) =>
                  LookupItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return _cachedOfferTypes!;
        }
      }
      return _cachedOfferTypes ?? [];
    } catch (e) {
      debugPrint('❌ [LOOKUP OFFER_TYPES XƏTASI]: $e');
      return _cachedOfferTypes ?? [];
    }
  }

  /// Tərəfdaş təkliflərini gətirir (GET /api/PartnerOffers/getAll)
  Future<List<PartnerOffer>> getPartnerOffers({
    String? partnerId,
    String? offerTypeId,
    bool? isActive,
    String? search,
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final queryParams = <String, dynamic>{
        'languageCode': lang,
      };
      if (partnerId != null && partnerId.trim().isNotEmpty) {
        queryParams['partnerId'] = partnerId.trim();
      }
      if (offerTypeId != null && offerTypeId.trim().isNotEmpty) {
        queryParams['offerTypeId'] = offerTypeId.trim();
      }
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }

      final response = await _client.get(
        ApiEndpoints.partnerOffersGetAll,
        queryParameters: queryParams,
      );

      debugPrint('📦 [PARTNER_OFFERS GET_ALL CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic>? list;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) list = result;
        } else if (data is List) {
          list = data;
        }

        if (list != null) {
          return list
              .map((item) => PartnerOffer.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('❌ [PARTNER_OFFERS GET_ALL XƏTASI]: $e');
      rethrow;
    }
  }
}
