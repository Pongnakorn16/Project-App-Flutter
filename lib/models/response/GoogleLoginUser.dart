// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

GoogleLoginUser GoogleLoginUserFromJson(String str) =>
    GoogleLoginUser.fromJson(json.decode(str));

String GoogleLoginUserToJson(GoogleLoginUser data) =>
    json.encode(data.toJson());

class GoogleLoginUser {
  final String displayName;
  final String email;
  final String photoUrl;

  GoogleLoginUser({
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  factory GoogleLoginUser.fromJson(Map<String, dynamic> json) {
    return GoogleLoginUser(
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
      };
}
