// To parse this JSON data, do
//
//     final customer = customerFromJson(jsonString);

import 'dart:convert';

CustomerPostRequest CustomerPostRequestFromJson(String str) =>
    CustomerPostRequest.fromJson(json.decode(str));

String CustomerPostRequestToJson(CustomerPostRequest data) =>
    json.encode(data.toJson());

class CustomerPostRequest {
  // int cusId;
  String name;
  String email;
  String password;
  String phone;
  // String image;
  // int balance;
  // int activeStatus;

  CustomerPostRequest({
    // required this.cusId,
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
    // required this.image,
    // required this.balance,
    // required this.activeStatus,
  });

  factory CustomerPostRequest.fromJson(Map<String, dynamic> json) =>
      CustomerPostRequest(
        // cusId: json["cus_id"],
        name: json["name"],
        email: json["email"],
        password: json["password"],
        phone: json["phone"],
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
        // "image": image,
        // "balance": balance,
        // "active_status": activeStatus,
      };
}
