import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

const _webClientId =
    '932597676201-7uotnk7681r19t2pvoa05e0ru3vkrpdd.apps.googleusercontent.com';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();
  static User? get currentUser => _auth.currentUser;

  static Future<void> initialize() {
    return GoogleSignIn.instance.initialize(
      clientId: kIsWeb ? _webClientId : null,
      serverClientId: _webClientId,
    );
  }

  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final idToken = googleUser.authentication.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await Future.wait([GoogleSignIn.instance.signOut(), _auth.signOut()]);
  }
}
