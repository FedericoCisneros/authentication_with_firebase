import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

abstract class AuthenticationInterface {
  Future<UserCredential> signUpWithEmail(String email, String password);
  Future<UserCredential> signInWithEmail(String email, String password);
  Future<UserCredential> signInWithEmailAnonymous(
      BuildContext context, String email, String password);
  Future<bool> signInWithLink(String emailAuth);
  Future<UserCredential> signInAnonymously();
  Future<UserCredential> signInWithGoogle();
  Future<UserCredential> signInWithApple();
  Future<UserCredential> signInWithFacebook();
  Future<UserCredential> signInWithEmailLink(String link);
  Future<void> logout();
}
