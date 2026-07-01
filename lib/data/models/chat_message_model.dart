import '../../core/services/parser_service.dart';

class ChatMessageModel {
  final String id;
  final String text;
  final String sender; // 'user' or 'system'
  final DateTime createdAt;
  
  // Custom states for parser interaction
  final bool isParserPreview;
  final ParserResult? parserResult;
  final bool isApproved; // If user clicked "Save" on the parser preview
  final bool isRejected; // If user clicked "Cancel/Ignore"

  ChatMessageModel({
    required this.id,
    required this.text,
    required this.sender,
    required this.createdAt,
    this.isParserPreview = false,
    this.parserResult,
    this.isApproved = false,
    this.isRejected = false,
  });

  ChatMessageModel copyWith({
    String? id,
    String? text,
    String? sender,
    DateTime? createdAt,
    bool? isParserPreview,
    ParserResult? parserResult,
    bool? isApproved,
    bool? isRejected,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      createdAt: createdAt ?? this.createdAt,
      isParserPreview: isParserPreview ?? this.isParserPreview,
      parserResult: parserResult ?? this.parserResult,
      isApproved: isApproved ?? this.isApproved,
      isRejected: isRejected ?? this.isRejected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'createdAt': createdAt.toIso8601String(),
      'isParserPreview': isParserPreview,
      'isApproved': isApproved,
      'isRejected': isRejected,
      if (parserResult != null) ...{
        'amount': parserResult!.amount,
        'type': parserResult!.type,
        'category': parserResult!.category,
        'description': parserResult!.description,
        'date': parserResult!.date.toIso8601String(),
        'isRecurring': parserResult!.isRecurring,
        'recurringInterval': parserResult!.recurringInterval,
      }
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    ParserResult? parsed;
    if (map['isParserPreview'] == true && map['amount'] != null) {
      parsed = ParserResult(
        amount: (map['amount'] as num).toDouble(),
        type: map['type'] ?? 'expense',
        category: map['category'] ?? 'Diğer',
        description: map['description'] ?? '',
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        isRecurring: map['isRecurring'] ?? false,
        recurringInterval: map['recurringInterval'],
      );
    }

    return ChatMessageModel(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      sender: map['sender'] ?? 'user',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      isParserPreview: map['isParserPreview'] ?? false,
      isApproved: map['isApproved'] ?? false,
      isRejected: map['isRejected'] ?? false,
      parserResult: parsed,
    );
  }
}
