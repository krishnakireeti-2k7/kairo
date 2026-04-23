import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/features/chat/data/services/chat_service.dart';
import 'package:kairo/features/chat/domain/models/chat_message.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<ChatState> {
  int _messageCounter = 0;

  @override
  ChatState build() {
    return const ChatState();
  }

  Future<void> sendMessage(String rawMessage) async {
    final message = rawMessage.trim();
    if (message.isEmpty || state.isSending) {
      return;
    }

    final userMessage = ChatMessage(
      id: _nextMessageId(),
      role: 'user',
      content: message,
      timestamp: DateTime.now(),
    );

    final pendingMessages = [...state.messages, userMessage];
    state = state.copyWith(
      messages: pendingMessages,
      isSending: true,
      errorMessage: null,
    );

    try {
      final reply = await ref.read(chatServiceProvider).sendMessage(
        message: message,
        history: pendingMessages,
      );

      final assistantMessage = ChatMessage(
        id: _nextMessageId(),
        role: 'assistant',
        content: reply,
        timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...pendingMessages, assistantMessage],
        isSending: false,
        errorMessage: null,
      );
    } catch (error) {
      state = state.copyWith(
        isSending: false,
        errorMessage: error.toString(),
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(errorMessage: null);
  }

  String _nextMessageId() {
    _messageCounter += 1;
    return 'chat-${DateTime.now().microsecondsSinceEpoch}-$_messageCounter';
  }
}

class ChatState {
  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;

  const ChatState({
    this.messages = const <ChatMessage>[],
    this.isSending = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    Object? errorMessage = _sentinel,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _sentinel = Object();
