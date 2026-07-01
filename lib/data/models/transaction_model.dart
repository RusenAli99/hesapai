import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String uid;
  final String type; // 'income' or 'expense'
  final String category;
  final double amount;
  final String description;
  final DateTime createdAt;
  final bool isRecurring;
  final String? recurringInterval; // 'weekly', 'monthly', 'yearly'
  final String? recurringParentId;

  TransactionModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.createdAt,
    this.isRecurring = false,
    this.recurringInterval,
    this.recurringParentId,
  });

  TransactionModel copyWith({
    String? id,
    String? uid,
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? createdAt,
    bool? isRecurring,
    String? recurringInterval,
    String? recurringParentId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringInterval: recurringInterval ?? this.recurringInterval,
      recurringParentId: recurringParentId ?? this.recurringParentId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRecurring': isRecurring,
      'recurringInterval': recurringInterval,
      'recurringParentId': recurringParentId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['createdAt'] is Timestamp) {
      parsedDate = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedDate = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: map['id'] ?? '',
      uid: map['uid'] ?? '',
      type: map['type'] ?? 'expense',
      category: map['category'] ?? 'Diğer',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      description: map['description'] ?? '',
      createdAt: parsedDate,
      isRecurring: map['isRecurring'] ?? false,
      recurringInterval: map['recurringInterval'],
      recurringParentId: map['recurringParentId'],
    );
  }
}
