import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/transaction_repository.dart';
import 'transaction_provider.dart';

// Global config checked at runtime
class AppConfig {
  static bool firebaseInitialized = false;
}

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.firebaseInitialized) {
    return FirebaseAuthRepository();
  } else {
    return MockAuthRepository();
  }
});

// Stream provider for user auth state changes
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.onAuthStateChanged;
});

// StateNotifier for user login state
final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<UserModel?>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  return AuthController(authRepository, transactionRepository);
});

class AuthController extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _authRepository;
  final TransactionRepository _transactionRepository;

  AuthController(this._authRepository, this._transactionRepository) : super(const AsyncValue.data(null)) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signInAnonymously(String displayName) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInAnonymously(displayName: displayName);
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateCurrency(String code, String symbol) async {
    if (state.value != null) {
      try {
        final currentUser = state.value!;
        final oldCode = currentUser.currencyCode;
        
        await _authRepository.updateCurrency(code, symbol);
        
        if (oldCode != code) {
          await _transactionRepository.convertTransactionCurrencies(
            currentUser.uid,
            oldCode,
            code,
          );
        }
        
        state = AsyncValue.data(currentUser.copyWith(
          currencyCode: code,
          currencySymbol: symbol,
        ));
      } catch (e, stack) {
        state = AsyncValue.error(e, stack);
      }
    }
  }
}
