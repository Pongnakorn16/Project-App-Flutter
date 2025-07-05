// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

CusAddressGetResponse CusAddressGetResponseFromJson(String str) =>
    CusAddressGetResponse.fromJson(json.decode(str));

class CusAddressGetResponse {
  int ca_id;
  int ca_cus_id;
  String ca_coordinate;
  String ca_address;
  String ca_detail;

  CusAddressGetResponse({
    this.ca_id = 0,
    this.ca_cus_id = 0,
    this.ca_coordinate = '',
    this.ca_address = '',
    this.ca_detail = '',
  });

  factory CusAddressGetResponse.fromJson(Map<String, dynamic> json) {
    return CusAddressGetResponse(
      ca_id: json['ca_id'] ?? 0,
      ca_cus_id: json['ca_cus_id'] ?? 0,
      ca_coordinate: json['ca_coordinate'] ?? '',
      ca_address: json['ca_address'] ?? '',
      ca_detail: json['ca_detail'] ?? '',
    );
  }
}
