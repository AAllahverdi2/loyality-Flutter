class SupportChatMessage {
  final String id;
  final String? conversationId;
  final String? sender;
  final String? senderName;
  final bool isUser;
  final String messageType;
  final String content;
  final String? attachmentFileId;
  final String? attachmentUrl;
  final bool isRead;
  final DateTime? seenAt;
  final DateTime? createdDate;
  final bool isSending;
  final bool hasFailed;
  final Map<String, dynamic>? rawJson;

  const SupportChatMessage({
    required this.id,
    this.conversationId,
    this.sender,
    this.senderName,
    this.isUser = true,
    this.messageType = 'Text',
    required this.content,
    this.attachmentFileId,
    this.attachmentUrl,
    this.isRead = false,
    this.seenAt,
    this.createdDate,
    this.isSending = false,
    this.hasFailed = false,
    this.rawJson,
  });

  /// Mesajın qarşı tərəfdən oxunub-oxunmadığı (seenAt !== null -> iki mavi xətt)
  bool get isSeen => seenAt != null || isRead;

  /// Sistem bildirişi mesajı olub-olmadığı (məs: "Operator təyin edildi. Operator: ...")
  bool get isSystemMessage {
    final s = (sender ?? '').trim().toLowerCase();
    final sn = (senderName ?? '').trim().toLowerCase();
    final mt = messageType.trim().toLowerCase();
    if (s == 'system' ||
        s == 'systemmessage' ||
        s == 'bot' ||
        s == '3' ||
        sn == 'system' ||
        sn == 'sistem' ||
        mt == 'system' ||
        mt == 'systemmessage' ||
        mt == 'info' ||
        mt == 'event' ||
        mt == 'notification') {
      return true;
    }

    final c = content.trim().toLowerCase();
    if (!isUser &&
        (c.startsWith('operator təyin edildi') ||
            c.startsWith('operator teyin edildi') ||
            c.startsWith('operator assigned') ||
            c.startsWith('оператор назначен') ||
            c.contains('operator təyin edildi'))) {
      return true;
    }
    return false;
  }

  factory SupportChatMessage.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final senderTypeValue =
        json['senderType'] ??
        json['senderRole'] ??
        json['sender'] ??
        json['role'] ??
        json['from'];
    final senderTypeCode = senderTypeValue is num
        ? senderTypeValue.toInt()
        : int.tryParse(senderTypeValue?.toString() ?? '');
    final rawSender =
        (senderTypeValue ??
                json['senderRole'] ??
                json['sender'] ??
                json['role'] ??
                json['from'] ??
                '')
            .toString()
            .trim();
    final senderLower = rawSender.toLowerCase();

    final rawSenderUserId =
        (json['senderUserId'] ?? json['senderId'] ?? json['authorId'])
            ?.toString()
            .trim();
    final hasKnownCurrentUser =
        currentUserId != null &&
        currentUserId.trim().isNotEmpty &&
        rawSenderUserId != null &&
        rawSenderUserId.isNotEmpty;
    final matchesCurrentUser =
        hasKnownCurrentUser &&
        rawSenderUserId.toLowerCase() == currentUserId.trim().toLowerCase();
    final differsFromCurrentUser =
        hasKnownCurrentUser && !matchesCurrentUser;

    final isCustomer =
        matchesCurrentUser ||
        senderTypeCode == 1 ||
        json['isFromUser'] == true ||
        json['isFromCustomer'] == true ||
        json['fromCustomer'] == true ||
        json['isCustomer'] == true ||
        json['isUser'] == true ||
        json['isMine'] == true ||
        senderLower == 'user' ||
        senderLower == 'customer' ||
        senderLower == 'client' ||
        senderLower == 'member' ||
        senderLower == 'mobileuser' ||
        senderLower == 'me';

    final isOperator =
        differsFromCurrentUser ||
        senderTypeCode == 2 ||
        senderTypeCode == 3 ||
        json['isOperator'] == true ||
        json['isFromOperator'] == true ||
        json['isAdmin'] == true ||
        json['isSystem'] == true ||
        json['isFromUser'] == false ||
        json['isCustomer'] == false ||
        json['isUser'] == false ||
        json['isMine'] == false ||
        senderLower == 'operator' ||
        senderLower == 'admin' ||
        senderLower == 'support' ||
        senderLower == 'supportagent' ||
        senderLower == 'agent' ||
        senderLower == 'staff' ||
        senderLower == 'moderator' ||
        senderLower == 'system' ||
        senderLower == 'systemmessage' ||
        senderLower == 'bot' ||
        json['messageType']?.toString().toLowerCase() == 'system' ||
        (json['operatorId'] != null && json['customerId'] == null);

    final computedIsUser = isCustomer || !isOperator;

    final rawCreatedDate =
        json['createdDate'] ??
        json['createdAt'] ??
        json['sentAt'] ??
        json['date'] ??
        json['timestamp'];

    DateTime? dt;
    if (rawCreatedDate != null) {
      if (rawCreatedDate is DateTime) {
        dt = rawCreatedDate;
      } else {
        dt = DateTime.tryParse(rawCreatedDate.toString());
      }
    }

    final nestedAttachment = json['attachment'] is Map
        ? Map<String, dynamic>.from(json['attachment'] as Map)
        : null;

    final attachId =
        (json['attachmentFileId'] ??
                json['fileId'] ??
                json['attachmentId'] ??
                nestedAttachment?['fileId'] ??
                nestedAttachment?['id'])
            ?.toString();

    final attachUrl =
        (json['attachmentUrl'] ??
                json['fileUrl'] ??
                nestedAttachment?['url'] ??
                nestedAttachment?['fileUrl'])
            ?.toString();

    final contentStr =
        json['content']?.toString() ??
        json['text']?.toString() ??
        json['message']?.toString() ??
        '';

    final rawSeenAt = json['seenAt'] ?? json['readAt'];
    final rawSeenStr = rawSeenAt?.toString().trim() ?? '';
    final hasValidRawSeenAt =
        rawSeenAt != null &&
        rawSeenStr.isNotEmpty &&
        rawSeenStr.toLowerCase() != 'null';

    DateTime? parsedSeenAt;
    if (hasValidRawSeenAt) {
      if (rawSeenAt is DateTime) {
        parsedSeenAt = rawSeenAt;
      } else {
        parsedSeenAt = DateTime.tryParse(rawSeenStr) ?? DateTime.now();
      }
    }

    final hasSeenFlag =
        parsedSeenAt != null ||
        hasValidRawSeenAt ||
        json['isRead'] == true ||
        json['isSeen'] == true ||
        json['seen'] == true;

    return SupportChatMessage(
      id:
          (json['id'] ?? json['messageId'])?.toString() ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      conversationId: json['conversationId']?.toString(),
      sender: rawSender,
      senderName:
          (json['operatorName'] ?? json['senderName'] ?? json['senderTypeName'])
              ?.toString(),
      isUser: computedIsUser,
      messageType: json['messageType']?.toString() ?? 'Text',
      content: contentStr,
      attachmentFileId: (attachId != null && attachId.isNotEmpty)
          ? attachId
          : null,
      attachmentUrl: (attachUrl != null && attachUrl.isNotEmpty)
          ? attachUrl
          : null,
      isRead: hasSeenFlag,
      seenAt: parsedSeenAt,
      createdDate: dt,
      isSending: false,
      hasFailed: false,
      rawJson: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'sender': sender,
      'senderName': senderName,
      'isUser': isUser,
      'messageType': messageType,
      'content': content,
      'attachmentFileId': attachmentFileId,
      'attachmentUrl': attachmentUrl,
      'isRead': isRead,
      'seenAt': seenAt?.toIso8601String(),
      'createdDate': createdDate?.toIso8601String(),
    };
  }

  String get timeStr {
    final dt = (createdDate ?? DateTime.now()).toLocal();
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$hour:$min';
  }

  SupportChatMessage copyWith({
    String? id,
    String? conversationId,
    String? sender,
    String? senderName,
    bool? isUser,
    String? messageType,
    String? content,
    String? attachmentFileId,
    String? attachmentUrl,
    bool? isRead,
    DateTime? seenAt,
    DateTime? createdDate,
    bool? isSending,
    bool? hasFailed,
    Map<String, dynamic>? rawJson,
  }) {
    return SupportChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      sender: sender ?? this.sender,
      senderName: senderName ?? this.senderName,
      isUser: isUser ?? this.isUser,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      attachmentFileId: attachmentFileId ?? this.attachmentFileId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      isRead: isRead ?? this.isRead,
      seenAt: seenAt ?? this.seenAt,
      createdDate: createdDate ?? this.createdDate,
      isSending: isSending ?? this.isSending,
      hasFailed: hasFailed ?? this.hasFailed,
      rawJson: rawJson ?? this.rawJson,
    );
  }
}
