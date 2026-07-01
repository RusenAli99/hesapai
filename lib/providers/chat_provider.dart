import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../data/models/chat_message_model.dart';
import '../core/services/parser_service.dart';
import 'transaction_provider.dart';

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessageModel>>((ref) {
  return ChatNotifier(ref);
});

class ChatNotifier extends StateNotifier<List<ChatMessageModel>> {
  static const String _storageKey = 'yazgec_chat_history';
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  ChatNotifier(this._ref) : super([]) {
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        state = decoded.map((item) => ChatMessageModel.fromMap(Map<String, dynamic>.from(item))).toList();
      } else {
        _setWelcomeMessage();
      }
    } catch (e) {
      print('Chat history load error: $e');
      _setWelcomeMessage();
    }
  }

  void _setWelcomeMessage() {
    state = [
      ChatMessageModel(
        id: 'welcome_1',
        text: 'Merhaba! Ben YazGeç finans asistanınız. 🤖\n\nGelir ve giderlerinizi buraya yazarak hızlıca kaydedebilirsiniz.',
        sender: 'system',
        createdAt: DateTime.now().subtract(const Duration(seconds: 1)),
      ),
      ChatMessageModel(
        id: 'welcome_2',
        text: 'Örnek olarak şunları yazabilirsiniz:\n\n✍️ "Bugün markette 450 TL harcadım"\n✍️ "Maaşım yattı 35.000 TL"\n✍️ "Faturaya 1200 TL ödedim"\n✍️ "Freelance işten 5000 TL kazandım"',
        sender: 'system',
        createdAt: DateTime.now(),
      ),
    ];
    _saveChatHistory();
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = state.map((m) => m.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(encoded));
    } catch (e) {
      print('Chat history save error: $e');
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Add User Message
    final userMsg = ChatMessageModel(
      id: _uuid.v4(),
      text: text,
      sender: 'user',
      createdAt: DateTime.now(),
    );
    
    state = [...state, userMsg];
    await _saveChatHistory();

    // 2. Add System Typing Indicator Placeholder
    final typingId = _uuid.v4();
    final typingMsg = ChatMessageModel(
      id: typingId,
      text: 'Analiz ediliyor...',
      sender: 'system',
      createdAt: DateTime.now().add(const Duration(milliseconds: 100)),
    );
    
    state = [...state, typingMsg];
    

    // 3. Run Parser
    final result = await ParserService.parse(text);

    if (result == null) {
      // Parsing failed - update typing message with help text
      state = state.map((m) {
        if (m.id == typingId) {
          return ChatMessageModel(
            id: typingId,
            text: 'Yazdığınız metinden bir harcama veya gelir tutarı çıkaramadım. 🧐\nLütfen "Marketten 250 TL harcadım" veya "Maaş 35000" gibi rakam içeren cümleler yazın.',
            sender: 'system',
            createdAt: DateTime.now(),
          );
        }
        return m;
      }).toList();
    } else {
      // Parsing succeeded - show confirmation card preview
      state = state.map((m) {
        if (m.id == typingId) {
          return ChatMessageModel(
            id: typingId,
            text: 'İşlemi onaylıyor musunuz?',
            sender: 'system',
            createdAt: DateTime.now(),
            isParserPreview: true,
            parserResult: result,
          );
        }
        return m;
      }).toList();
    }
    await _saveChatHistory();
  }

  // Action: User modifies the transaction fields in the preview bubble
  void updatePreviewResult(String messageId, ParserResult updatedResult) {
    state = state.map((m) {
      if (m.id == messageId) {
        return m.copyWith(parserResult: updatedResult);
      }
      return m;
    }).toList();
    _saveChatHistory();
  }

  // Action: Save approved transaction
  Future<void> approveTransaction(String messageId) async {
    final index = state.indexWhere((m) => m.id == messageId);
    if (index == -1) return;

    final msg = state[index];
    final result = msg.parserResult;
    if (result == null) return;

    // Set approved status on bubble
    state = state.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isApproved: true);
      }
      return m;
    }).toList();

    // Call transaction controller to save to database
    await _ref.read(transactionControllerProvider).addTransaction(
      amount: result.amount,
      type: result.type,
      category: result.category,
      description: result.description,
      date: result.date,
      isRecurring: result.isRecurring,
      recurringInterval: result.recurringInterval,
    );

    // Add success confirmation message
    final formattedAmount = '${result.amount.toStringAsFixed(0)} TL';
    final confirmationMsg = ChatMessageModel(
      id: _uuid.v4(),
      text: '✅ **${result.category}** kategorisinde **$formattedAmount** tutarındaki ${result.type == 'income' ? 'gelir' : 'gider'} başarıyla kaydedildi!',
      sender: 'system',
      createdAt: DateTime.now(),
    );

    state = [...state, confirmationMsg];
    await _saveChatHistory();
  }

  // Action: User rejects the parsed transaction
  Future<void> rejectTransaction(String messageId) async {
    state = state.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isRejected: true);
      }
      return m;
    }).toList();

    final cancelMsg = ChatMessageModel(
      id: _uuid.v4(),
      text: '❌ İşlem iptal edildi.',
      sender: 'system',
      createdAt: DateTime.now(),
    );

    state = [...state, cancelMsg];
    await _saveChatHistory();
  }

  // Action: Clear chat logs
  Future<void> clearHistory() async {
    state = [];
    _setWelcomeMessage();
  }
}
