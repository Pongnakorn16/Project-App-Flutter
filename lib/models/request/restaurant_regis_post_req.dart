// To parse this JSON data, do
//
//     final customer = customerFromJson(jsonString);

import 'dart:convert';

RestaurantPostRequest RestaurantPostRequestFromJson(String str) =>
    RestaurantPostRequest.fromJson(json.decode(str));

String RestaurantPostRequestToJson(RestaurantPostRequest data) =>
    json.encode(data.toJson());

class RestaurantPostRequest {
  // int cusId;
  String res_name;
  String res_email;
  String res_password;
  String res_phone;
  // String image;
  // int balance;
  // int activeStatus;

  RestaurantPostRequest({
    // required this.cusId,
    required this.res_name,
    required this.res_email,
    required this.res_password,
    required this.res_phone,
    // required this.image,
    // required this.balance,
    // required this.activeStatus,
  });

  factory RestaurantPostRequest.fromJson(Map<String, dynamic> json) =>
      RestaurantPostRequest(
        // cusId: json["cus_id"],
        res_name: json["res_name"],
        res_email: json["res_email"],
        res_password: json["res_password"],
        res_phone: json["res_phone"],
        // image: json["image"],
        // balance: json["balance"],
        // activeStatus: json["active_status"],
      );

  Map<String, dynamic> toJson() => {
        // "cus_id": cusId,
        "res_name": res_name,
        "res_email": res_email,
        "res_password": res_password,
        "res_phone": res_phone,
        // "image": image,
        // "balance": balance,
        // "active_status": activeStatus,
      };
}
