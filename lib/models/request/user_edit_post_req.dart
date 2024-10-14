// To parse this JSON data, do
//
//     final UserRegisterPostRequest = UserRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

UserEditPostRequest UserEditPostRequestFromJson(String str) =>
    UserEditPostRequest.fromJson(json.decode(str));

String UserEditPostRequestToJson(UserEditPostRequest data) =>
    json.encode(data.toJson());

class UserEditPostRequest {
  int? uid;
  String? phone;
  String? name;
  String? password;
  String? address;
  String? coordinate;

  UserEditPostRequest({
    required this.uid,
    required this.phone,
    required this.name,
    required this.password,
    required this.address,
    required this.coordinate,
  });

  factory UserEditPostRequest.fromJson(Map<String, dynamic> json) =>
      UserEditPostRequest(
        uid: json["Uid"],
        phone: json["Phone"],
        name: json["Name"],
        password: json["Password"],
        address: json["Address"],
        coordinate: json["Coordinate"],
      );

  Map<String, dynamic> toJson() => {
        "Uid": uid,
        "Phone": phone,
        "Name": name,
        "Password": password,
        "Address": address,
        "Coordinate": coordinate,
      };
}
