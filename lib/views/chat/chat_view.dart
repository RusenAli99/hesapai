import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/parser_preview.dart';
import 'widgets/chat_input_field.dart';
import '../../providers/chat_provider.dart';
import '../../core/theme/app_colors.dart';

class ChatView extends ConsumerStatefulWidget {
  const ChatView({super.key});

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Auto-scroll helper
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger auto-scroll on new messages
    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.transparent,
              backgroundImage: const AssetImage('assets/logo.png'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YazGeç Asistanı',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.income,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Aktif',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Sohbeti Temizle',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sohbeti Temizle'),
                  content: const Text('Sohbet geçmişinizi temizlemek istediğinize emin misiniz? İşlemleriniz silinmeyecektir.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppColors.expense),
                      onPressed: () {
                        ref.read(chatProvider.notifier).clearHistory();
                        Navigator.pop(context);
                      },
                      child: const Text('Temizle'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                
                if (message.isParserPreview) {
                  return ParserPreview(message: message);
                }
                
                return ChatBubble(message: message);
              },
            ),
          ),
          
          // Input Bar
          ChatInputField(
            onSend: (text) {
              ref.read(chatProvider.notifier).sendMessage(text);
            },
          ),
        ],
      ),
    );
  }
}
