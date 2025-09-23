import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ NEW API: Use GoogleSignIn.instance instead of GoogleSignIn()
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web implementation
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        final UserCredential userCredential =
        await _auth.signInWithPopup(authProvider);
        return userCredential.user;
      } else {
        // ✅ NEW API: Use authenticate() instead of signIn()
        final GoogleSignInAccount? googleSignInAccount =
        await _googleSignIn.signIn();

        if (googleSignInAccount != null) {
          final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

          // ✅ NEW API: Use idToken and accessToken properties correctly
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleSignInAuthentication.accessToken,
            idToken: googleSignInAuthentication.idToken,
          );

          final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
          return userCredential.user;
        }
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
    return null;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
