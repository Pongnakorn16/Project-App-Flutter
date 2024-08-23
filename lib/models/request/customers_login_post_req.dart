// To parse this JSON data, do
//
//     final customersLoginPostRequest = customersLoginPostRequestFromJson(jsonString);

import 'dart:convert';

CustomersLoginPostRequest customersLoginPostRequestFromJson(String str) =>
    CustomersLoginPostRequest.fromJson(json.decode(str));

String customersLoginPostRequestToJson(CustomersLoginPostRequest data) =>
    json.encode(data.toJson());

class CustomersLoginPostRequest {
  String Email;
  String Password;

  CustomersLoginPostRequest({
    required this.Email,
    required this.Password,
  });

  factory CustomersLoginPostRequest.fromJson(Map<String, dynamic> json) =>
      CustomersLoginPostRequest(
        Email: json["Email"],
        Password: json["Password"],
      );

  Map<String, dynamic> toJson() => {
        "Email": Email,
        "Password": Password,
      };
}
