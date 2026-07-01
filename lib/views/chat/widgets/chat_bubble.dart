import 'package:flutter/material.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;

  const ChatBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Rich Text Formatting helper (handles simple bold markdown e.g. **text**)
    Widget buildMessageText(String text, TextStyle baseStyle) {
      final List<TextSpan> spans = [];
      final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
      
      int lastIndex = 0;
      for (final match in regex.allMatches(text)) {
        if (match.start > lastIndex) {
          spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
        }
        spans.add(
          TextSpan(
            text: match.group(1),
            style: baseStyle.copyWith(fontWeight: FontWeight.bold),
          ),
        );
        lastIndex = match.end;
      }
      
      if (lastIndex < text.length) {
        spans.add(TextSpan(text: text.substring(lastIndex)));
      }

      return RichText(
        text: TextSpan(
          children: spans.isEmpty ? [TextSpan(text: text)] : spans,
          style: baseStyle,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.primary
                    : (isDark ? AppColors.cardDark : Colors.white),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 0),
                  bottomRight: Radius.circular(isUser ? 0 : 20),
                ),
                border: !isUser
                    ? Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: buildMessageText(
                message.text,
                TextStyle(
                  fontSize: 15,
                  color: isUser
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                  height: 1.35,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4.0, right: 4.0, top: 4.0, bottom: 8.0),
              child: Text(
                Formatters.formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
