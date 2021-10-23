import 'package:flutter/material.dart';

class User {
  String uid;
  String photo;
  String email;
  String phone;
  String name;
  bool isAnonymous;
  bool emailVerified;
  Future<void> Function({String displayName, String photoURL}) updateProfile;

  User(
      {@required this.uid,
      this.name,
      this.email,
      this.phone,
      this.photo,
      this.emailVerified = false,
      this.isAnonymous = false,
      this.updateProfile});

  User copyWith(
      {String uid,
      String name,
      String email,
      String phone,
      String photo,
      bool emailVerified,
      bool isAnonymous,
      Function updateProfile}) {
    return User(
        uid: uid ?? this.uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        photo: photo ?? this.photo,
        emailVerified: emailVerified ?? this.emailVerified,
        isAnonymous: isAnonymous ?? this.isAnonymous,
        updateProfile: updateProfile ?? this.updateProfile);
  }
}
