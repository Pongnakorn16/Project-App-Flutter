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
  String? address;
  String? coordinates;
  String user_type;
  String? license_plate;

  UserLoginPostResponse({
    required this.uid,
    required this.phone,
    required this.name,
    required this.password,
    required this.user_image,
    this.address,
    this.coordinates,
    required this.user_type,
    this.license_plate,
  });

  factory UserLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      UserLoginPostResponse(
        uid: json["id"] ?? 0,
        phone: json["phone"] ?? '',
        name: json["name"] ?? '',
        password: json["password"] ?? '',
        user_image: json["image"] ?? '',
        address: json["address"],
        coordinates: json["coordinates"],
        user_type: json["source_table"] ?? '',
        license_plate: json["license_plate"],
      );

  Map<String, dynamic> toJson() => {
        "id": uid,
        "phone": phone,
        "name": name,
        "password": password,
        "image": user_image,
        "address": address,
        "coordinates": coordinates,
        "source_table": user_type,
        "license_plate": license_plate,
      };
}
