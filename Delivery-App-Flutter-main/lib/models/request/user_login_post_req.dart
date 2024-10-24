// To parse this JSON data, do
//
//     final UserLoginPostRequest = UserLoginPostRequestFromJson(jsonString);

import 'dart:convert';

UserLoginPostRequest UserLoginPostRequestFromJson(String str) =>
    UserLoginPostRequest.fromJson(json.decode(str));

String UserLoginPostRequestToJson(UserLoginPostRequest data) =>
    json.encode(data.toJson());

class UserLoginPostRequest {
  String Phone;
  String Password;

  UserLoginPostRequest({
    required this.Phone,
    required this.Password,
  });

  factory UserLoginPostRequest.fromJson(Map<String, dynamic> json) =>
      UserLoginPostRequest(
        Phone: json["Phone"],
        Password: json["Password"],
      );

  Map<String, dynamic> toJson() => {
        "Phone": Phone,
        "Password": Password,
      };
}
