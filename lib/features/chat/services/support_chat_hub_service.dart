import 'dart:async';
import 'dart:convert';

import 'package:loyallig_flutter/core/constants/api_endpoints.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';
import 'package:loyallig_flutter/features/profile/services/profile_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

class OperatorTypingEvent {
  final String? conversationId;
  final String? operatorUserId;
  final bool isTyping;

  const OperatorTypingEvent({
    this.conversationId,
    this.operatorUserId,
    required this.isTyping,
  });
}

class MessagesSeenEvent {
  final String? conversationId;
  final List<String> messageIds;
  final DateTime? seenAt;
  final bool hasExplicitSeenAt;

  const MessagesSeenEvent({
    this.conversationId,
    required this.messageIds,
    this.seenAt,
    this.hasExplicitSeenAt = false,
  });
}

class ConversationStatusEvent {
  final String? conversationId;
  final String status;
  final String? statusName;

  const ConversationStatusEvent({
    this.conversationId,
    required this.status,
    this.statusName,
  });
}

class SupportChatHubService {
  SupportChatHubService._internal();
  static final SupportChatHubService instance =
      SupportChatHubService._internal();

  HubConnection? _hubConnection;
  Completer<bool>? _connectCompleter;
  String? _activeConversationId;
  String? _currentUserId;

  // Öz typing echo-muzu filtr etmək üçün (əgər backend senderUserId göndərməzsə)
  String? _lastSentTypingConvId;
  bool? _lastSentTypingValue;
  DateTime? _lastSentTypingAt;

  // Eyni mesajın həm conversation group-dan, həm də user_{userId} otağından dublikat gəlməsini filtr etmək üçün
  final Map<String, DateTime> _recentReceivedMsgIds = {};

  // Qlobal oxundu keşi (MessagesSeen çat ekranı açılmazdan əvvəl user_{userId}-ə gələrsə)
  final Map<String, DateTime> globalSeenTimestamps = {};

  // Streams for UI
  final _messageController = StreamController<SupportChatMessage>.broadcast();
  final _typingController = StreamController<OperatorTypingEvent>.broadcast();
  final _seenController = StreamController<MessagesSeenEvent>.broadcast();
  final _statusController =
      StreamController<ConversationStatusEvent>.broadcast();
  final _connectionStateController =
      StreamController<HubConnectionState>.broadcast();

  Stream<SupportChatMessage> get onMessageReceived => _messageController.stream;
  Stream<OperatorTypingEvent> get onOperatorTyping => _typingController.stream;
  Stream<MessagesSeenEvent> get onMessagesSeen => _seenController.stream;
  Stream<ConversationStatusEvent> get onStatusChanged =>
      _statusController.stream;
  Stream<HubConnectionState> get onConnectionStateChanged =>
      _connectionStateController.stream;

  HubConnectionState get state =>
      _hubConnection?.state ?? HubConnectionState.Disconnected;

  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  String? get currentUserId => _currentUserId;

  String? get activeConversationId => _activeConversationId;

  String? _extractUserIdFromJwt(String? token) {
    if (token == null || token.trim().isEmpty) return null;
    try {
      final parts = token.trim().split('.');
      if (parts.length != 3) return null;
      final normalized = base64Url.normalize(parts[1]);
      final payloadStr = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(payloadStr);
      if (decoded is Map) {
        return (decoded['sub'] ??
                decoded['nameid'] ??
                decoded['userId'] ??
                decoded['UserId'] ??
                decoded['uid'] ??
                decoded['id'] ??
                decoded[
                    'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'])
            ?.toString();
      }
    } catch (_) {}
    return null;
  }

  String _resolveUserId([String? explicit]) {
    final candidates = <String?>[
      explicit,
      _currentUserId,
      _extractUserIdFromJwt(ApiClient.instance.accessToken),
      ProfileService.cachedProfile?.id,
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) {
        return c.trim();
      }
    }
    return '';
  }

  bool _isBoolLike(dynamic val) {
    if (val is bool) return true;
    if (val is num) return val == 0 || val == 1;
    if (val is String) {
      final s = val.trim().toLowerCase();
      return s == 'true' || s == 'false';
    }
    return false;
  }

  bool _parseBool(dynamic val) {
    if (val is bool) return val;
    if (val is num) return val != 0;
    if (val != null) return val.toString().trim().toLowerCase() == 'true';
    return false;
  }

  /// Hub-a qoşulmaq
  Future<bool> initAndConnect() async {
    if (isConnected) {
      return true;
    }

    if (_connectCompleter != null) {
      return _connectCompleter!.future;
    }

    final completer = Completer<bool>();
    _connectCompleter = completer;

    try {
      String? initialToken = ApiClient.instance.accessToken;
      initialToken ??= await TokenStorage.getAccessToken();
      if (initialToken != null && initialToken.startsWith('Bearer ')) {
        initialToken = initialToken.substring(7).trim();
      }
      if (initialToken == null || initialToken.trim().isEmpty) {
        completer.complete(false);
        return false;
      }
      _currentUserId = _extractUserIdFromJwt(initialToken);

      _connectionStateController.add(HubConnectionState.Connecting);

      if (_hubConnection != null) {
        try {
          await _hubConnection?.stop();
        } catch (_) {}
        _hubConnection = null;
      }

      final hubUrl = ApiEndpoints.supportChatHub;

      _hubConnection = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            options: HttpConnectionOptions(
              accessTokenFactory: () async {
                String? token = ApiClient.instance.accessToken;
                token ??= await TokenStorage.getAccessToken();
                if (token != null && token.startsWith('Bearer ')) {
                  token = token.substring(7).trim();
                }
                _currentUserId = _extractUserIdFromJwt(token);
                return token ?? '';
              },
            ),
          )
          .withAutomaticReconnect()
          .build();

      _setupListeners();

      _hubConnection?.onreconnecting(({error}) {
        _connectionStateController.add(HubConnectionState.Reconnecting);
      });

      _hubConnection?.onreconnected(({connectionId}) {
        _connectionStateController.add(HubConnectionState.Connected);
        // Connection yenidən qurularsa JoinConversation(conversationId) təkrar çağırılır
        if (_activeConversationId != null) {
          joinConversation(_activeConversationId!);
        }
      });

      _hubConnection?.onclose(({error}) {
        _connectionStateController.add(HubConnectionState.Disconnected);
      });

      await _hubConnection?.start();
      _connectionStateController.add(HubConnectionState.Connected);
      completer.complete(true);
      return true;
    } catch (_) {
      _connectionStateController.add(HubConnectionState.Disconnected);
      completer.complete(false);
      return false;
    } finally {
      _connectCompleter = null;
    }
  }

  void _handleTypingEvent(
    List<dynamic>? args, {
    required String eventName,
    bool isExplicitOperatorEvent = false,
  }) {
    try {
      bool isTyping = false;
      String? convId;
      String? senderUserId;
      String? senderType;
      String? senderConnectionId;

      if (args != null && args.isNotEmpty) {
        if (args[0] is Map) {
          final map = args[0] as Map;
          isTyping = _parseBool(map['isTyping'] ?? map['typing']);
          convId = map['conversationId']?.toString();
          senderUserId =
              (map['operatorUserId'] ??
                      map['senderUserId'] ??
                      map['userId'] ??
                      map['senderId'])
                  ?.toString();
          senderType =
              (map['senderType'] ?? map['senderRole'] ?? map['role'])
                  ?.toString();
          senderConnectionId =
              (map['connectionId'] ?? map['senderConnectionId'])?.toString();
        } else if (args.length >= 3) {
          // Backend formatı: OperatorTyping(conversationId, operatorUserId, isTyping) -> args[2]
          convId = args[0]?.toString();
          if (_isBoolLike(args[2])) {
            senderUserId = args[1]?.toString();
            isTyping = _parseBool(args[2]);
            if (args.length >= 4 && args[3] != null) {
              senderType = args[3]?.toString();
            }
          } else if (_isBoolLike(args[1])) {
            // Ehtiyat format: (conversationId, isTyping, senderUserId)
            isTyping = _parseBool(args[1]);
            if (args[2] is Map) {
              final meta = args[2] as Map;
              senderUserId =
                  (meta['operatorUserId'] ??
                          meta['senderUserId'] ??
                          meta['userId'])
                      ?.toString();
              senderType = meta['senderType']?.toString();
              senderConnectionId = meta['connectionId']?.toString();
            } else {
              senderUserId = args[2]?.toString();
            }
            if (args.length >= 4 && args[3] != null) {
              senderType = args[3]?.toString();
            }
          } else {
            senderUserId = args[1]?.toString();
            isTyping = _parseBool(args[2]);
          }
        } else if (args.length == 2) {
          if (_isBoolLike(args[0]) && !_isBoolLike(args[1])) {
            isTyping = _parseBool(args[0]);
            convId = args[1]?.toString();
          } else {
            convId = args[0]?.toString();
            isTyping = _parseBool(args[1]);
          }
        } else if (args.length == 1) {
          isTyping = _parseBool(args[0]);
        }
      }

      if (!isExplicitOperatorEvent) {
        // 1. Öz connectionId-mizdirsə filtr et
        final myConnId = _hubConnection?.connectionId;
        if (senderConnectionId != null &&
            myConnId != null &&
            senderConnectionId == myConnId) {
          return;
        }

        // 2. Öz userId-mizdirsə filtr et
        if (senderUserId != null &&
            senderUserId.isNotEmpty &&
            _currentUserId != null &&
            _currentUserId!.isNotEmpty &&
            senderUserId.toLowerCase() == _currentUserId!.toLowerCase()) {
          return;
        }

        // 3. senderType müştəridirsə filtr et
        if (senderType != null && senderType.trim().isNotEmpty) {
          final st = senderType.trim().toLowerCase();
          if (st == 'customer' ||
              st == 'user' ||
              st == 'client' ||
              st == 'mobileuser' ||
              st == '1') {
            return;
          }
        }

        // 4. Əgər backend sender məlumatı göndərməyibsə və öz SendTyping çağırışımızın
        // dərhal geri qayıdan echo-sudursa filtr et
        final hasSenderMetadata =
            (senderUserId != null && senderUserId.isNotEmpty) ||
            (senderType != null && senderType.isNotEmpty) ||
            (senderConnectionId != null && senderConnectionId.isNotEmpty);

        final targetConvId = convId ?? _activeConversationId;
        if (!hasSenderMetadata &&
            _lastSentTypingAt != null &&
            _lastSentTypingConvId != null &&
            targetConvId != null &&
            _lastSentTypingConvId!.toLowerCase() ==
                targetConvId.toLowerCase() &&
            _lastSentTypingValue == isTyping &&
            DateTime.now().difference(_lastSentTypingAt!) <
                const Duration(milliseconds: 600)) {
          _lastSentTypingAt = null;
          return;
        }
      }

      _typingController.add(
        OperatorTypingEvent(
          conversationId: convId ?? _activeConversationId,
          operatorUserId: senderUserId,
          isTyping: isTyping,
        ),
      );
    } catch (_) {}
  }

  void _setupListeners() {
    // 1. Yeni Mesaj: ReceiveMessage(message) — həm qrupa, həm də user_{userId} otağına gəlir
    _hubConnection?.on('ReceiveMessage', (List<dynamic>? args) {
      try {
        if (args != null && args.isNotEmpty) {
          Map<String, dynamic>? msgMap;
          String? convIdFromArgs;

          if (args[0] is Map) {
            msgMap = Map<String, dynamic>.from(args[0] as Map);
          } else if (args.length >= 2 && args[1] is Map) {
            convIdFromArgs = args[0]?.toString();
            msgMap = Map<String, dynamic>.from(args[1] as Map);
          } else if (args.length >= 3 && args[2] is Map) {
            convIdFromArgs = args[0]?.toString();
            msgMap = Map<String, dynamic>.from(args[2] as Map);
          }

          if (msgMap != null) {
            if (convIdFromArgs != null && msgMap['conversationId'] == null) {
              msgMap['conversationId'] = convIdFromArgs;
            }

            final rawServerId = (msgMap['id'] ?? msgMap['messageId'])
                ?.toString()
                .trim();
            if (rawServerId != null && rawServerId.isNotEmpty) {
              final normId = rawServerId.toLowerCase();
              final now = DateTime.now();
              _recentReceivedMsgIds.removeWhere(
                (_, ts) => now.difference(ts) > const Duration(seconds: 6),
              );
              if (_recentReceivedMsgIds.containsKey(normId)) {
                return;
              }
              _recentReceivedMsgIds[normId] = now;
            }

            final msg = SupportChatMessage.fromJson(
              msgMap,
              currentUserId: _currentUserId,
            );
            _messageController.add(msg);
          }
        }
      } catch (_) {}
    });

    // 2. Operator yazır: OperatorTyping(conversationId, operatorUserId, isTyping)
    _hubConnection?.on('OperatorTyping', (List<dynamic>? args) {
      _handleTypingEvent(
        args,
        eventName: 'OperatorTyping',
        isExplicitOperatorEvent: true,
      );
    });

    // Ehtiyat olaraq UserTyping də dinlənilir
    _hubConnection?.on('UserTyping', (List<dynamic>? args) {
      _handleTypingEvent(
        args,
        eventName: 'UserTyping',
        isExplicitOperatorEvent: false,
      );
    });

    // 3. Mesajlar oxundu: MessagesSeen(conversationId, messageIds, seenAt)
    _hubConnection?.on('MessagesSeen', (List<dynamic>? args) {
      try {
        List<String> msgIds = [];
        String? convId;
        DateTime? seenAt;

        DateTime? parseSeenAt(dynamic raw) {
          if (raw == null) return null;
          if (raw is DateTime) return raw;
          final str = raw.toString().trim();
          if (str.isEmpty) return null;
          return DateTime.tryParse(str);
        }

        List<String> extractIds(dynamic rawList) {
          if (rawList is String && rawList.trim().isNotEmpty) {
            return rawList
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
          }
          if (rawList is Iterable) {
            return rawList
                .map((e) {
                  if (e is Map) {
                    return (e['id'] ?? e['messageId'])?.toString().trim() ?? '';
                  }
                  return e?.toString().trim() ?? '';
                })
                .where((e) => e.isNotEmpty)
                .toList();
          }
          return [];
        }

        if (args != null && args.isNotEmpty) {
          if (args[0] is Map) {
            final map = args[0] as Map;
            convId = map['conversationId']?.toString();
            msgIds = extractIds(
              map['messageIds'] ??
                  map['ids'] ??
                  map['seenMessageIds'] ??
                  map['readMessageIds'] ??
                  map['messages'] ??
                  map['messageId'],
            );
            seenAt = parseSeenAt(map['seenAt'] ?? map['readAt']);
          } else if (args[0] is Iterable) {
            msgIds = extractIds(args[0]);
            if (args.length >= 2) {
              seenAt = parseSeenAt(args[1]);
            }
          } else {
            // Backend standart: (conversationId, messageIds, seenAt),
            // (conversationId, customerUserId, messageIds, seenAt) və ya (convId, map)
            convId = args[0]?.toString();
            for (int i = 1; i < args.length; i++) {
              final arg = args[i];
              if (arg is Map) {
                convId ??= arg['conversationId']?.toString();
                if (msgIds.isEmpty) {
                  msgIds = extractIds(
                    arg['messageIds'] ??
                        arg['ids'] ??
                        arg['seenMessageIds'] ??
                        arg['readMessageIds'] ??
                        arg['messages'] ??
                        arg['messageId'],
                  );
                }
                seenAt ??= parseSeenAt(arg['seenAt'] ?? arg['readAt']);
              } else if (arg is Iterable) {
                if (msgIds.isEmpty) {
                  msgIds = extractIds(arg);
                }
              } else if (arg != null && msgIds.isNotEmpty) {
                seenAt ??= parseSeenAt(arg);
              }
            }
            if (seenAt == null && args.length >= 2) {
              seenAt = parseSeenAt(args.last);
            }
          }
        }

        final resolvedConvId =
            (convId != null && convId.trim().isNotEmpty)
            ? convId.trim()
            : _activeConversationId;

        final effectiveSeenAt = seenAt ?? DateTime.now();
        for (final id in msgIds) {
          globalSeenTimestamps[id.toLowerCase()] = effectiveSeenAt;
        }

        _seenController.add(
          MessagesSeenEvent(
            conversationId: resolvedConvId,
            messageIds: msgIds,
            seenAt: effectiveSeenAt,
            hasExplicitSeenAt: seenAt != null,
          ),
        );
      } catch (_) {}
    });

    // 4. Söhbət Statusu Dəyişdi: ConversationStatusChanged(conversationId, status, statusName)
    _hubConnection?.on('ConversationStatusChanged', (List<dynamic>? args) {
      try {
        String status = '';
        String? statusName;
        String? convId;

        if (args != null && args.isNotEmpty) {
          if (args.length >= 2 && args[0] is! Map) {
            convId = args[0]?.toString();
            status = args[1]?.toString() ?? '';
            if (args.length >= 3) {
              final rawName = args[2]?.toString().trim();
              if (rawName != null && rawName.isNotEmpty) {
                statusName = rawName;
              }
            }
          } else if (args[0] is Map) {
            final map = args[0] as Map;
            convId = map['conversationId']?.toString();
            status =
                map['status']?.toString() ??
                map['statusName']?.toString() ??
                '';
            final rawName = map['statusName']?.toString().trim();
            if (rawName != null && rawName.isNotEmpty) {
              statusName = rawName;
            }
          } else {
            status = args[0]?.toString() ?? '';
          }
        }

        _statusController.add(
          ConversationStatusEvent(
            conversationId: convId ?? _activeConversationId,
            status: status,
            statusName: statusName,
          ),
        );
      } catch (_) {}
    });
  }

  /// 1. Söhbət otağına daxil olmaq (JoinConversation)
  Future<void> joinConversation(String conversationId) async {
    _activeConversationId = conversationId;
    if (!isConnected) {
      final ok = await initAndConnect();
      if (!ok) return;
    }
    try {
      await _hubConnection?.invoke('JoinConversation', args: [conversationId]);
    } catch (_) {}
  }

  /// 2. Söhbət otağından çıxmaq (LeaveConversation)
  Future<void> leaveConversation(String conversationId) async {
    try {
      if (isConnected) {
        await _hubConnection?.invoke(
          'LeaveConversation',
          args: [conversationId],
        );
      }
    } catch (_) {
    } finally {
      if (_activeConversationId == conversationId) {
        _activeConversationId = null;
      }
    }
  }

  /// 3. Müştərinin yazma statusu (SendTyping)
  Future<void> sendTyping(String conversationId, bool isTyping) async {
    if (!isConnected) return;
    try {
      _lastSentTypingConvId = conversationId;
      _lastSentTypingValue = isTyping;
      _lastSentTypingAt = DateTime.now();

      await _hubConnection?.invoke(
        'SendTyping',
        args: [conversationId, isTyping],
      );
    } catch (_) {}
  }

  /// 4. REST ilə yaradılmış mesajı SignalR üzərindən operatorlara/otağa yaymaq
  /// Hub metodu: BroadcastMessage(conversationId, customerUserId, message)
  Future<bool> broadcastMessage({
    required String conversationId,
    String? customerUserId,
    required Map<String, dynamic> messagePayload,
  }) async {
    if (!isConnected) {
      final ok = await initAndConnect();
      if (!ok || !isConnected) return false;
    }

    final convId = (messagePayload['conversationId'] ?? conversationId)
        .toString()
        .trim();
    if (convId.isEmpty) return false;

    final custId = _resolveUserId(
      (customerUserId ??
              messagePayload['customerUserId'] ??
              messagePayload['userId'] ??
              messagePayload['senderUserId'])
          ?.toString(),
    );

    final payload = Map<String, dynamic>.from(messagePayload);
    if ((payload['id'] == null || payload['id'].toString().trim().isEmpty) &&
        payload['messageId'] != null) {
      payload['id'] = payload['messageId'].toString();
    } else if (payload['id'] != null) {
      payload['id'] = payload['id'].toString();
    }
    payload['conversationId'] =
        (payload['conversationId']?.toString().trim().isNotEmpty ?? false)
        ? payload['conversationId'].toString().trim()
        : convId;
    if (custId.isNotEmpty &&
        (payload['customerUserId'] == null ||
            payload['customerUserId'].toString().trim().isEmpty)) {
      payload['customerUserId'] = custId;
    }
    if (payload['createdDate'] is DateTime) {
      payload['createdDate'] = (payload['createdDate'] as DateTime)
          .toUtc()
          .toIso8601String();
    } else if (payload['createdDate'] == null ||
        payload['createdDate'].toString().trim().isEmpty) {
      payload['createdDate'] =
          (payload['createdAt'] ?? payload['sentAt'])?.toString() ??
          DateTime.now().toUtc().toIso8601String();
    } else {
      payload['createdDate'] = payload['createdDate'].toString();
    }

    try {
      await _hubConnection?.invoke(
        'BroadcastMessage',
        args: <Object>[convId, custId, payload],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 5. Mesajlar oxundu edildikdən sonra SignalR üzərindən qarşı tərəfə yaymaq
  /// Hub metodu: BroadcastMessagesSeen(conversationId, customerUserId, messageIds, seenAt)
  Future<bool> broadcastMessagesSeen({
    required String conversationId,
    String? customerUserId,
    required List<dynamic> messageIds,
    dynamic seenAt,
  }) async {
    final normalizedIds = messageIds
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    if (normalizedIds.isEmpty) return false;

    if (!isConnected) {
      final ok = await initAndConnect();
      if (!ok || !isConnected) return false;
    }

    final convId = conversationId.trim();
    if (convId.isEmpty) return false;

    final custId = _resolveUserId(customerUserId);

    final Object seenAtArg;
    if (seenAt is DateTime) {
      seenAtArg = seenAt.toUtc().toIso8601String();
    } else if (seenAt != null &&
        seenAt.toString().trim().isNotEmpty &&
        seenAt.toString().trim().toLowerCase() != 'null') {
      seenAtArg = seenAt.toString().trim();
    } else {
      seenAtArg = DateTime.now().toUtc().toIso8601String();
    }

    try {
      await _hubConnection?.invoke(
        'BroadcastMessagesSeen',
        args: <Object>[convId, custId, normalizedIds, seenAtArg],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 6. Yeni söhbət yaradıldıqdan sonra operatorlara SignalR ilə xəbər vermək
  /// Hub metodu: BroadcastConversationCreated(conversationId, userId, topicId, subject)
  Future<bool> broadcastConversationCreated({
    required String conversationId,
    String? userId,
    required String topicId,
    required String subject,
  }) async {
    if (!isConnected) {
      final ok = await initAndConnect();
      if (!ok || !isConnected) return false;
    }

    final convId = conversationId.trim();
    if (convId.isEmpty) return false;

    final effectiveUserId = _resolveUserId(userId);
    final effectiveTopicId = topicId.trim();
    final effectiveSubject = subject.trim().isNotEmpty
        ? subject.trim()
        : 'Dəstək müraciəti';

    try {
      await _hubConnection?.invoke(
        'BroadcastConversationCreated',
        args: <Object>[
          convId,
          effectiveUserId,
          effectiveTopicId,
          effectiveSubject,
        ],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 7. Söhbət bağlandıqda və ya statusu dəyişdikdə SignalR üzərindən yaymaq
  /// Hub metodu: BroadcastStatusChanged(conversationId, status, customerUserId)
  Future<bool> broadcastStatusChanged({
    required String conversationId,
    required int status,
    String? customerUserId,
  }) async {
    if (!isConnected) {
      final ok = await initAndConnect();
      if (!ok || !isConnected) return false;
    }

    final convId = conversationId.trim();
    if (convId.isEmpty) return false;

    final custId = _resolveUserId(customerUserId);

    try {
      await _hubConnection?.invoke(
        'BroadcastStatusChanged',
        args: <Object>[convId, status, custId],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Ekrandan çıxarkən əvvəl typing=false göndərib, sonra otaqdan çıxmaq
  Future<void> stopTypingAndLeave(
    String conversationId, {
    bool wasTyping = false,
  }) async {
    if (wasTyping) {
      await sendTyping(conversationId, false);
    }
    await leaveConversation(conversationId);
  }

  /// Əlaqəni kəsmək
  Future<void> stop() async {
    try {
      if (_activeConversationId != null) {
        await leaveConversation(_activeConversationId!);
      }
      await _hubConnection?.stop();
    } catch (_) {
    } finally {
      _hubConnection = null;
      _activeConversationId = null;
      _currentUserId = null;
      _recentReceivedMsgIds.clear();
      globalSeenTimestamps.clear();
    }
  }
}
