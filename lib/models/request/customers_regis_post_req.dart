// To parse this JSON data, do
//
//     final customersRegisterPostRequest = customersRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

CustomersRegisterPostRequest customersRegisterPostRequestFromJson(String str) =>
    CustomersRegisterPostRequest.fromJson(json.decode(str));

String customersRegisterPostRequestToJson(CustomersRegisterPostRequest data) =>
    json.encode(data.toJson());

class CustomersRegisterPostRequest {
  String email;
  String username;
  String password;
  String image;
  int wallet;

  CustomersRegisterPostRequest(
      {required this.email,
      required this.username,
      required this.password,
      required this.wallet,
      required this.image});

  factory CustomersRegisterPostRequest.fromJson(Map<String, dynamic> json) =>
      CustomersRegisterPostRequest(
        email: json["Email"],
        username: json["Username"],
        password: json["Password"],
        wallet: json["Wallet"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "Email": email,
        "Username": username,
        "Password": password,
        "Wallet": wallet,
        "image": image
      };
}
