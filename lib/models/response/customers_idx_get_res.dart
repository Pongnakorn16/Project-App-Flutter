// To parse this JSON data, do
//
//     final customersIdxGetResponse = customersIdxGetResponseFromJson(jsonString);

import 'dart:convert';

CustomersIdxGetResponse customersIdxGetResponseFromJson(String str) =>
    CustomersIdxGetResponse.fromJson(json.decode(str));

String customersIdxGetResponseToJson(CustomersIdxGetResponse data) =>
    json.encode(data.toJson());

class CustomersIdxGetResponse {
  int idx;
  String fullname;
  String phone;
  String email;
  String image;

  CustomersIdxGetResponse({
    required this.idx,
    required this.fullname,
    required this.phone,
    required this.email,
    required this.image,
  });

  factory CustomersIdxGetResponse.fromJson(Map<String, dynamic> json) =>
      CustomersIdxGetResponse(
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
