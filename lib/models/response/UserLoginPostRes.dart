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
  String? address_detail;
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
    this.address_detail,
    this.coordinates,
    this.license_plate,
    required this.balance,
    required this.active_status,
    required this.source_table,
  });

  factory UserLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      UserLoginPostResponse(
        id: json["cus_id"] ?? 0,
        email: json["cus_email"] ?? '',
        phone: json["cus_phone"] ?? '',
        name: json["cus_name"] ?? '',
        password: json["cus_password"] ?? '',
        user_image: json["cus_image"] ?? '',
        address: json["address"], // ถ้ายังไม่มีใน JSON ก็ไม่ต้องแก้
        address_detail: json["address_detail"],
        coordinates: json["coordinates"],
        license_plate: json["license_plate"],
        balance: json["cus_balance"] ?? 0,
        active_status: json["cus_active_status"] ?? 0,
        source_table: json["source_table"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "cus_id": id,
        "cus_email": email,
        "cus_phone": phone,
        "cus_name": name,
        "cus_password": password,
        "cus_image": user_image,
        "address": address,
        "address_detail": address_detail,
        "coordinates": coordinates,
        "license_plate": license_plate,
        "cus_balance": balance,
        "cus_active_status": active_status,
        "source_table": source_table,
      };
}
