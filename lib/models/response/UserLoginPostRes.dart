// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

UserLoginPostResponse UserLoginPostResponseFromJson(String str) =>
    UserLoginPostResponse.fromJson(json.decode(str));

String UserLoginPostResponseToJson(UserLoginPostResponse data) =>
    json.encode(data.toJson());

class UserLoginPostResponse {
  int uid;
  String phone;
  String name;
  String password;
  String user_image;
  String address;
  String coordinates;
  String user_type;
  String license_plate;

  UserLoginPostResponse({
    required this.uid,
    required this.phone,
    required this.name,
    required this.password,
    required this.user_image,
    required this.address,
    required this.coordinates,
    required this.user_type,
    required this.license_plate,
  });

  factory UserLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      UserLoginPostResponse(
        uid: json["uid"],
        phone: json["Phone"],
        name: json["Name"],
        password: json["Password"],
        user_image: json["user_image"],
        address: json["address"],
        coordinates: json["coordinates"],
        user_type: json["user_type"],
        license_plate: json["license_plate"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "Phone": phone,
        "Name": name,
        "Password": password,
        "User_image": user_image,
        "Address": address,
        "Coordinates": coordinates,
        "User_type": user_type,
        "License_plate": license_plate,
      };
}
