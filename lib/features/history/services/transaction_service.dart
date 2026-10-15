import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/models/lookup_item.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/history/models/user_transaction.dart';

class TransactionService {
  final ApiClient _client = ApiClient.instance;

  /// Şəxsi əməliyyat tarixçəsini gətirir (/api/Transactions/my)
  Future<List<UserTransaction>> getMyTransactions({
    String? partnerId,
    dynamic status,
    dynamic transactionType,
    DateTime? dateFrom,
    DateTime? dateTo,
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
      if (status != null && status.toString().trim().isNotEmpty) {
        queryParams['status'] = status.toString().trim();
      }
      if (transactionType != null &&
          transactionType.toString().trim().isNotEmpty) {
        queryParams['transactionType'] = transactionType.toString().trim();
      }
      if (dateFrom != null) {
        queryParams['dateFrom'] = dateFrom.toIso8601String();
      }
      if (dateTo != null) {
        queryParams['dateTo'] = dateTo.toIso8601String();
      }

      debugPrint('🔍 [TRANSACTIONS MY REQUEST PARAMETRLƏRİ]: $queryParams');

      final response = await _client.get(
        ApiEndpoints.transactionsMy,
        queryParameters: queryParams,
      );

      debugPrint('📦 [TRANSACTIONS MY CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> list = [];

        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) {
            list = result;
          }
        } else if (data is List) {
          list = data;
        }

        return list
            .whereType<Map<String, dynamic>>()
            .map((json) => UserTransaction.fromJson(json))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('Əməliyyat tarixçəsi gətirilərkən Dio xətası: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Əməliyyat tarixçəsi gətirilərkən xəta: $e');
      rethrow;
    }
  }

  /// Əməliyyatın detallı məlumatını gətirir (GET /api/Transactions/getById?id={id}&languageCode={languageCode})
  Future<UserTransaction?> getTransactionById(
    String id, {
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.transactionsGetById,
        queryParameters: {
          'id': id,
          'languageCode': lang,
        },
      );

      debugPrint('📦 [TRANSACTIONS GET_BY_ID CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        Map<String, dynamic>? itemMap;
        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is Map) {
            itemMap = Map<String, dynamic>.from(result);
          } else {
            itemMap = Map<String, dynamic>.from(data);
          }
        }

        if (itemMap != null) {
          return UserTransaction.fromJson(itemMap);
        }
      }
      return null;
    } on DioException catch (e) {
      debugPrint('Əməliyyat detalı gətirilərkən Dio xətası: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Əməliyyat detalı gətirilərkən xəta: $e');
      return null;
    }
  }

  // Lookups üçün in-memory keş
  static List<LookupItem>? _cachedTransactionTypes;
  static List<LookupItem>? _cachedTransactionStatuses;
  static List<LookupItem>? _cachedPartners;
  static String? _cachedLanguageCode;

  static List<LookupItem>? get cachedTransactionTypes => _cachedTransactionTypes;
  static List<LookupItem>? get cachedTransactionStatuses =>
      _cachedTransactionStatuses;
  static List<LookupItem>? get cachedPartners => _cachedPartners;

  static bool get hasLookupsCache =>
      _cachedTransactionTypes != null &&
      _cachedTransactionStatuses != null &&
      _cachedPartners != null;

  /// Bütün lookup keşini təmizləyir (məsələn: səhifə refresh olunanda)
  static void clearLookupsCache() {
    _cachedTransactionTypes = null;
    _cachedTransactionStatuses = null;
    _cachedPartners = null;
    _cachedLanguageCode = null;
    debugPrint('🧹 [TRANSACTIONS LOOKUP CACHE]: Keş təmizləndi');
  }

  /// Bütün lookup-ları eyni vaxtda keşləmək və ya yeniləmək
  Future<void> fetchAllLookups({
    bool forceRefresh = false,
    String? languageCode,
  }) async {
    final lang = languageCode ?? AppLocalizations.currentLanguageCode;
    await Future.wait([
      getLookupTransactionTypes(languageCode: lang, forceRefresh: forceRefresh),
      getLookupTransactionStatuses(
          languageCode: lang, forceRefresh: forceRefresh),
      getLookupPartners(languageCode: lang, forceRefresh: forceRefresh),
    ]);
  }

  /// Əməliyyat növlərinin lookup siyahısını gətirir (GET /api/Lookups/transactionTypes)
  Future<List<LookupItem>> getLookupTransactionTypes({
    String? languageCode,
    bool forceRefresh = false,
  }) async {
    final lang = languageCode ?? AppLocalizations.currentLanguageCode;
    if (!forceRefresh &&
        _cachedTransactionTypes != null &&
        _cachedLanguageCode == lang) {
      debugPrint('⚡ [LOOKUP TRANSACTION_TYPES]: Cachedən oxundu (${_cachedTransactionTypes!.length} element)');
      return _cachedTransactionTypes!;
    }

    try {
      final response = await _client.get(
        ApiEndpoints.lookupTransactionTypes,
        queryParameters: {'languageCode': lang},
      );

      debugPrint('📦 [LOOKUP TRANSACTION_TYPES CAVABI]: ${response.statusCode}');

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
          _cachedTransactionTypes = list
              .map((item) =>
                  LookupItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return _cachedTransactionTypes!;
        }
      }
      return _cachedTransactionTypes ?? [];
    } catch (e) {
      debugPrint('❌ [LOOKUP TRANSACTION_TYPES XƏTASI]: $e');
      return _cachedTransactionTypes ?? [];
    }
  }

  /// Əməliyyat statuslarının lookup siyahısını gətirir (GET /api/Lookups/transactionStatuses)
  Future<List<LookupItem>> getLookupTransactionStatuses({
    String? languageCode,
    bool forceRefresh = false,
  }) async {
    final lang = languageCode ?? AppLocalizations.currentLanguageCode;
    if (!forceRefresh &&
        _cachedTransactionStatuses != null &&
        _cachedLanguageCode == lang) {
      debugPrint('⚡ [LOOKUP TRANSACTION_STATUSES]: Cachedən oxundu (${_cachedTransactionStatuses!.length} element)');
      return _cachedTransactionStatuses!;
    }

    try {
      final response = await _client.get(
        ApiEndpoints.lookupTransactionStatuses,
        queryParameters: {'languageCode': lang},
      );

      debugPrint('📦 [LOOKUP TRANSACTION_STATUSES CAVABI]: ${response.statusCode}');

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
          _cachedTransactionStatuses = list
              .map((item) =>
                  LookupItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return _cachedTransactionStatuses!;
        }
      }
      return _cachedTransactionStatuses ?? [];
    } catch (e) {
      debugPrint('❌ [LOOKUP TRANSACTION_STATUSES XƏTASI]: $e');
      return _cachedTransactionStatuses ?? [];
    }
  }

  /// Tərəfdaşların lookup siyahısını gətirir (GET /api/Lookups/partners)
  Future<List<LookupItem>> getLookupPartners({
    String? languageCode,
    bool forceRefresh = false,
  }) async {
    final lang = languageCode ?? AppLocalizations.currentLanguageCode;
    if (!forceRefresh &&
        _cachedPartners != null &&
        _cachedLanguageCode == lang) {
      debugPrint('⚡ [LOOKUP PARTNERS]: Cachedən oxundu (${_cachedPartners!.length} element)');
      return _cachedPartners!;
    }

    try {
      final response = await _client.get(
        ApiEndpoints.lookupPartners,
        queryParameters: {'languageCode': lang},
      );

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
          _cachedPartners = list
              .map((item) =>
                  LookupItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
          return _cachedPartners!;
        }
      }
      return _cachedPartners ?? [];
    } catch (e) {
      debugPrint('❌ [LOOKUP PARTNERS XƏTASI]: $e');
      return _cachedPartners ?? [];
    }
  }
}
