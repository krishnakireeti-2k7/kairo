import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kairo/core/widgets/app_bottom_navigation.dart';
import 'package:kairo/features/chat/presentation/providers/chat_provider.dart';
import 'package:kairo/features/chat/presentation/widgets/chat_bubble.dart';
import 'package:kairo/features/chat/presentation/widgets/chat_input.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final ProviderSubscription<ChatState> _chatSubscription;

  @override
  void initState() {
    super.initState();
    _chatSubscription = ref.listenManual(chatProvider, (_, next) {
      if (next.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(next.errorMessage!),
              backgroundColor: const Color(0xFF7A2F36),
            ),
          );
        ref.read(chatProvider.notifier).clearError();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  void dispose() {
    _chatSubscription.close();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;

    return Scaffold(
      backgroundColor: const Color(0xFF09131A),
      appBar: AppBar(
        title: const Text('AI Assistant'),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages.isEmpty
                ? ListView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.all(16),
                    children: const [
                      _EmptyChatCard(),
                    ],
                  )
                : ListView.separated(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    itemBuilder: (context, index) {
                      return ChatBubble(message: messages[index]);
                    },
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemCount: messages.length,
                  ),
          ),
          if (chatState.isSending)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ThinkingCard(),
              ),
            ),
          ChatInput(
            controller: _controller,
            isSending: chatState.isSending,
            onSend: _handleSend,
          ),
          const AppBottomNavigation(),
        ],
      ),
    );
  }

  void _handleSend() {
    final message = _controller.text.trim();
    if (message.isEmpty) {
      return;
    }

    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(message);
  }
}

class _EmptyChatCard extends StatelessWidget {
  const _EmptyChatCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121C24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFDBE3ED).withValues(alpha: 0.06),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFFF4F7FB),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Ask about patterns in your recent symptom history and get a concise response grounded in your logs.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: Color(0xFFB9C4D1),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingCard extends StatelessWidget {
  const _ThinkingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF121C24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDBE3ED).withValues(alpha: 0.06),
        ),
      ),
      child: const Text(
        'Thinking...',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFFB9C4D1),
        ),
      ),
    );
  }
}
