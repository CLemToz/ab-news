import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._(); // Private constructor
  static final instance = AuthService._(); // Singleton instance

  // Lazily initialize the services. This ensures they are created only when
  // first accessed, long after the Flutter engine is ready.
  late final FirebaseAuth _auth = FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      // Re-throw the exception to be handled in the UI
      rethrow;
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
      String name, String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await userCredential.user?.updateDisplayName(name);
      // Reload the user to make sure we have the latest data.
      await userCredential.user?.reload();
      return userCredential;
    } on FirebaseAuthException {
      // Re-throw the exception to be handled in the UI
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException {
      // Re-throw the exception to be handled in the UI
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      // Re-throw the exception to be handled in the UI
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      // Check if a user was previously signed in with Google.
      // This check needs to be safe.
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      // This can happen if the google_sign_in plugin is not properly initialized,
      // but we don't want it to crash the whole app.
      print('Error signing out of Google: $e');
    }
    // Always attempt to sign out of Firebase.
    await _auth.signOut();
  }
}
