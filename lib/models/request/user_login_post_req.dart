// To parse this JSON data, do
//
//     final UserLoginPostRequest = UserLoginPostRequestFromJson(jsonString);

import 'dart:convert';

UserLoginPostRequest UserLoginPostRequestFromJson(String str) =>
    UserLoginPostRequest.fromJson(json.decode(str));

String UserLoginPostRequestToJson(UserLoginPostRequest data) =>
    json.encode(data.toJson());

class UserLoginPostRequest {
  String Email;
  String Password;

  UserLoginPostRequest({
    required this.Email,
    required this.Password,
  });

  factory UserLoginPostRequest.fromJson(Map<String, dynamic> json) =>
      UserLoginPostRequest(
        Email: json["Email"],
        Password: json["Password"],
      );

  Map<String, dynamic> toJson() => {
        "Email": Email,
        "Password": Password,
      };
}
