import 'dart:async';

import 'package:authentication_with_firebase/src/exceptions/exceptions.dart';
import 'package:authentication_with_firebase/src/models/user.dart';
import 'package:authentication_with_firebase/src/services/authentication.dart';
import 'package:flutter/cupertino.dart';

enum LoginProvider { Email, Dynamic_Link, Google, Facebook, Apple, Anonymous }

class AuthenticationProvider with ChangeNotifier {
  Authentication _authentication = Authentication.instance;

  StreamController<User> authState = StreamController.broadcast();

  AuthenticationProvider() {
    _authentication.authChanges.listen((User user) {
      authState.add(user);
    });
  }

  bool _loading = false;
  User user;

  bool get loading => _loading;

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  Future<bool> login(
      [LoginProvider provider = LoginProvider.Anonymous,
      String email,
      String pass]) async {
    _setLoading(true);
    bool loggedOrSendLink = false;
    try {
      switch (provider) {
        case LoginProvider.Email:
          user = await _authentication.signInWithEmail(email, pass);
          if (user != null) {
            loggedOrSendLink = true;
          }
          break;
        case LoginProvider.Dynamic_Link:
          loggedOrSendLink = await _authentication.signInWithLink(email);
          break;
        case LoginProvider.Google:
          user = await _authentication.signInWithGoogle();
          if (user != null) {
            loggedOrSendLink = true;
          }
          break;
        case LoginProvider.Facebook:
          user = await _authentication.signInWithFacebook();
          if (user != null) {
            loggedOrSendLink = true;
          }
          break;
        case LoginProvider.Apple:
          user = await _authentication.signInWithApple();
          if (user != null) {
            loggedOrSendLink = true;
          }
          break;
        case LoginProvider.Anonymous:
          user = await _authentication.signInAnonymously();
          if (user != null) {
            loggedOrSendLink = true;
          }
          break;
      }
    } on AuthenticationException {
      rethrow;
    } finally {
      _setLoading(false);
    }
    return loggedOrSendLink;
  }

  Future<void> logout() async {
    _setLoading(true);
    await _authentication.logout();
    _setLoading(false);
  }
}
