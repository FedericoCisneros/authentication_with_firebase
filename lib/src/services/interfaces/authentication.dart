import '../../models/user.dart' as model;

abstract class AuthenticationInterface {
  Future<model.User> signUpWithEmail(String email, String password);
  Future<model.User> signInWithEmail(String email, String password);
  Future<bool> signInWithLink(String emailAuth);
  Future<model.User> signInAnonymously();
  Future<model.User> signInWithGoogle();
  Future<model.User> signInWithApple();
  Future<model.User> signInWithFacebook();
  Future<model.User> signInWithEmailLink(String link);
  Future<void> logout();
}
