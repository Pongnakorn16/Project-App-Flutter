// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

UserLoginPostResponse UserLoginPostResponseFromJson(String str) =>
    UserLoginPostResponse.fromJson(json.decode(str));

String UserLoginPostResponseToJson(UserLoginPostResponse data) =>
    json.encode(data.toJson());

class UserLoginPostResponse {
  int id;
  String email;
  String phone;
  String name;
  String password;
  String user_image;
  String? address;
  String? coordinates;
  String? license_plate;
  int balance;
  int active_status;
  String source_table;

  UserLoginPostResponse({
    required this.id,
    required this.email,
    required this.phone,
    required this.name,
    required this.password,
    required this.user_image,
    this.address,
    this.coordinates,
    this.license_plate,
    required this.balance,
    required this.active_status,
    required this.source_table,
  });

  factory UserLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      UserLoginPostResponse(
          id: json["id"] ?? 0,
          email: json["email"] ?? '',
          phone: json["phone"] ?? '',
          name: json["name"] ?? '',
          password: json["password"] ?? '',
          user_image: json["image"] ?? '',
          address: json["address"],
          coordinates: json["coordinates"],
          license_plate: json["license_plate"],
          balance: json["balance"] ?? 0,
          active_status: json["activ_status"] ?? 0,
          source_table: json["source_table"]);

  Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "phone": phone,
        "name": name,
        "password": password,
        "image": user_image,
        "address": address,
        "coordinates": coordinates,
        "license_plate": license_plate,
        "balance": balance,
        "active_status": active_status,
        "source_table": source_table,
      };
}
