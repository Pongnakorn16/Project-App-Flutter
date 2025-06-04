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
  String cus_name;
  String cus_email;
  String cus_password;
  String cus_phone;
  // String image;
  // int balance;
  // int activeStatus;

  CustomerPostRequest({
    // required this.cusId,
    required this.cus_name,
    required this.cus_email,
    required this.cus_password,
    required this.cus_phone,
    // required this.image,
    // required this.balance,
    // required this.activeStatus,
  });

  factory CustomerPostRequest.fromJson(Map<String, dynamic> json) =>
      CustomerPostRequest(
        // cusId: json["cus_id"],
        cus_name: json["cus_name"],
        cus_email: json["cus_email"],
        cus_password: json["cus_password"],
        cus_phone: json["cus_phone"],
        // image: json["image"],
        // balance: json["balance"],
        // activeStatus: json["active_status"],
      );

  Map<String, dynamic> toJson() => {
        // "cus_id": cusId,
        "cus_name": cus_name,
        "cus_email": cus_email,
        "cus_password": cus_password,
        "cus_phone": cus_phone,
        // "image": image,
        // "balance": balance,
        // "active_status": activeStatus,
      };
}
