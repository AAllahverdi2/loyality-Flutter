import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';
import 'package:loyallig_flutter/features/chat/models/support_conversation.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_hub_service.dart';

class SupportChatService {
  final ApiClient _client = ApiClient.instance;

  /// Texniki DioException mətnlərini istifadəçi üçün qısa və sadə mesaja çevirir
  static String extractFriendlyErrorMessage(
    Object error, {
    String fallbackKey = 'chat_general_error_short',
  }) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode == 429) {
        return tr('chat_error_too_many_requests');
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return tr('chat_error_network');
      }
      final data = error.response?.data;
      if (data is Map) {
        final msg = (data['errorMessage'] ??
                data['message'] ??
                data['detail'] ??
                data['title'])
            ?.toString()
            .trim();
        if (msg != null &&
            msg.isNotEmpty &&
            msg.length <= 100 &&
            !msg.contains('DioException') &&
            !msg.contains('https://') &&
            !msg.contains('validateStatus')) {
          return msg;
        }
      }
      return tr(fallbackKey);
    }

    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    if (raw.contains('429')) {
      return tr('chat_error_too_many_requests');
    }
    if (raw.isNotEmpty &&
        raw.length <= 90 &&
        !raw.contains('DioException') &&
        !raw.contains('https://') &&
        !raw.contains('validateStatus') &&
        !raw.contains('SocketException')) {
      return raw;
    }
    return tr(fallbackKey);
  }

  /// Müştərinin mövzu üzrə yeni söhbət və ilk mesajı yaratması
  /// POST /api/SupportConversations/create
  /// Schema:
  /// {
  ///   "supportTopicId": "guid",
  ///   "subject": "string",
  ///   "messageType": "Text",
  ///   "content": "string",
  ///   "attachmentFileId": "guid" (optional)
  /// }
  Future<SupportConversation> createConversation({
    required String supportTopicId,
    String? subject,
    String messageType = 'Text',
    required String content,
    String? attachmentFileId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'supportTopicId': supportTopicId,
        'subject': (subject != null && subject.trim().isNotEmpty)
            ? subject.trim()
            : 'Dəstək müraciəti',
        'messageType': messageType,
        'content': content.trim(),
        if (attachmentFileId != null && attachmentFileId.trim().isNotEmpty)
          'attachmentFileId': attachmentFileId.trim(),
      };

      final response = await _client.post(
        ApiEndpoints.supportConversationsCreate,
        data: payload,
      );

      if (kDebugMode) {
        debugPrint('📦 [SUPPORT_CHAT CREATE RES]: ${response.statusCode}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        SupportConversation? parsedConv;

        String? extractDirectId(dynamic raw) {
          if (raw is String && raw.trim().isNotEmpty) {
            return raw.trim();
          }
          if (raw is Map) {
            final idVal =
                raw['id'] ??
                raw['conversationId'] ??
                raw['supportConversationId'] ??
                raw['value'];
            if (idVal is String && idVal.trim().isNotEmpty) {
              return idVal.trim();
            }
          }
          return null;
        }

        if (data is Map) {
          final hasNested =
              data.containsKey('result') || data.containsKey('data');
          final result = hasNested ? (data['result'] ?? data['data']) : data;

          if (result is Map) {
            final itemMap = Map<String, dynamic>.from(result);
            final directId = extractDirectId(itemMap) ?? extractDirectId(data);
            if (directId != null && itemMap['id'] == null) {
              itemMap['id'] = directId;
            }
            parsedConv = SupportConversation.fromJson(
              itemMap,
              currentUserId: SupportChatHubService.instance.currentUserId,
            );
          } else {
            final directId = extractDirectId(result) ?? extractDirectId(data);
            if (directId != null) {
              parsedConv = SupportConversation(
                id: directId,
                topicId: supportTopicId,
                topicName: subject,
                title: subject,
              );
            }
          }
        } else if (data is String && data.trim().isNotEmpty) {
          parsedConv = SupportConversation(
            id: data.trim(),
            topicId: supportTopicId,
            topicName: subject,
            title: subject,
          );
        }

        // Əgər POST /create cavabında id qaytarılmayıbsa (məs: { isSuccess: true }),
        // dərhal /my siyahısından yeni yaradılmış aktiv müraciəti tapıb real id-ni götürürük.
        if (parsedConv == null || parsedConv.id.trim().isEmpty) {
          debugPrint(
            '🔄 [SUPPORT_CHAT CREATE] Cavabda id tapılmadı, /my siyahısından axtarılır...',
          );
          final myList = await getMyConversations();
          final normTopicId = supportTopicId.trim().toLowerCase();
          final normSubject = (subject ?? '').trim().toLowerCase();

          int compareNewestFirst(
            SupportConversation a,
            SupportConversation b,
          ) {
            final aTime =
                a.createdDate ??
                a.lastMessageDate ??
                a.updatedDate ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.createdDate ??
                b.lastMessageDate ??
                b.updatedDate ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          }

          final matched = myList.where((c) {
            if (!c.isOpen || c.id.trim().isEmpty) return false;
            if (c.topicId != null &&
                c.topicId!.trim().toLowerCase() == normTopicId) {
              return true;
            }
            if (normSubject.isNotEmpty &&
                (c.topicName?.trim().toLowerCase() == normSubject ||
                    c.title?.trim().toLowerCase() == normSubject)) {
              return true;
            }
            return false;
          }).toList()..sort(compareNewestFirst);

          if (matched.isNotEmpty) {
            parsedConv = matched.first;
          } else {
            final anyOpen = myList
                .where((c) => c.isOpen && c.id.trim().isNotEmpty)
                .toList()
              ..sort(compareNewestFirst);
            if (anyOpen.isNotEmpty) {
              parsedConv = anyOpen.first;
            }
          }
          debugPrint(
            '✅ [SUPPORT_CHAT CREATE] /my siyahısından tapılan convId: ${parsedConv?.id}',
          );
        }

        if (parsedConv != null && parsedConv.id.trim().isNotEmpty) {
          return parsedConv;
        }
      }
      throw Exception('Söhbət yaradıla bilmədi: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [SUPPORT_CHAT CREATE XƏTASI]: $e');
      rethrow;
    }
  }

  /// Müştərinin özünə aid aktiv və köhnə söhbətlər siyahısı
  /// GET /api/SupportConversations/my?languageCode={lang}
  Future<List<SupportConversation>> getMyConversations({
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.supportConversationsMy,
        queryParameters: {'languageCode': lang},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        List<dynamic> list = [];

        if (data is Map) {
          final result = data['result'] ?? data['data'] ?? data['items'];
          if (result is List) {
            list = result;
          } else if (result is Map && result['items'] is List) {
            list = result['items'] as List;
          }
        } else if (data is List) {
          list = data;
        }

        return list
            .map(
              (item) => SupportConversation.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ [SUPPORT_CHAT MY XƏTASI]: $e');
      rethrow;
    }
  }

  /// Seçilmiş söhbətin içindəki mesajların tarixçəsi
  /// GET /api/SupportConversations/my/{id}?languageCode={lang}
  Future<SupportConversation> getConversationDetails(
    String conversationId, {
    String? languageCode,
  }) async {
    try {
      final lang = languageCode ?? AppLocalizations.currentLanguageCode;
      final response = await _client.get(
        ApiEndpoints.supportConversationsMyById(conversationId),
        queryParameters: {'languageCode': lang},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        Map<String, dynamic> itemMap = {};

        if (data is Map) {
          final result = data['result'] ?? data['data'] ?? data;
          if (result is Map) {
            itemMap = Map<String, dynamic>.from(result);
          }
        }

        return SupportConversation.fromJson(
          itemMap,
          currentUserId: SupportChatHubService.instance.currentUserId,
        );
      }
      throw Exception('Söhbət detalları alına bilmədi: ${response.statusCode}');
    } catch (e) {
      debugPrint('❌ [SUPPORT_CHAT MY BY ID XƏTASI]: $e');
      rethrow;
    }
  }

  /// Söhbətə yeni mesaj göndərmək (REST API)
  /// POST /api/SupportConversations/my/{id}/messages
  Future<SupportChatMessage?> sendMessageRest(
    String conversationId, {
    required String content,
    String messageType = 'Text',
    String? attachmentFileId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType,
        if (attachmentFileId != null && attachmentFileId.trim().isNotEmpty)
          'attachmentFileId': attachmentFileId.trim(),
      };

      final response = await _client.post(
        ApiEndpoints.supportConversationsMyMessages(conversationId),
        data: payload,
      );

      if (kDebugMode) {
        debugPrint('📦 [SUPPORT_CHAT SEND REST RES]: ${response.statusCode}');
      }

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        final data = response.data;
        if (data is Map) {
          final hasNestedPayload =
              data.containsKey('result') || data.containsKey('data');
          final result = hasNestedPayload
              ? (data['result'] ?? data['data'])
              : data;

          if (result is Map) {
            final resultMap = Map<String, dynamic>.from(result);
            final realId = (resultMap['id'] ?? resultMap['messageId'])
                ?.toString()
                .trim();
            if (realId != null && realId.isNotEmpty) {
              final parsed = SupportChatMessage.fromJson(
                resultMap,
                currentUserId: SupportChatHubService.instance.currentUserId,
              );
              return parsed.copyWith(
                id: realId,
                conversationId: parsed.conversationId ?? conversationId,
                content: parsed.content.isNotEmpty ? parsed.content : content,
                messageType: messageType,
                attachmentFileId: parsed.attachmentFileId ?? attachmentFileId,
                isUser: true,
                createdDate: parsed.createdDate ?? DateTime.now(),
              );
            }
          } else if (result is String && result.trim().isNotEmpty) {
            return SupportChatMessage(
              id: result.trim(),
              conversationId: conversationId,
              sender: 'Customer',
              isUser: true,
              messageType: messageType,
              content: content,
              attachmentFileId: attachmentFileId,
              createdDate: DateTime.now(),
            );
          }
        } else if (data is String && data.trim().isNotEmpty) {
          return SupportChatMessage(
            id: data.trim(),
            conversationId: conversationId,
            sender: 'Customer',
            isUser: true,
            messageType: messageType,
            content: content,
            attachmentFileId: attachmentFileId,
            createdDate: DateTime.now(),
          );
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [SUPPORT_CHAT SEND REST XƏTASI]: $e');
      rethrow;
    }
  }

  /// Qarşı tərəfdən gələn mesajları "oxundu" statusuna keçirmək
  /// POST /api/SupportConversations/my/{conversationId}/messages/seen (body: {})
  Future<bool> markMessagesSeen(String conversationId) async {
    try {
      final response = await _client.post(
        ApiEndpoints.supportConversationsMyMessagesSeen(conversationId),
        data: const <String, dynamic>{},
      );

      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } catch (e) {
      debugPrint('⚠️ [SUPPORT_CHAT MARK SEEN XƏTASI]: $e');
      return false;
    }
  }

  /// Müştərinin söhbəti bağlaması
  /// POST /api/SupportConversations/my/{id}/close
  Future<bool> closeConversation(String conversationId) async {
    try {
      final response = await _client.post(
        ApiEndpoints.supportConversationsMyClose(conversationId),
      );
      final statusCode = response.statusCode ?? 0;
      return statusCode >= 200 && statusCode < 300;
    } catch (e) {
      debugPrint('❌ [SUPPORT_CHAT CLOSE XƏTASI]: $e');
      rethrow;
    }
  }
}
