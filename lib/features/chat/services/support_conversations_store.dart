import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:loyallig_flutter/core/network/api_client.dart';
import 'package:loyallig_flutter/core/network/token_storage.dart';
import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';
import 'package:loyallig_flutter/features/chat/models/support_conversation.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_hub_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_service.dart';
import 'package:signalr_netcore/signalr_client.dart';

/// Tətbiqin qlobal (root) səviyyəsində dəstək söhbətlərini və SignalR
/// `ReceiveMessage` / `ConversationStatusChanged` eventlərini canlı dinləyən store.
class SupportConversationsStore extends ChangeNotifier {
  SupportConversationsStore._internal() {
    _attachGlobalListeners();
  }

  static final SupportConversationsStore instance =
      SupportConversationsStore._internal();

  final SupportChatService _chatService = SupportChatService();
  final SupportChatHubService _hubService = SupportChatHubService.instance;

  List<SupportConversation> _conversations = [];
  bool _isRefreshing = false;
  bool _hasLoadedOnce = false;

  List<SupportConversation> get conversations =>
      List<SupportConversation>.unmodifiable(_conversations);

  List<SupportConversation> get activeConversations =>
      _conversations.where((c) => c.isOpen).toList();

  bool get hasLoadedOnce => _hasLoadedOnce;

  int get totalUnreadCount => _conversations
      .where((c) => c.isOpen)
      .fold<int>(0, (sum, c) => sum + c.unreadMessagesCount);

  bool get hasUnreadMessages => totalUnreadCount > 0;

  void _attachGlobalListeners() {
    // 1. Qlobal ReceiveMessage dinləyicisi (user_{userId} otağı daxil olmaqla)
    _hubService.onMessageReceived.listen(_handleIncomingMessage);

    // 2. Qlobal status dəyişikliyi dinləyicisi
    _hubService.onStatusChanged.listen(_handleStatusChanged);

    // 3. Reconnect zamanı siyahını avtomatik sinxronlaşdırırıq
    _hubService.onConnectionStateChanged.listen((state) {
      if (state == HubConnectionState.Connected && _hasLoadedOnce) {
        unawaited(refreshConversations(silent: true));
      }
    });
  }

  /// İstifadəçi giriş etdikdə və ya tətbiq açıldıqda root səviyyədə çağırılır:
  /// SignalR Hub-a qoşulur (backend user_{userId} otağına salır) və siyahını yükləyir.
  Future<void> initGlobalSession() async {
    final hasTokenInMemory =
        ApiClient.instance.accessToken != null &&
        ApiClient.instance.accessToken!.trim().isNotEmpty;
    final hasSession = hasTokenInMemory || await TokenStorage.hasValidSession();
    if (!hasSession) return;

    unawaited(_hubService.initAndConnect());
    await refreshConversations(silent: true);
  }

  /// Tətbiq arxa plandan ön plana qayıtdıqda (resumed) çağırılır.
  Future<void> onAppResumed() async {
    final hasSession = await TokenStorage.hasValidSession();
    if (!hasSession) return;

    if (!_hubService.isConnected) {
      unawaited(_hubService.initAndConnect());
    }
    unawaited(refreshConversations(silent: true));
  }

  /// `/api/SupportConversations/my` siyahısını yeniləyir.
  Future<List<SupportConversation>> refreshConversations({
    bool silent = false,
  }) async {
    if (_isRefreshing) return _conversations;
    _isRefreshing = true;

    try {
      final fetched = await _chatService.getMyConversations();
      final activeConvId = _hubService.activeConversationId
          ?.trim()
          .toLowerCase();

      _conversations = fetched.map((conv) {
        // Əgər istifadəçi hazırda bu çatın içindədirsə, oxunmamış sayını 0 saxlayırıq
        if (activeConvId != null &&
            conv.id.trim().toLowerCase() == activeConvId &&
            conv.unreadMessagesCount > 0) {
          return conv.copyWith(unreadMessagesCount: 0);
        }
        return conv;
      }).toList();

      _hasLoadedOnce = true;
      notifyListeners();
      return _conversations;
    } catch (_) {
      if (!silent) rethrow;
      return _conversations;
    } finally {
      _isRefreshing = false;
    }
  }

  void _handleIncomingMessage(SupportChatMessage msg) {
    final convId = msg.conversationId?.trim();

    if (convId == null || convId.isEmpty) {
      unawaited(refreshConversations(silent: true));
      return;
    }

    final normConvId = convId.toLowerCase();
    final activeConvId = _hubService.activeConversationId?.trim().toLowerCase();
    final isViewingThisChat =
        activeConvId != null && activeConvId == normConvId;

    final preview = msg.content.trim().isNotEmpty
        ? msg.content.trim()
        : ((msg.attachmentFileId != null || msg.attachmentUrl != null)
              ? '📷 Şəkil'
              : '');
    final msgTime = msg.createdDate ?? DateTime.now();

    final idx = _conversations.indexWhere(
      (c) => c.id.trim().toLowerCase() == normConvId,
    );

    if (idx != -1) {
      final existing = _conversations[idx];
      final nextUnread = isViewingThisChat
          ? 0
          : (!msg.isUser
                ? existing.unreadMessagesCount + 1
                : existing.unreadMessagesCount);

      final updated = existing.copyWith(
        lastMessage: preview.isNotEmpty ? preview : existing.lastMessage,
        lastMessageDate: msgTime,
        updatedDate: msgTime,
        unreadMessagesCount: nextUnread,
        // Əgər operator bağlı söhbəti yenidən açıb mesaj yazıbsa dərhal aktiv göstəririk
        status: (!msg.isUser && existing.isClosed) ? 'Open' : existing.status,
        statusName: (!msg.isUser && existing.isClosed)
            ? 'Aktiv'
            : existing.statusName,
      );

      final updatedList = List<SupportConversation>.from(_conversations);
      updatedList.removeAt(idx);
      updatedList.insert(0, updated);
      _conversations = updatedList;
      notifyListeners();
    } else {
      // Siyahıda hələ olmayan yeni müraciətdirsə dərhal API-dən çəkirik
      unawaited(refreshConversations(silent: true));
    }
  }

  void _handleStatusChanged(ConversationStatusEvent event) {
    final convId = event.conversationId?.trim();
    if (convId == null || convId.isEmpty) {
      unawaited(refreshConversations(silent: true));
      return;
    }

    final normConvId = convId.toLowerCase();
    final idx = _conversations.indexWhere(
      (c) => c.id.trim().toLowerCase() == normConvId,
    );

    if (idx != -1) {
      final isClosedStatus = SupportConversation.isClosedStatus(
        event.status,
        event.statusName,
      );
      final resolvedStatusName =
          (event.statusName != null && event.statusName!.trim().isNotEmpty)
          ? event.statusName!.trim()
          : (isClosedStatus ? 'Bağlanıb' : event.status);

      final updatedList = List<SupportConversation>.from(_conversations);
      updatedList[idx] = updatedList[idx].copyWith(
        status: event.status,
        statusName: resolvedStatusName,
        unreadMessagesCount: isClosedStatus
            ? 0
            : updatedList[idx].unreadMessagesCount,
      );
      _conversations = updatedList;
      notifyListeners();
    } else {
      unawaited(refreshConversations(silent: true));
    }
  }

  /// İstifadəçi çata klikləyib daxil olduqda lokal olaraq dərhal 0 edir.
  void markConversationRead(String conversationId) {
    final normId = conversationId.trim().toLowerCase();
    final idx = _conversations.indexWhere(
      (c) => c.id.trim().toLowerCase() == normId,
    );
    if (idx != -1 && _conversations[idx].unreadMessagesCount > 0) {
      final updatedList = List<SupportConversation>.from(_conversations);
      updatedList[idx] = updatedList[idx].copyWith(unreadMessagesCount: 0);
      _conversations = updatedList;
      notifyListeners();
    }
  }

  /// Müştəri özü mesaj göndərdikdə son mesaj və tarixi dərhal yeniləyir.
  void updateConversationPreview(
    String conversationId, {
    required String lastMessage,
    DateTime? date,
  }) {
    final normId = conversationId.trim().toLowerCase();
    final idx = _conversations.indexWhere(
      (c) => c.id.trim().toLowerCase() == normId,
    );
    if (idx != -1) {
      final ts = date ?? DateTime.now();
      final updated = _conversations[idx].copyWith(
        lastMessage: lastMessage,
        lastMessageDate: ts,
        updatedDate: ts,
        unreadMessagesCount: 0,
      );
      final updatedList = List<SupportConversation>.from(_conversations);
      updatedList.removeAt(idx);
      updatedList.insert(0, updated);
      _conversations = updatedList;
      notifyListeners();
    }
  }

  /// Yeni söhbət yaradıldıqda və ya yeniləndikdə siyahıya əlavə edir.
  void upsertConversation(SupportConversation conv) {
    final normId = conv.id.trim().toLowerCase();
    final updatedList = List<SupportConversation>.from(_conversations);
    final idx = updatedList.indexWhere(
      (c) => c.id.trim().toLowerCase() == normId,
    );
    if (idx != -1) {
      updatedList.removeAt(idx);
    }
    updatedList.insert(0, conv);
    _conversations = updatedList;
    notifyListeners();
  }

  /// Müştəri söhbəti bağladıqda lokal siyahıda dərhal statusu bağlayır.
  void markConversationClosed(String conversationId) {
    final normId = conversationId.trim().toLowerCase();
    final idx = _conversations.indexWhere(
      (c) => c.id.trim().toLowerCase() == normId,
    );
    if (idx != -1) {
      final updatedList = List<SupportConversation>.from(_conversations);
      updatedList[idx] = updatedList[idx].copyWith(
        status: '5',
        statusName: 'Bağlanıb',
        unreadMessagesCount: 0,
      );
      _conversations = updatedList;
      notifyListeners();
    }
  }

  /// Çıxış (logout) zamanı təmizlənir.
  void clear() {
    _conversations = [];
    _hasLoadedOnce = false;
    notifyListeners();
  }
}
