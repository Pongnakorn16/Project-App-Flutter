// To parse this JSON data, do
//
//     final customersLoginPostResponse = customersLoginPostResponseFromJson(jsonString);

import 'dart:convert';

CustomersLoginPostResponse customersLoginPostResponseFromJson(String str) =>
    CustomersLoginPostResponse.fromJson(json.decode(str));

String customersLoginPostResponseToJson(CustomersLoginPostResponse data) =>
    json.encode(data.toJson());

class CustomersLoginPostResponse {
  String message;
  Customer customer;

  CustomersLoginPostResponse({
    required this.message,
    required this.customer,
  });

  factory CustomersLoginPostResponse.fromJson(Map<String, dynamic> json) =>
      CustomersLoginPostResponse(
        message: json["message"],
        customer: Customer.fromJson(json["customer"]),
      );

  Map<String, dynamic> toJson() => {
        "message": message,
        "customer": customer.toJson(),
      };
}

class Customer {
  int idx;
  String fullname;
  String phone;
  String email;
  String image;

  Customer({
    required this.idx,
    required this.fullname,
    required this.phone,
    required this.email,
    required this.image,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        idx: json["idx"],
        fullname: json["fullname"],
        phone: json["phone"],
        email: json["email"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "idx": idx,
        "fullname": fullname,
        "phone": phone,
        "email": email,
        "image": image,
      };
}
