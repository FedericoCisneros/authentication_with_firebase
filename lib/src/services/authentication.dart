import 'package:authentication_with_firebase/src/exceptions/exception_codes.dart';
import 'package:authentication_with_firebase/src/exceptions/exceptions.dart';
import 'package:authentication_with_firebase/src/util/util.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'interfaces/authentication.dart';

class Authentication extends AuthenticationInterface {
  FirebaseAuth _auth = FirebaseAuth.instance;
  ActionCodeSettings actionCodeSettings;

  Authentication({this.actionCodeSettings});

  @override
  Future<UserCredential> signInAnonymously() async {
    return await _auth.signInAnonymously();
  }

  @override
  Future<UserCredential> signInWithApple() async {
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

    UserCredential credential;
    if (oauthCredential != null)
      // Sign in the user with Firebase. If the nonce we generated earlier does
      // not match the nonce in `appleCredential.identityToken`, sign in will fail.
      credential =
          await FirebaseAuth.instance.signInWithCredential(oauthCredential);
    return credential;
  }

  @override
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  @override
  Future<UserCredential> signInWithEmailAnonymous(
      BuildContext context, String email, String password) async {
    EmailAuthCredential emailAuthCredential =
        EmailAuthProvider.credential(email: email, password: password);

    UserCredential credential;
    if (emailAuthCredential != null) {
      credential = await _auth.signInWithCredential(emailAuthCredential);
    }
    return credential;
  }

  @override
  Future<UserCredential> signInWithEmailLink(String link) async {
    final storage = FlutterSecureStorage();
    String email = await storage.read(key: 'email');

    UserCredential credential;
    if (email != null) {
      if (FirebaseAuth.instance.isSignInWithEmailLink(link)) {
        try {
          credential = await FirebaseAuth.instance
              .signInWithEmailLink(email: email, emailLink: link);
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

    if (credential != null) {
      await storage.delete(key: 'email');
      return credential;
    } else {
      return null;
    }
  }

  @override
  Future<UserCredential> signInWithFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();
    OAuthCredential facebookCredential =
        FacebookAuthProvider.credential(result.accessToken.token);

    UserCredential credential;
    if (facebookCredential != null)
      credential =
          await FirebaseAuth.instance.signInWithCredential(facebookCredential);
    return credential;
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    GoogleAuthCredential googleCredential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    UserCredential credential;
    if (googleCredential != null)
      credential = await _auth.signInWithCredential(googleCredential);
    return credential;
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
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
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
