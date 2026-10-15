import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/chat/models/support_topic.dart';

class SupportTopicsService {
  final ApiClient _client = ApiClient.instance;

  /// Aktiv dəstək mövzularını serverdən gətirir
  /// [languageCode] ötürülməzsə cari aktiv dil istifadə olunur (məs: 'az')
  Future<List<SupportTopic>> getActiveTopics({String? languageCode}) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.supportTopicsActive,
        queryParameters: {
          'languageCode': lang,
        },
      );

      debugPrint('📦 [SUPPORT_TOPICS/ACTIVE CAVABI]: ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<SupportTopic> topics = [];

        if (data is Map) {
          final result = data['result'] ?? data['data'];
          if (result is List) {
            topics = result
                .map((item) => SupportTopic.fromJson(
                    Map<String, dynamic>.from(item as Map)))
                .toList();
          }
        } else if (data is List) {
          topics = data
              .map((item) => SupportTopic.fromJson(
                  Map<String, dynamic>.from(item as Map)))
              .toList();
        }

        return topics;
      }
      return [];
    } catch (e) {
      debugPrint('❌ [SUPPORT_TOPICS/ACTIVE XƏTASI]: $e');
      rethrow;
    }
  }
}
