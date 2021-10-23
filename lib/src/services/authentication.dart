import 'dart:async';

import 'package:authentication_with_firebase/src/exceptions/exception_codes.dart';
import 'package:authentication_with_firebase/src/exceptions/exceptions.dart';
import 'package:authentication_with_firebase/src/models/user.dart' as model;
import 'package:authentication_with_firebase/src/util/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'interfaces/authentication.dart';

class Authentication extends AuthenticationInterface {
  FirebaseAuth _auth = FirebaseAuth.instance;
  ActionCodeSettings actionCodeSettings;

  StreamController<model.User> _authChange = new StreamController.broadcast();

  Authentication._() {
    _auth.authStateChanges().listen((event) {
      if (event == null)
        _authChange.add(null);
      else
        _authChange.add(model.User(
            uid: event.uid,
            name: event.displayName,
            emailVerified: event.emailVerified,
            email: event.email,
            phone: event.phoneNumber,
            photo: event.photoURL,
            isAnonymous: event.isAnonymous,
            updateProfile: event.updateProfile));
    });
  }

  static Authentication _instance;

  static Authentication get instance {
    if (_instance == null) {
      _instance = Authentication._();
    }
    return _instance;
  }

  Stream<model.User> get authChanges => _authChange.stream;

  @override
  Future<model.User> signInAnonymously() async {
    final credential = await _auth.signInAnonymously();
    if (credential != null)
      return model.User(
          uid: credential.user.uid,
          name: credential.user.displayName,
          emailVerified: credential.user.emailVerified,
          email: credential.user.email,
          phone: credential.user.phoneNumber,
          photo: credential.user.photoURL,
          isAnonymous: credential.user.isAnonymous,
          updateProfile: credential.user.updateProfile);
    return null;
  }

  @override
  Future<model.User> signInWithApple() async {
    // To prevent replay attacks with the credential returned from Apple, we
    // include a nonce in the credential request. When signing in in with
    // Firebase, the nonce in the id token returned by Apple, is expected to
    // match the sha256 hash of `rawNonce`.
    final rawNonce = generateNonce();
    final nonce = sha256ofString(rawNonce);

    // Request credential for the currently signed in Apple account.
    AuthorizationCredentialAppleID appleCredential;
    try {
      appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      throw SignInWithAppleAuthorizationException(
          code: e.code, message: e.message);
    }

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com").credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    model.User user;
    if (oauthCredential != null) {
      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      final credential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
      if (credential != null) {
        user = model.User(
            uid: credential.user.uid,
            name: credential.user.displayName,
            emailVerified: credential.user.emailVerified,
            email: credential.user.email,
            phone: credential.user.phoneNumber,
            photo: credential.user.photoURL,
            isAnonymous: credential.user.isAnonymous,
            updateProfile: credential.user.updateProfile);
      }
    }
    return user;
  }

  @override
  Future<model.User> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (credential != null)
      return model.User(
          uid: credential.user.uid,
          name: credential.user.displayName,
          emailVerified: credential.user.emailVerified,
          email: credential.user.email,
          phone: credential.user.phoneNumber,
          photo: credential.user.photoURL,
          isAnonymous: credential.user.isAnonymous,
          updateProfile: credential.user.updateProfile);
    return null;
  }

  @override
  Future<model.User> signInWithEmailLink(String link) async {
    final storage = FlutterSecureStorage();
    String email = await storage.read(key: 'email');

    model.User user;
    if (email != null) {
      if (FirebaseAuth.instance.isSignInWithEmailLink(link)) {
        try {
          final credential = await FirebaseAuth.instance
              .signInWithEmailLink(email: email, emailLink: link);
          if (credential != null) {
            user = model.User(
                uid: credential.user.uid,
                name: credential.user.displayName,
                emailVerified: credential.user.emailVerified,
                email: credential.user.email,
                phone: credential.user.phoneNumber,
                photo: credential.user.photoURL,
                isAnonymous: credential.user.isAnonymous,
                updateProfile: credential.user.updateProfile);
          }
        } on FirebaseAuthException catch (e) {
          if (e.code == "expired-action-code")
            throw AuthenticationException(
                code: ExceptionCodes.EXPIRED_ACTION_CODE);
          else if (e.code == "invalid-email") {
            throw AuthenticationException(code: ExceptionCodes.INVALID_EMAIL);
          } else if (e.code == "user-disabled") {
            throw AuthenticationException(code: ExceptionCodes.USER_DISABLED);
          }
        }
      }
    }

    if (user != null) {
      await storage.delete(key: 'email');
    }
    return user;
  }

  @override
  Future<model.User> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    OAuthCredential facebookCredential =
        FacebookAuthProvider.credential(result.accessToken.token);

    model.User user;
    if (facebookCredential != null) {
      final credential =
          await FirebaseAuth.instance.signInWithCredential(facebookCredential);
      if (credential != null) {
        user = model.User(
            uid: credential.user.uid,
            name: credential.user.displayName,
            emailVerified: credential.user.emailVerified,
            email: credential.user.email,
            phone: credential.user.phoneNumber,
            photo: credential.user.photoURL,
            isAnonymous: credential.user.isAnonymous,
            updateProfile: credential.user.updateProfile);
      }
    }
    return user;
  }

  @override
  Future<model.User> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    GoogleAuthCredential googleCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    model.User user;
    if (googleCredential != null) {
      final credential = await _auth.signInWithCredential(googleCredential);
      if (credential != null) {
        user = model.User(
            uid: credential.user.uid,
            name: credential.user.displayName,
            emailVerified: credential.user.emailVerified,
            email: credential.user.email,
            phone: credential.user.phoneNumber,
            photo: credential.user.photoURL,
            isAnonymous: credential.user.isAnonymous,
            updateProfile: credential.user.updateProfile);
      }
    }
    return user;
  }

  @override
  Future<bool> signInWithLink(String emailAuth) async {
    if (actionCodeSettings == null)
      throw AuthenticationException(code: ExceptionCodes.ACTION_CODE_SETTINGS);

    /// A [FirebaseAuthException] maybe thrown with the following error code:
    /// - **invalid-email**:
    ///  - Thrown if the email address is not valid.
    /// - **user-not-found**:
    ///  - Thrown if there is no user corresponding to the email address.
    try {
      await FirebaseAuth.instance.sendSignInLinkToEmail(
          email: emailAuth, actionCodeSettings: actionCodeSettings);
    } on FirebaseAuthException catch (e) {
      if (e.code == "invalid-email")
        throw AuthenticationException(code: ExceptionCodes.INVALID_EMAIL);
      else if (e.code == "user-not-found")
        throw AuthenticationException(code: ExceptionCodes.USER_NOT_FOUND);
    }

    return true;
  }

  @override
  Future<model.User> signUpWithEmail(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    if (credential != null) {
      return model.User(
          uid: credential.user.uid,
          name: credential.user.displayName,
          emailVerified: credential.user.emailVerified,
          email: credential.user.email,
          phone: credential.user.phoneNumber,
          photo: credential.user.photoURL,
          isAnonymous: credential.user.isAnonymous,
          updateProfile: credential.user.updateProfile);
    }
    return null;
  }

  @override
  Future<void> logout() async {
    final isLoggedWithFacebook = await FacebookAuth.instance.isLogged;
    if (isLoggedWithFacebook != null) {
      await FacebookAuth.instance.logOut();
    }

    await _auth.signOut();
  }
}
