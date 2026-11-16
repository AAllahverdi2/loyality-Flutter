import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';

class SupportConversation {
  final String id;
  final String? topicId;
  final String? topicName;
  final String? title;
  final String? status;
  final String? statusName;
  final int unreadMessagesCount;
  final DateTime? createdDate;
  final DateTime? updatedDate;
  final String? lastMessage;
  final DateTime? lastMessageDate;
  final List<SupportChatMessage> messages;

  const SupportConversation({
    required this.id,
    this.topicId,
    this.topicName,
    this.title,
    this.status,
    this.statusName,
    int? unreadMessagesCount,
    int? unreadCount,
    this.createdDate,
    this.updatedDate,
    this.lastMessage,
    this.lastMessageDate,
    this.messages = const [],
  }) : unreadMessagesCount = unreadMessagesCount ?? unreadCount ?? 0;

  /// Köhnə sahə adı ilə geriyə uyğunluq üçün getter
  int get unreadCount => unreadMessagesCount;

  bool get isClosed {
    final s = status?.toLowerCase() ?? '';
    final sn = statusName?.toLowerCase() ?? '';
    return s == 'closed' ||
        s == 'bagli' ||
        s == 'bağlı' ||
        s == '4' ||
        s == '5' ||
        s.contains('resolved') ||
        s.contains('solved') ||
        s.contains('həll') ||
        sn.contains('bağ') ||
        sn.contains('close') ||
        sn.contains('resolved') ||
        sn.contains('həll');
  }

  bool get isOpen => !isClosed;

  factory SupportConversation.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    List<SupportChatMessage> parseMessages(dynamic raw) {
      if (raw is List) {
        return raw
            .map(
              (item) => SupportChatMessage.fromJson(
                Map<String, dynamic>.from(item as Map),
                currentUserId: currentUserId,
              ),
            )
            .toList();
      }
      return [];
    }

    final rawMessages = json['messages'] ?? json['conversationMessages'] ?? [];
    final parsedMessages = parseMessages(rawMessages);

    String? parseLastMessage(dynamic rawLast) {
      if (rawLast == null) {
        final fallback = json['lastMessageContent'] ?? json['lastMessageText'];
        if (fallback != null) return fallback.toString();
        if (parsedMessages.isNotEmpty) return parsedMessages.last.content;
        return null;
      }
      if (rawLast is Map) {
        return (rawLast['content'] ?? rawLast['text'] ?? rawLast['message'])
            ?.toString();
      }
      return rawLast.toString();
    }

    final rawUnread =
        json['unreadMessagesCount'] ??
        json['unreadCount'] ??
        json['customerUnreadCount'] ??
        json['unreadMessageCount'];

    int parsedUnread = 0;
    if (rawUnread is num) {
      parsedUnread = rawUnread.toInt();
    } else if (rawUnread != null) {
      parsedUnread = int.tryParse(rawUnread.toString().trim()) ?? 0;
    }
    if (parsedUnread < 0) {
      parsedUnread = 0;
    }

    return SupportConversation(
      id: (json['id'] ?? json['conversationId'])?.toString() ?? '',
      topicId:
          (json['supportTopicId'] ??
                  json['topicId'] ??
                  json['supportTopic']?['id'] ??
                  json['topic']?['id'])
              ?.toString(),
      topicName:
          (json['supportTopicName'] ??
                  json['topicName'] ??
                  json['supportTopic']?['name'] ??
                  json['topic']?['name'])
              ?.toString(),
      title: (json['subject'] ?? json['title'])?.toString(),
      status: json['status']?.toString(),
      statusName: json['statusName']?.toString(),
      unreadMessagesCount: parsedUnread,
      createdDate: parseDate(json['createdDate'] ?? json['createdAt']),
      updatedDate: parseDate(json['updatedDate'] ?? json['updatedAt']),
      lastMessage: parseLastMessage(json['lastMessage']),
      lastMessageDate: parseDate(
        json['lastMessageDate'] ??
            json['lastMessageAt'] ??
            (json['lastMessage'] is Map
                ? (json['lastMessage']['createdDate'] ??
                      json['lastMessage']['createdAt'])
                : null),
      ),
      messages: parsedMessages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'topicId': topicId,
      'topicName': topicName,
      'title': title,
      'status': status,
      'statusName': statusName,
      'unreadMessagesCount': unreadMessagesCount,
      'unreadCount': unreadMessagesCount,
      'createdDate': createdDate?.toIso8601String(),
      'updatedDate': updatedDate?.toIso8601String(),
      'lastMessage': lastMessage,
      'lastMessageDate': lastMessageDate?.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  SupportConversation copyWith({
    String? id,
    String? topicId,
    String? topicName,
    String? title,
    String? status,
    String? statusName,
    int? unreadMessagesCount,
    int? unreadCount,
    DateTime? createdDate,
    DateTime? updatedDate,
    String? lastMessage,
    DateTime? lastMessageDate,
    List<SupportChatMessage>? messages,
  }) {
    return SupportConversation(
      id: id ?? this.id,
      topicId: topicId ?? this.topicId,
      topicName: topicName ?? this.topicName,
      title: title ?? this.title,
      status: status ?? this.status,
      statusName: statusName ?? this.statusName,
      unreadMessagesCount:
          unreadMessagesCount ?? unreadCount ?? this.unreadMessagesCount,
      createdDate: createdDate ?? this.createdDate,
      updatedDate: updatedDate ?? this.updatedDate,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageDate: lastMessageDate ?? this.lastMessageDate,
      messages: messages ?? this.messages,
    );
  }
}
