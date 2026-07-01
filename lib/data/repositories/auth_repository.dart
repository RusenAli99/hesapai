import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get onAuthStateChanged;
  Future<UserModel?> signInWithGoogle();
  Future<UserModel?> signInAnonymously({String? displayName});
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> updateCurrency(String code, String symbol);
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  @override
  Stream<UserModel?> get onAuthStateChanged => _auth.authStateChanges().map((user) {
        if (user == null) return null;
        return UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Kullanıcı',
          email: user.email ?? '',
        );
      });

  @override
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        return UserModel(
          uid: user.uid,
          name: user.displayName ?? 'Kullanıcı',
          email: user.email ?? '',
        );
      }
    } catch (e) {
      print('Firebase Google Sign-In Error: $e');
      rethrow;
    }
    return null;
  }

  @override
  Future<UserModel?> signInAnonymously({String? displayName}) async {
    final UserCredential credential = await _auth.signInAnonymously();
    if (credential.user != null) {
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user!.updateDisplayName(displayName);
      }
      return UserModel(
        uid: credential.user!.uid,
        name: displayName ?? credential.user!.displayName ?? 'Misafir Kullanıcı',
        email: credential.user!.email ?? '',
      );
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Get currency preference from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('currency_code') ?? 'TRY';
      final symbol = prefs.getString('currency_symbol') ?? '₺';
      return UserModel(
        uid: user.uid,
        name: user.displayName ?? 'Kullanıcı',
        email: user.email ?? '',
        currencyCode: code,
        currencySymbol: symbol,
      );
    }
    return null;
  }

  @override
  Future<void> updateCurrency(String code, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    await prefs.setString('currency_symbol', symbol);
  }
}

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  
  // Custom StreamController mapping
  final List<void Function(UserModel?)> _listeners = [];

  MockAuthRepository() {
    _loadMockUser();
  }

  Future<void> _loadMockUser() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('mock_uid');
    if (uid != null) {
      final name = prefs.getString('mock_name') ?? 'Misafir';
      final email = prefs.getString('mock_email') ?? 'misafir@yazgec.com';
      final code = prefs.getString('currency_code') ?? 'TRY';
      final symbol = prefs.getString('currency_symbol') ?? '₺';
      _currentUser = UserModel(
        uid: uid,
        name: name,
        email: email,
        currencyCode: code,
        currencySymbol: symbol,
      );
      _notify();
    }
  }

  void _notify() {
    for (final listener in _listeners) {
      listener(_currentUser);
    }
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    // Custom stream that immediately emits current user and listens to changes
    return Stream.fromFuture(Future.value(_currentUser)).concatWithStream(
      Stream.periodic(const Duration(milliseconds: 500), (_) => _currentUser).distinct(),
    );
  }

  @override
  Future<UserModel?> signInWithGoogle() async {
    // Mock successful sign in after 1 second delay
    await Future.delayed(const Duration(milliseconds: 800));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_uid', 'mock_google_user_123');
    await prefs.setString('mock_name', 'Deneme Kullanıcısı');
    await prefs.setString('mock_email', 'deneme.yazgec@gmail.com');
    
    final code = prefs.getString('currency_code') ?? 'TRY';
    final symbol = prefs.getString('currency_symbol') ?? '₺';

    _currentUser = UserModel(
      uid: 'mock_google_user_123',
      name: 'Deneme Kullanıcısı',
      email: 'deneme.yazgec@gmail.com',
      currencyCode: code,
      currencySymbol: symbol,
    );
    _notify();
    return _currentUser;
  }

  @override
  Future<UserModel?> signInAnonymously({String? displayName}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mock_uid', 'mock_anon_user');
    await prefs.setString('mock_name', displayName ?? 'Misafir Kullanıcı');
    await prefs.setString('mock_email', 'misafir@yazgec.com');
    
    final code = prefs.getString('currency_code') ?? 'TRY';
    final symbol = prefs.getString('currency_symbol') ?? '₺';

    _currentUser = UserModel(
      uid: 'mock_anon_user',
      name: displayName ?? 'Misafir Kullanıcı',
      email: 'misafir@yazgec.com',
      currencyCode: code,
      currencySymbol: symbol,
    );
    _notify();
    return _currentUser;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('mock_uid');
    await prefs.remove('mock_name');
    await prefs.remove('mock_email');
    _currentUser = null;
    _notify();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    await _loadMockUser();
    return _currentUser;
  }

  @override
  Future<void> updateCurrency(String code, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency_code', code);
    await prefs.setString('currency_symbol', symbol);
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        currencyCode: code,
        currencySymbol: symbol,
      );
      _notify();
    }
  }
}

// Extends stream compatibility
extension StreamConcat<T> on Stream<T> {
  Stream<T> concatWithStream(Stream<T> other) async* {
    yield* this;
    yield* other;
  }
}
