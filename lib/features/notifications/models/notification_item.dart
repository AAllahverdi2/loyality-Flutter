import 'dart:convert';

import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';

enum AppNotificationType { personal, broadcast }

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetUserId,
    this.payloadJson,
    this.imageFileId,
    this.createdAt,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final String? targetUserId;
  final String? payloadJson;
  final String? imageFileId;
  final DateTime? createdAt;
  final bool isRead;

  String? get imageUrl {
    final id = imageFileId?.trim();
    if (id == null || id.isEmpty || id.toLowerCase() == 'null') {
      return null;
    }
    return '${ApiEndpoints.baseUrl}${ApiEndpoints.fileDownload(id)}';
  }

  bool get isPersonal => type == AppNotificationType.personal;

  bool get isBroadcast => type == AppNotificationType.broadcast;

  Map<String, dynamic>? get parsedPayload {
    final raw = payloadJson?.trim();
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  String? get action => parsedPayload?['action']?.toString().trim();

  String get typeLabel => isPersonal
      ? tr('notifications_type_personal')
      : tr('notifications_type_broadcast');

  String get formattedTime {
    final dt = createdAt?.toLocal();
    if (dt == null) return '';

    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds >= 0 && diff.inSeconds < 60) {
      return tr('notifications_just_now');
    }
    if (diff.inMinutes >= 1 && diff.inMinutes < 60) {
      return tr('notifications_minutes_ago', {'count': '${diff.inMinutes}'});
    }

    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    final timeStr = '$hh:$mm';

    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final dayDiff = today.difference(itemDay).inDays;

    if (dayDiff == 0) {
      return diff.inHours < 6
          ? tr('notifications_hours_ago', {'count': '${diff.inHours}'})
          : timeStr;
    }
    if (dayDiff == 1) {
      return tr('notifications_yesterday', {'time': timeStr});
    }

    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    return '$dd.$mo.${dt.year} $timeStr';
  }

  String get formattedFullDate {
    final dt = createdAt?.toLocal();
    if (dt == null) return '';
    final dd = dt.day.toString().padLeft(2, '0');
    final mo = dt.month.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$dd.$mo.${dt.year}  $hh:$mm';
  }

  static dynamic _readField(Map<String, dynamic> lowerJson, List<String> keys) {
    for (final key in keys) {
      if (lowerJson.containsKey(key) && lowerJson[key] != null) {
        return lowerJson[key];
      }
    }
    return null;
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final lowerJson = <String, dynamic>{
      for (final entry in json.entries) entry.key.trim().toLowerCase(): entry.value,
    };

    final rawType = _readField(lowerJson, const ['type', 'notificationtype']);
    AppNotificationType parsedType = AppNotificationType.personal;
    if (rawType is num) {
      parsedType = rawType.toInt() == 2
          ? AppNotificationType.broadcast
          : AppNotificationType.personal;
    } else if (rawType != null) {
      final t = rawType.toString().trim().toLowerCase();
      if (t == '2' || t == 'broadcast' || t == 'general' || t == 'ümumi') {
        parsedType = AppNotificationType.broadcast;
      }
    }

    String? normalizedPayloadJson;
    final rawPayload = _readField(lowerJson, const ['payloadjson', 'payload']);
    if (rawPayload is String && rawPayload.trim().isNotEmpty) {
      normalizedPayloadJson = rawPayload.trim();
    } else if (rawPayload is Map) {
      normalizedPayloadJson = jsonEncode(rawPayload);
    }

    final rawCreatedAt = _readField(lowerJson, const [
      'createdat',
      'createddate',
    ]);
    DateTime? parsedCreatedAt;
    if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    } else if (rawCreatedAt != null) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString().trim());
    }

    final rawIsRead = _readField(lowerJson, const ['isread', 'read']);
    final isReadText = rawIsRead?.toString().trim().toLowerCase();
    final parsedIsRead = rawIsRead is bool
        ? rawIsRead
        : rawIsRead is num
        ? rawIsRead != 0
        : (isReadText == 'true' || isReadText == '1');

    final rawImageId = _readField(lowerJson, const [
      'imagefileid',
      'fileid',
      'attachid',
      'imageid',
    ])?.toString().trim();
    final normalizedImageId =
        (rawImageId == null ||
            rawImageId.isEmpty ||
            rawImageId.toLowerCase() == 'null')
        ? null
        : rawImageId;

    return AppNotification(
      id: (_readField(lowerJson, const ['id', 'notificationid']) ?? '')
          .toString()
          .trim(),
      title: (_readField(lowerJson, const ['title', 'subject']) ?? '')
          .toString()
          .trim(),
      body:
          (_readField(lowerJson, const [
                    'body',
                    'message',
                    'content',
                    'text',
                  ]) ??
                  '')
              .toString()
              .trim(),
      type: parsedType,
      targetUserId: _readField(lowerJson, const [
        'targetuserid',
        'userid',
      ])?.toString().trim(),
      payloadJson: normalizedPayloadJson,
      imageFileId: normalizedImageId,
      createdAt: parsedCreatedAt,
      isRead: parsedIsRead,
    );
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    AppNotificationType? type,
    String? targetUserId,
    String? payloadJson,
    String? imageFileId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      targetUserId: targetUserId ?? this.targetUserId,
      payloadJson: payloadJson ?? this.payloadJson,
      imageFileId: imageFileId ?? this.imageFileId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationsPageResult {
  const NotificationsPageResult({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.hasMore,
  });

  final List<AppNotification> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final bool hasMore;
}
