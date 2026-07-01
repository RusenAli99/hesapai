import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';

abstract class TransactionRepository {
  Stream<List<TransactionModel>> getTransactions(String uid);
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> clearAllTransactions(String uid);
  Future<void> convertTransactionCurrencies(String uid, String fromCode, String toCode);
}

class FirestoreTransactionRepository implements TransactionRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<TransactionModel>> getTransactions(String uid) {
    return _firestore
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Map document ID to model ID
        return TransactionModel.fromMap(data);
      }).toList();
    });
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    final docRef = _firestore.collection('transactions').doc();
    final data = transaction.copyWith(id: docRef.id).toMap();
    await docRef.set(data);
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _firestore
        .collection('transactions')
        .doc(transaction.id)
        .update(transaction.toMap());
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _firestore.collection('transactions').doc(id).delete();
  }

  @override
  Future<void> clearAllTransactions(String uid) async {
    final querySnapshot = await _firestore
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .get();
        
    final batch = _firestore.batch();
    for (final doc in querySnapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  Future<void> convertTransactionCurrencies(String uid, String fromCode, String toCode) async {
    if (fromCode == toCode) return;
    
    final querySnapshot = await _firestore
        .collection('transactions')
        .where('uid', isEqualTo: uid)
        .get();
        
    final rate = _getExchangeRate(fromCode, toCode);
    final batch = _firestore.batch();
    
    for (final doc in querySnapshot.docs) {
      final double amount = (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
      batch.update(doc.reference, {'amount': amount * rate});
    }
    await batch.commit();
  }

  double _getExchangeRate(String from, String to) {
    final Map<String, double> usdToOther = {
      'USD': 1.0,
      'EUR': 0.92,
      'TRY': 46.65,
      'GBP': 0.79,
    };
    final rateFrom = usdToOther[from] ?? 1.0;
    final rateTo = usdToOther[to] ?? 1.0;
    return rateTo / rateFrom;
  }
}

class LocalTransactionRepository implements TransactionRepository {
  static const String _storageKey = 'yazgec_local_transactions';
  
  // Custom stream controller for local database updates
  final List<void Function(List<TransactionModel>)> _listeners = [];
  List<TransactionModel> _cachedTransactions = [];

  LocalTransactionRepository() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _cachedTransactions = decoded
            .map((item) => TransactionModel.fromMap(Map<String, dynamic>.from(item)))
            .toList();
        // Sort by date descending
        _cachedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
      _notify();
    } catch (e) {
      print('Local DB read error: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = _cachedTransactions.map((t) {
        // SharedPreferences requires JSON-safe structures, so convert DateTime to string
        final map = t.toMap();
        map['createdAt'] = t.createdAt.toIso8601String();
        return map;
      }).toList();
      await prefs.setString(_storageKey, jsonEncode(encoded));
      _notify();
    } catch (e) {
      print('Local DB save error: $e');
    }
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(List.from(_cachedTransactions));
    }
  }

  @override
  Stream<List<TransactionModel>> getTransactions(String uid) {
    // Generate stream based on periodic check, mapping user's specific items
    return Stream.periodic(const Duration(milliseconds: 500), (_) {
      return _cachedTransactions.where((t) => t.uid == uid).toList();
    }).distinct((a, b) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (a[i].id != b[i].id || a[i].amount != b[i].amount || a[i].category != b[i].category) {
          return false;
        }
      }
      return true;
    });
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    _cachedTransactions.add(transaction);
    _cachedTransactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveToStorage();
  }

  @override
  Future<void> updateTransaction(TransactionModel transaction) async {
    final index = _cachedTransactions.indexWhere((t) => t.id == transaction.id);
    if (index != -1) {
      _cachedTransactions[index] = transaction;
      await _saveToStorage();
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _cachedTransactions.removeWhere((t) => t.id == id);
    await _saveToStorage();
  }

  @override
  Future<void> clearAllTransactions(String uid) async {
    _cachedTransactions.removeWhere((t) => t.uid == uid);
    await _saveToStorage();
  }

  @override
  Future<void> convertTransactionCurrencies(String uid, String fromCode, String toCode) async {
    if (fromCode == toCode) return;
    
    final rate = _getExchangeRate(fromCode, toCode);
    bool modified = false;
    
    for (int i = 0; i < _cachedTransactions.length; i++) {
      if (_cachedTransactions[i].uid == uid) {
        final current = _cachedTransactions[i];
        _cachedTransactions[i] = current.copyWith(
          amount: current.amount * rate,
        );
        modified = true;
      }
    }
    
    if (modified) {
      await _saveToStorage();
    }
  }

  double _getExchangeRate(String from, String to) {
    final Map<String, double> usdToOther = {
      'USD': 1.0,
      'EUR': 0.92,
      'TRY': 46.65,
      'GBP': 0.79,
    };
    final rateFrom = usdToOther[from] ?? 1.0;
    final rateTo = usdToOther[to] ?? 1.0;
    return rateTo / rateFrom;
  }
}
