// To parse this JSON data, do
//
//     final customersLoginPostResponse = customersLoginPostResponseFromJson(jsonString);

import 'dart:convert';

CustomersLoginPostResponse customersLoginPostResponseFromJson(String str) =>
    CustomersLoginPostResponse.fromJson(json.decode(str));

String customersLoginPostResponseToJson(CustomersLoginPostResponse data) =>
    json.encode(data.toJson());

class CustomersLoginPostResponse {
  int uid;
  String email;
  String username;
  String password;
  int wallet;
  int typeId;
  String image;

  CustomersLoginPostResponse({
    required this.uid,
    required this.email,
    required this.username,
    required this.password,
    required this.wallet,
    required this.typeId,
    required this.image,
  });

  factory CustomersLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      CustomersLoginPostResponse(
        uid: json["uid"],
        email: json["Email"],
        username: json["Username"],
        password: json["Password"],
        wallet: json["Wallet"],
        typeId: json["TypeID"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "Email": email,
        "Username": username,
        "Password": password,
        "Wallet": wallet,
        "TypeID": typeId,
        "image": image,
      };
}
