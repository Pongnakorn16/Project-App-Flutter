// To parse this JSON data, do
//
//     final UserRegisterPostRequest = UserRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

CusProEditPostRequest cusProEditPostRequestFromJson(String str) =>
    CusProEditPostRequest.fromJson(json.decode(str));

String cusProEditPostRequestToJson(CusProEditPostRequest data) =>
    json.encode(data.toJson());

class CusProEditPostRequest {
  int cus_id;
  String cus_phone;
  String cus_name;
  String cus_password;
  String cus_image;
  int ca_id;
  String ca_address;
  String ca_detail;
  String ca_coordinates;

  CusProEditPostRequest({
    required this.cus_id,
    required this.cus_phone,
    required this.cus_name,
    required this.cus_password,
    required this.cus_image,
    required this.ca_id,
    required this.ca_address,
    required this.ca_detail,
    required this.ca_coordinates,
  });

  factory CusProEditPostRequest.fromJson(Map<String, dynamic> json) =>
      CusProEditPostRequest(
        cus_id: json['cus_id'],
        cus_phone: json['cus_phone'],
        cus_name: json['cus_name'],
        cus_password: json['cus_password'],
        cus_image: json['cus_image'],
        ca_id: json['ca_id'],
        ca_address: json['cus_address'],
        ca_detail: json['cus_detail'],
        ca_coordinates: json['cus_coordinates'],
      );

  Map<String, dynamic> toJson() => {
        'cus_id': cus_id,
        'cus_phone': cus_phone,
        'cus_name': cus_name,
        'cus_password': cus_password,
        'cus_image': cus_image,
        'ca_id': ca_id,
        'ca_address': ca_address,
        'ca_detail': ca_detail,
        'ca_coordinates': ca_coordinates,
      };
}
