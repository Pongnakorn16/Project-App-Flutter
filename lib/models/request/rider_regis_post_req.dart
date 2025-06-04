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
  String rid_name;
  String rid_email;
  String rid_password;
  String rid_phone;
  String rid_license;
  // String image;
  // int balance;
  // int activeStatus;

  RiderPostRequest({
    // required this.cusId,
    required this.rid_name,
    required this.rid_email,
    required this.rid_password,
    required this.rid_phone,
    required this.rid_license,
    // required this.image,
    // required this.balance,
    // required this.activeStatus,
  });

  factory RiderPostRequest.fromJson(Map<String, dynamic> json) =>
      RiderPostRequest(
          // cusId: json["cus_id"],
          rid_name: json["rid_name"],
          rid_email: json["rid_email"],
          rid_password: json["rid_password"],
          rid_phone: json["rid_phone"],
          rid_license: json["rid_license"]
          // image: json["image"],
          // balance: json["balance"],
          // activeStatus: json["active_status"],
          );

  Map<String, dynamic> toJson() => {
        // "cus_id": cusId,
        "rid_name": rid_name,
        "rid_email": rid_email,
        "rid_password": rid_password,
        "rid_phone": rid_phone,
        "rid_license": rid_license,
        // "image": image,
        // "balance": balance,
        // "active_status": activeStatus,
      };
}
