// To parse this JSON data, do
//
//     final customersLoginPostRequest = customersLoginPostRequestFromJson(jsonString);

import 'dart:convert';

CustomersLoginPostRequest customersLoginPostRequestFromJson(String str) =>
    CustomersLoginPostRequest.fromJson(json.decode(str));

String customersLoginPostRequestToJson(CustomersLoginPostRequest data) =>
    json.encode(data.toJson());

class CustomersLoginPostRequest {
  String phone;
  String password;

  CustomersLoginPostRequest({
    required this.phone,
    required this.password,
  });

  factory CustomersLoginPostRequest.fromJson(Map<String, dynamic> json) =>
      CustomersLoginPostRequest(
        phone: json["phone"],
        password: json["password"],
      );

  Map<String, dynamic> toJson() => {
        "phone": phone,
        "password": password,
      };
}
