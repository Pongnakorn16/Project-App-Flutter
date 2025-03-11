// To parse this JSON data, do
//
//     final customer = customerFromJson(jsonString);

import 'dart:convert';

RiderPostRequest RiderPostRequestFromJson(String str) =>
    RiderPostRequest.fromJson(json.decode(str));

String RiderPostRequestToJson(RiderPostRequest data) =>
    json.encode(data.toJson());

class RiderPostRequest {
  // int cusId;
  String name;
  String email;
  String password;
  String phone;
  String license;
  // String image;
  // int balance;
  // int activeStatus;

  RiderPostRequest({
    // required this.cusId,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    required this.license,
    // required this.image,
    // required this.balance,
    // required this.activeStatus,
  });

  factory RiderPostRequest.fromJson(Map<String, dynamic> json) =>
      RiderPostRequest(
          // cusId: json["cus_id"],
          name: json["name"],
          email: json["email"],
          password: json["password"],
          phone: json["phone"],
          license: json["license"]
          // image: json["image"],
          // balance: json["balance"],
          // activeStatus: json["active_status"],
          );

  Map<String, dynamic> toJson() => {
        // "cus_id": cusId,
        "name": name,
        "email": email,
        "password": password,
        "phone": phone,
        "license": license,
        // "image": image,
        // "balance": balance,
        // "active_status": activeStatus,
      };
}
