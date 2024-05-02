import 'package:logging/logging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final Logger logger = Logger('AuthService');
  final auth = FirebaseAuth.instance;

  // Mala práctica: No se está manejando el caso en el que googleSignInAccount o googleSignInAuthentication sean null
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication?.accessToken,
        idToken: googleSignInAuthentication?.idToken,
      );

      final UserCredential authResult =
          await _auth.signInWithCredential(credential);
      final User? user = authResult.user;

      assert(!user!.isAnonymous);
      assert(await user?.getIdToken() != null);

      final User? currentUser = _auth.currentUser;
      assert(user?.uid == currentUser?.uid);

      return user;
    } catch (error) {
      logger.severe('Error en signInWithGoogle: $error');
      throw Exception('Error al iniciar sesión con Google: $error');
    }
  }

  Future<String?> getIdToken() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      return await user.getIdToken();
    }
    return null;
  }

  Future<void> signInWithCustomToken(String token) {
    return _auth.signInWithCustomToken(token);
  }

  Future<String?> getCurrentUserUid() async {
    final User? user = _auth.currentUser;
    return user?.uid;
  }

  Future<void> signOutGoogle() async {
    try {
      await googleSignIn.signOut();
    } catch (error) {
      logger.severe('Error al cerrar sesión en Google: $error');
    }
  }
}
