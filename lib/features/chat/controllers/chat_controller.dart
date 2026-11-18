import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:loyallig_flutter/core/localization/app_localizations.dart';
import 'package:loyallig_flutter/core/network/network_monitor.dart';
import 'package:loyallig_flutter/core/services/biometric_service.dart';
import 'package:loyallig_flutter/core/services/file_service.dart';
import 'package:loyallig_flutter/features/chat/models/support_chat_message.dart';
import 'package:loyallig_flutter/features/chat/models/support_conversation.dart';
import 'package:loyallig_flutter/features/chat/models/support_topic.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_hub_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_chat_service.dart';
import 'package:loyallig_flutter/features/chat/services/support_conversations_store.dart';
import 'package:signalr_netcore/signalr_client.dart';

class ChatController extends ChangeNotifier {
  static const int maxMessageLength = 4000;

  final SupportChatService _chatService = SupportChatService();
  final SupportChatHubService _hubService = SupportChatHubService.instance;
  final SupportConversationsStore _conversationsStore =
      SupportConversationsStore.instance;
  final FileService fileService = FileService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController scrollController = ScrollController();

  final SupportTopic? topic;
  String? conversationId;
  SupportConversation? conversation;

  List<SupportChatMessage> messages = [];
  bool isLoadingHistory = false;
  bool isSending = false;
  bool isUploadingAttachment = false;
  bool isOperatorTyping = false;
  bool isClosed = false;
  HubConnectionState connectionState = HubConnectionState.Disconnected;

  Timer? _userTypingDebounce;
  Timer? _operatorTypingTimeout;
  Timer? _greetingTypingTimer;
  bool _isUserTyping = false;
  DateTime? _lastTypingTrueSentAt;
  bool _showGreetingMessage = false;
  bool _isDisposed = false;

  // MessagesSeen siqnalı REST cavabından əvvəl gələrsə oxundu tarixini itirməmək üçün keş
  final Map<String, DateTime> _seenMessageTimestamps = {};

  StreamSubscription<SupportChatMessage>? _msgSub;
  StreamSubscription<OperatorTypingEvent>? _typingSub;
  StreamSubscription<MessagesSeenEvent>? _seenSub;
  StreamSubscription<ConversationStatusEvent>? _statusSub;
  StreamSubscription<HubConnectionState>? _connSub;

  void Function(String message, {bool isError})? onShowNotification;

  ChatController({this.conversationId, this.topic, this.conversation}) {
    isClosed = conversation?.isClosed ?? false;
    connectionState = _hubService.state;
  }

  String? get topicName =>
      topic?.name ?? conversation?.topicName ?? conversation?.title;

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  SupportChatMessage _applySeenState(
    SupportChatMessage msg, {
    SupportChatMessage? existing,
  }) {
    final normId = msg.id.trim().toLowerCase();
    final cachedSeenAt =
        _seenMessageTimestamps[normId] ??
        _hubService.globalSeenTimestamps[normId];
    final effectiveSeenAt = msg.seenAt ?? existing?.seenAt ?? cachedSeenAt;
    final effectiveIsRead =
        msg.isSeen || (existing?.isSeen ?? false) || cachedSeenAt != null;

    if (effectiveSeenAt != msg.seenAt || effectiveIsRead != msg.isRead) {
      return msg.copyWith(
        isRead: effectiveIsRead,
        seenAt: effectiveSeenAt,
      );
    }
    return msg;
  }

  void init() {
    connectionState = _hubService.state;
    _initSignalRSubscriptions();
    NetworkMonitor.instance.reconnectNotifier.addListener(_onReconnected);

    if (conversationId != null && conversationId!.trim().isNotEmpty) {
      _showGreetingMessage = true;
      _conversationsStore.markConversationRead(conversationId!);
      _loadHistoryAndConnect();
    } else {
      _showGreetingMessage = false;
      _hubService.initAndConnect();
    }
  }

  void _onReconnected() {
    if (_isDisposed) return;
    if (conversationId != null && conversationId!.trim().isNotEmpty) {
      unawaited(_loadHistoryAndConnect());
    } else {
      unawaited(_hubService.initAndConnect());
    }
  }

  void _triggerAutoGreetingWithTyping() {
    if (_showGreetingMessage || _greetingTypingTimer != null || _isDisposed) {
      return;
    }
    isOperatorTyping = true;
    _safeNotify();
    scrollToBottom();

    _greetingTypingTimer = Timer(const Duration(milliseconds: 1800), () {
      _greetingTypingTimer = null;
      if (_isDisposed) return;
      _showGreetingMessage = true;
      isOperatorTyping = false;
      messages = _insertGreetingAfterFirstMessage(messages);
      _safeNotify();
      scrollToBottom();
    });
  }

  SupportChatMessage _buildGreetingMessage({DateTime? createdDate}) {
    final tName = topicName;
    final greetingText = tName != null && tName.isNotEmpty
        ? tr('chat_auto_greeting_with_topic', {'topic': tName})
        : tr('chat_auto_greeting');

    return SupportChatMessage(
      id: 'greeting_msg',
      content: greetingText,
      isUser: false,
      sender: 'Operator',
      createdDate: createdDate ?? conversation?.createdDate ?? DateTime.now(),
    );
  }

  List<SupportChatMessage> _insertGreetingAfterFirstMessage(
    List<SupportChatMessage> list,
  ) {
    final withoutGreeting = list.where((m) => m.id != 'greeting_msg').toList();
    if (withoutGreeting.isEmpty || !_showGreetingMessage) {
      return withoutGreeting;
    }

    final firstMsg = withoutGreeting.first;
    final greeting = _buildGreetingMessage(
      createdDate: firstMsg.createdDate ?? conversation?.createdDate,
    );
    return [firstMsg, greeting, ...withoutGreeting.skip(1)];
  }

  void _initSignalRSubscriptions() {
    _msgSub = _hubService.onMessageReceived.listen((msg) {
      if (_isDisposed) return;

      final hasActiveConvId =
          conversationId != null && conversationId!.trim().isNotEmpty;
      final incomingConvId = msg.conversationId?.trim();

      if (!hasActiveConvId) {
        if (isSending &&
            incomingConvId != null &&
            incomingConvId.isNotEmpty) {
          conversationId = incomingConvId;
          unawaited(_hubService.joinConversation(incomingConvId));
        } else {
          return;
        }
      } else if (incomingConvId != null &&
          incomingConvId.isNotEmpty &&
          incomingConvId.toLowerCase() !=
              conversationId!.trim().toLowerCase()) {
        return;
      }

      final existingIdx = messages.indexWhere((m) {
        if (m.id == msg.id) return true;
        if (m.id.startsWith('temp_') &&
            !m.hasFailed &&
            m.isUser == msg.isUser) {
          final sameAttachment =
              msg.attachmentFileId != null &&
              msg.attachmentFileId!.isNotEmpty &&
              m.attachmentFileId == msg.attachmentFileId;
          final sameContent = m.content == msg.content;
          return sameAttachment || sameContent;
        }
        return false;
      });

      if (existingIdx != -1) {
        messages[existingIdx] = _applySeenState(
          msg,
          existing: messages[existingIdx],
        );
      } else {
        messages.add(_applySeenState(msg));
      }
      messages = _insertGreetingAfterFirstMessage(messages);

      // Qarşı tərəfdən yeni mesaj gələn kimi "yazır..." statusunu dərhal silirik
      if (!msg.isUser) {
        isOperatorTyping = false;
        _operatorTypingTimeout?.cancel();
      }

      _safeNotify();
      scrollToBottom();

      if (!msg.isUser && conversationId != null) {
        _markIncomingMessageSeen();
      }
    });

    _typingSub = _hubService.onOperatorTyping.listen((event) {
      if (_isDisposed || conversationId == null) return;
      if (event.conversationId != null &&
          event.conversationId!.trim().toLowerCase() !=
              conversationId!.trim().toLowerCase()) {
        debugPrint(
          '⚠️ [CHAT UI] OperatorTyping başqa söhbət üçündür: '
          'eventConvId=${event.conversationId}, activeConvId=$conversationId',
        );
        return;
      }

      debugPrint(
        '💬 [CHAT UI] Operator yazır yeniləndi: '
        'isTyping=${event.isTyping}, operatorId=${event.operatorUserId}, convId=${event.conversationId}',
      );

      if (event.isTyping) {
        isOperatorTyping = true;
        _operatorTypingTimeout?.cancel();
        // Ehtiyat fallback taymer: false gecikərsə və ya bağlantı kəsilərsə avtomatik gizlədilir
        _operatorTypingTimeout = Timer(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          isOperatorTyping = false;
          _safeNotify();
        });
        scrollToBottom();
      } else {
        isOperatorTyping = false;
        _operatorTypingTimeout?.cancel();
      }
      _safeNotify();
    });

    _seenSub = _hubService.onMessagesSeen.listen((event) {
      if (_isDisposed || conversationId == null) return;
      if (event.conversationId != null &&
          event.conversationId!.trim().toLowerCase() !=
              conversationId!.trim().toLowerCase()) {
        return;
      }
      if (event.messageIds.isEmpty) return;

      final effectiveSeenAt = event.seenAt ?? DateTime.now();
      final seenSet = event.messageIds
          .map((id) => id.trim().toLowerCase())
          .where((id) => id.isNotEmpty)
          .toSet();
      if (seenSet.isEmpty) return;

      for (final normId in seenSet) {
        _seenMessageTimestamps[normId] = effectiveSeenAt;
      }

      bool updated = false;
      for (int i = 0; i < messages.length; i++) {
        final m = messages[i];
        final isMatchedId = seenSet.contains(m.id.trim().toLowerCase());
        final isSentTempUserMsg =
            m.isUser &&
            !m.isSending &&
            !m.hasFailed &&
            m.id.startsWith('temp_');

        if (isMatchedId || isSentTempUserMsg) {
          if (!m.isSeen || m.seenAt == null) {
            messages[i] = m.copyWith(
              isRead: true,
              seenAt: m.seenAt ?? effectiveSeenAt,
            );
            updated = true;
          }
        }
      }
      if (updated) {
        _safeNotify();
      }
    });

    _statusSub = _hubService.onStatusChanged.listen((event) {
      if (_isDisposed || conversationId == null) return;
      if (event.conversationId != null &&
          event.conversationId!.trim().toLowerCase() !=
              conversationId!.trim().toLowerCase()) {
        return;
      }

      final wasClosed = isClosed;
      final s = event.status.toLowerCase();
      isClosed =
          s == '4' ||
          s == '5' ||
          s.contains('close') ||
          s.contains('bağ') ||
          s.contains('resolved') ||
          s.contains('solved') ||
          s.contains('həll');
      if (isClosed) {
        isOperatorTyping = false;
        _operatorTypingTimeout?.cancel();
        stopUserTyping();
      }
      _safeNotify();

      if (isClosed && !wasClosed) {
        onShowNotification?.call(tr('chat_closed_by_operator'));
      }
    });

    _connSub = _hubService.onConnectionStateChanged.listen((state) {
      if (_isDisposed) return;
      connectionState = state;
      _safeNotify();
    });
  }

  void stopUserTyping() {
    _userTypingDebounce?.cancel();
    _userTypingDebounce = null;
    if (_isUserTyping) {
      _isUserTyping = false;
      _lastTypingTrueSentAt = null;
      if (conversationId != null) {
        _hubService.sendTyping(conversationId!, false);
      }
    }
  }

  void onTextChanged(String text) {
    if (conversationId == null || isClosed) return;
    if (text.trim().isNotEmpty) {
      final now = DateTime.now();
      // İstifadəçi yazmağa davam etdikcə hər 1.8 - 2 saniyədən bir true siqnalı yenilənir
      if (!_isUserTyping ||
          _lastTypingTrueSentAt == null ||
          now.difference(_lastTypingTrueSentAt!) >=
              const Duration(milliseconds: 1800)) {
        _isUserTyping = true;
        _lastTypingTrueSentAt = now;
        _hubService.sendTyping(conversationId!, true);
      }

      // 2 - 2.5 saniyə klaviaturaya toxunmadıqda false göndərilir
      _userTypingDebounce?.cancel();
      _userTypingDebounce = Timer(const Duration(milliseconds: 2200), () {
        if (!_isDisposed) {
          stopUserTyping();
        }
      });
    } else {
      stopUserTyping();
    }
  }

  Future<void> _loadHistoryAndConnect() async {
    if (conversationId == null) return;
    await _hubService.joinConversation(conversationId!);
    await loadHistory();
  }

  Future<void> loadHistory() async {
    if (conversationId == null || _isDisposed) return;

    isLoadingHistory = true;
    _safeNotify();

    try {
      final conv = await _chatService.getConversationDetails(conversationId!);
      if (_isDisposed) return;

      conversation = conv.unreadMessagesCount > 0
          ? conv.copyWith(unreadMessagesCount: 0)
          : conv;
      isClosed = conv.isClosed;
      isLoadingHistory = false;

      final mergedMessages = conv.messages
          .map((m) => _applySeenState(m))
          .toList();
      for (final current in messages.where((m) => m.id != 'greeting_msg')) {
        var index = mergedMessages.indexWhere(
          (m) => m.id.trim().toLowerCase() == current.id.trim().toLowerCase(),
        );
        var matchedTemporaryMessage = false;
        if (index == -1 && current.id.startsWith('temp_')) {
          index = mergedMessages.indexWhere((m) {
            final sameAttachment =
                current.attachmentFileId != null &&
                current.attachmentFileId!.isNotEmpty &&
                m.attachmentFileId == current.attachmentFileId;
            return m.isUser == current.isUser &&
                (sameAttachment || m.content == current.content);
          });
          matchedTemporaryMessage = index != -1;
        }
        if (index == -1) {
          mergedMessages.add(_applySeenState(current));
        } else if (!matchedTemporaryMessage &&
            (current.isSending || current.hasFailed)) {
          mergedMessages[index] = _applySeenState(
            current,
            existing: mergedMessages[index],
          );
        } else {
          mergedMessages[index] = _applySeenState(
            mergedMessages[index],
            existing: current,
          );
        }
      }
      mergedMessages.sort((a, b) {
        final aDate = a.createdDate;
        final bDate = b.createdDate;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return -1;
        if (bDate == null) return 1;
        return aDate.compareTo(bDate);
      });
      messages = _insertGreetingAfterFirstMessage(mergedMessages);
      _safeNotify();
      scrollToBottom();

      // Çat pəncərəsi açılanda dərhal qarşı tərəfin mesajlarını "oxundu" edirik (body: {})
      _conversationsStore.markConversationRead(conversationId!);
      unawaited(_chatService.markMessagesSeen(conversationId!));
    } catch (e) {
      debugPrint('❌ [CHAT] Tarixçə yüklənərkən xəta: $e');
      isLoadingHistory = false;
      _safeNotify();
    }
  }

  void _markIncomingMessageSeen() {
    if (conversationId == null || _isDisposed) return;
    _conversationsStore.markConversationRead(conversationId!);
    unawaited(_chatService.markMessagesSeen(conversationId!));
  }

  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty || isSending || isUploadingAttachment || isClosed) {
      return;
    }
    if (cleanText.length > maxMessageLength) {
      onShowNotification?.call(
        tr('chat_max_length_error', {'max': '$maxMessageLength'}),
      );
      return;
    }

    stopUserTyping();

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final localMessage = SupportChatMessage(
      id: tempId,
      conversationId: conversationId,
      sender: 'User',
      isUser: true,
      messageType: 'Text',
      content: cleanText,
      createdDate: DateTime.now(),
      isSending: true,
    );

    messages.add(localMessage);
    isSending = true;
    _safeNotify();
    scrollToBottom();

    try {
      bool sent = false;
      SupportChatMessage? serverMsg;

      if (conversationId == null || conversationId!.trim().isEmpty) {
        if (topic != null) {
          final conv = await _chatService.createConversation(
            supportTopicId: topic!.id,
            subject: topic!.name,
            content: cleanText,
            messageType: 'Text',
          );
          if (conv.id.trim().isNotEmpty) {
            conversationId = conv.id.trim();
          }
          conversation = conv;
          isClosed = conv.isClosed;
          if (conversationId != null && conversationId!.isNotEmpty) {
            _conversationsStore.upsertConversation(
              conv.copyWith(
                id: conversationId,
                topicName: conv.topicName ?? topic!.name,
                lastMessage: cleanText,
                lastMessageDate: DateTime.now(),
                unreadMessagesCount: 0,
              ),
            );
            if (conv.messages.isNotEmpty) {
              serverMsg = conv.messages.last.copyWith(isUser: true);
            }
            await _hubService.joinConversation(conversationId!);
            await loadHistory();
          }
          sent = true;
        } else {
          throw Exception('Mövzu seçilməyib');
        }
      } else {
        serverMsg = await _chatService.sendMessageRest(
          conversationId!,
          content: cleanText,
          messageType: 'Text',
        );
        if (serverMsg != null) {
          serverMsg = serverMsg.copyWith(isUser: true);
        }
        _conversationsStore.updateConversationPreview(
          conversationId!,
          lastMessage: cleanText,
        );
        sent = true;
      }

      if (_isDisposed) return;
      isSending = false;
      final idx = messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        final resolved =
            serverMsg ??
            messages[idx].copyWith(
              conversationId: conversationId,
              isSending: false,
              hasFailed: !sent,
            );
        messages[idx] = _applySeenState(resolved, existing: messages[idx]);
      } else if (serverMsg != null) {
        final serverIdx = messages.indexWhere(
          (m) =>
              m.id.trim().toLowerCase() == serverMsg!.id.trim().toLowerCase(),
        );
        if (serverIdx != -1) {
          messages[serverIdx] = _applySeenState(
            messages[serverIdx],
            existing: serverMsg,
          );
        }
      }
      if (sent) {
        if (!_showGreetingMessage) {
          _triggerAutoGreetingWithTyping();
        } else {
          messages = _insertGreetingAfterFirstMessage(messages);
        }
      }
      _safeNotify();
    } catch (e) {
      debugPrint('❌ [CHAT] Mesaj göndərilmə xətası: $e');
      if (_isDisposed) return;
      isSending = false;
      final idx = messages.indexWhere((m) => m.id == tempId);
      if (idx != -1) {
        messages[idx] = messages[idx].copyWith(
          isSending: false,
          hasFailed: true,
        );
      }
      _safeNotify();
      onShowNotification?.call(
        SupportChatService.extractFriendlyErrorMessage(
          e,
          fallbackKey: 'chat_send_error_short',
        ),
        isError: true,
      );
    }
  }

  Future<void> pickAndSendAttachment(ImageSource source) async {
    if (isSending || isUploadingAttachment || isClosed) return;
    stopUserTyping();

    try {
      final picked = await BiometricService.instance.runWithSuppressedLock(
        () => _picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 85,
        ),
      );

      if (picked == null || _isDisposed) return;

      isUploadingAttachment = true;
      _safeNotify();

      final res = await fileService.uploadXFile(picked);

      if (_isDisposed) return;
      isUploadingAttachment = false;
      _safeNotify();

      if (res.isSuccess && res.fileId != null) {
        final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
        final localMsg = SupportChatMessage(
          id: tempId,
          conversationId: conversationId,
          sender: 'User',
          isUser: true,
          messageType: 'Text',
          content: '📷 Şəkil',
          attachmentFileId: res.fileId,
          createdDate: DateTime.now(),
          isSending: true,
        );

        messages.add(localMsg);
        isSending = true;
        _safeNotify();
        scrollToBottom();

        bool sent = false;
        SupportChatMessage? serverMsg;

        try {
          if (conversationId == null || conversationId!.trim().isEmpty) {
            if (topic != null) {
              final conv = await _chatService.createConversation(
                supportTopicId: topic!.id,
                subject: topic!.name,
                content: '📷 Şəkil',
                messageType: 'Text',
                attachmentFileId: res.fileId,
              );
              if (conv.id.trim().isNotEmpty) {
                conversationId = conv.id.trim();
              }
              conversation = conv;
              isClosed = conv.isClosed;
              if (conversationId != null && conversationId!.isNotEmpty) {
                _conversationsStore.upsertConversation(
                  conv.copyWith(
                    id: conversationId,
                    topicName: conv.topicName ?? topic!.name,
                    lastMessage: '📷 Şəkil',
                    lastMessageDate: DateTime.now(),
                    unreadMessagesCount: 0,
                  ),
                );
                if (conv.messages.isNotEmpty) {
                  serverMsg = conv.messages.last.copyWith(isUser: true);
                }
                await _hubService.joinConversation(conversationId!);
                await loadHistory();
              }
              sent = true;
            }
          } else {
            serverMsg = await _chatService.sendMessageRest(
              conversationId!,
              content: '📷 Şəkil',
              messageType: 'Text',
              attachmentFileId: res.fileId,
            );
            if (serverMsg != null) {
              serverMsg = serverMsg.copyWith(isUser: true);
            }
            _conversationsStore.updateConversationPreview(
              conversationId!,
              lastMessage: '📷 Şəkil',
            );
            sent = true;
          }
        } catch (sendErr) {
          debugPrint('❌ [CHAT ATTACHMENT SEND ERROR]: $sendErr');
          sent = false;
        }

        if (_isDisposed) return;
        isSending = false;
        final idx = messages.indexWhere((m) => m.id == tempId);
        if (idx != -1) {
          final resolved =
              serverMsg ??
              messages[idx].copyWith(
                conversationId: conversationId,
                isSending: false,
                hasFailed: !sent,
              );
          messages[idx] = _applySeenState(resolved, existing: messages[idx]);
        } else if (serverMsg != null) {
          final serverIdx = messages.indexWhere(
            (m) =>
                m.id.trim().toLowerCase() == serverMsg!.id.trim().toLowerCase(),
          );
          if (serverIdx != -1) {
            messages[serverIdx] = _applySeenState(
              messages[serverIdx],
              existing: serverMsg,
            );
          }
        }
        if (sent) {
          if (!_showGreetingMessage) {
            _triggerAutoGreetingWithTyping();
          } else {
            messages = _insertGreetingAfterFirstMessage(messages);
          }
        }
        _safeNotify();
      } else {
        onShowNotification?.call(
          res.errorMessage != null
              ? SupportChatService.extractFriendlyErrorMessage(
                  res.errorMessage!,
                  fallbackKey: 'chat_file_upload_error',
                )
              : tr('chat_file_upload_error'),
          isError: true,
        );
      }
    } catch (e) {
      debugPrint('❌ [ATTACHMENT PICK ERROR]: $e');
      if (_isDisposed) return;
      isUploadingAttachment = false;
      isSending = false;
      _safeNotify();
      onShowNotification?.call(
        SupportChatService.extractFriendlyErrorMessage(
          e,
          fallbackKey: 'chat_file_upload_error',
        ),
        isError: true,
      );
    }
  }

  Future<void> closeConversation() async {
    if (conversationId == null) return;
    stopUserTyping();
    try {
      final didClose = await _chatService.closeConversation(conversationId!);
      if (!didClose) {
        throw Exception(tr('chat_general_error_short'));
      }
      if (_isDisposed) return;
      isClosed = true;
      _conversationsStore.markConversationClosed(conversationId!);
      _safeNotify();
      onShowNotification?.call(tr('chat_closed_success'));
    } catch (e) {
      onShowNotification?.call(
        SupportChatService.extractFriendlyErrorMessage(e),
        isError: true,
      );
    }
  }

  void scrollToBottom() {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    final wasTyping = _isUserTyping;
    _isUserTyping = false;
    _isDisposed = true;
    NetworkMonitor.instance.reconnectNotifier.removeListener(_onReconnected);
    _userTypingDebounce?.cancel();
    _operatorTypingTimeout?.cancel();
    _greetingTypingTimer?.cancel();
    _msgSub?.cancel();
    _typingSub?.cancel();
    _seenSub?.cancel();
    _statusSub?.cancel();
    _connSub?.cancel();

    if (conversationId != null) {
      _hubService.stopTypingAndLeave(conversationId!, wasTyping: wasTyping);
    }

    scrollController.dispose();
    super.dispose();
  }
}
