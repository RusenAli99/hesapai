import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transaction_repository.dart';
import 'auth_provider.dart';

// Provider for TransactionRepository
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  if (AppConfig.firebaseInitialized) {
    return FirestoreTransactionRepository();
  } else {
    return LocalTransactionRepository();
  }
});

// Stream provider to fetch user transactions in real-time
final transactionsProvider = StreamProvider.autoDispose<List<TransactionModel>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  final authState = ref.watch(authStateProvider);

  final user = authState.value;
  if (user == null) {
    return Stream.value([]);
  }
  return repository.getTransactions(user.uid).map((transactions) {
    // Check and process recurring transactions asynchronously
    Future.microtask(() {
      if (ref.read(authStateProvider).value != null) {
        ref.read(transactionControllerProvider).checkAndProcessRecurringTransactions(transactions);
      }
    });
    return transactions;
  });
});

// Provider for the currently selected month for filtering
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

// Controller for transactions action operations
final transactionControllerProvider = Provider((ref) => TransactionController(ref));

class TransactionController {
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  TransactionController(this._ref);

  TransactionRepository get _repository => _ref.read(transactionRepositoryProvider);
  String? get _currentUserId => _ref.read(authStateProvider).value?.uid;

  Future<void> addTransaction({
    required double amount,
    required String type,
    required String category,
    required String description,
    required DateTime date,
    bool isRecurring = false,
    String? recurringInterval,
    String? recurringParentId,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final transaction = TransactionModel(
      id: _uuid.v4(),
      uid: uid,
      type: type,
      category: category,
      amount: amount,
      description: description,
      createdAt: date,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
      recurringParentId: recurringParentId,
    );

    await _repository.addTransaction(transaction);
  }

  Future<void> updateTransaction({
    required String id,
    required double amount,
    required String type,
    required String category,
    required String description,
    required DateTime date,
    required bool isRecurring,
    String? recurringInterval,
  }) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final transaction = TransactionModel(
      id: id,
      uid: uid,
      type: type,
      category: category,
      amount: amount,
      description: description,
      createdAt: date,
      isRecurring: isRecurring,
      recurringInterval: recurringInterval,
    );

    await _repository.updateTransaction(transaction);
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
  }

  Future<void> clearAllTransactions() async {
    final uid = _currentUserId;
    if (uid == null) return;
    await _repository.clearAllTransactions(uid);
  }

  Future<void> checkAndProcessRecurringTransactions(List<TransactionModel> transactions) async {
    final uid = _currentUserId;
    if (uid == null) return;

    final now = DateTime.now();

    // 1. Filter recurring transactions (parents)
    final recurringParents = transactions.where((t) => t.isRecurring && t.uid == uid).toList();
    if (recurringParents.isEmpty) return;

    final List<TransactionModel> newOccurrences = [];

    for (final parent in recurringParents) {
      final interval = parent.recurringInterval;
      if (interval == null) continue;

      DateTime occurrenceDate = parent.createdAt;

      while (true) {
        // Calculate the next occurrence date
        if (interval == 'weekly') {
          occurrenceDate = occurrenceDate.add(const Duration(days: 7));
        } else if (interval == 'monthly') {
          occurrenceDate = _addMonths(occurrenceDate, 1);
        } else if (interval == 'yearly') {
          occurrenceDate = _addYears(occurrenceDate, 1);
        } else {
          break; // unknown interval
        }

        // If the occurrence date is in the future, stop calculating for this parent
        if (occurrenceDate.isAfter(now)) {
          break;
        }

        // Check if we already have a transaction for this parent at this date
        final exists = transactions.any((t) =>
            t.uid == uid &&
            t.recurringParentId == parent.id &&
            t.createdAt.year == occurrenceDate.year &&
            t.createdAt.month == occurrenceDate.month &&
            t.createdAt.day == occurrenceDate.day);

        if (!exists) {
          // Generate a new transaction occurrence
          newOccurrences.add(
            TransactionModel(
              id: _uuid.v4(),
              uid: uid,
              type: parent.type,
              category: parent.category,
              amount: parent.amount,
              description: parent.description,
              createdAt: occurrenceDate,
              isRecurring: false, // The occurrence itself is not recurring
              recurringParentId: parent.id,
            ),
          );
        }
      }
    }

    // 2. Add all new occurrences to the database
    if (newOccurrences.isNotEmpty) {
      for (final occurrence in newOccurrences) {
        await _repository.addTransaction(occurrence);
      }
    }
  }

  // Helpers for adding months and years
  DateTime _addMonths(DateTime dt, int months) {
    int year = dt.year;
    int month = dt.month + months;
    while (month > 12) {
      year++;
      month -= 12;
    }
    int day = dt.day;
    int daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    return DateTime(year, month, day, dt.hour, dt.minute, dt.second, dt.millisecond, dt.microsecond);
  }

  DateTime _addYears(DateTime dt, int years) {
    int year = dt.year + years;
    int month = dt.month;
    int day = dt.day;
    if (month == 2 && day == 29) {
      if (!_isLeapYear(year)) {
        day = 28;
      }
    }
    return DateTime(year, month, day, dt.hour, dt.minute, dt.second, dt.millisecond, dt.microsecond);
  }

  int _getDaysInMonth(int year, int month) {
    if (month == 2) {
      return _isLeapYear(year) ? 29 : 28;
    }
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return days[month - 1];
  }

  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
}
