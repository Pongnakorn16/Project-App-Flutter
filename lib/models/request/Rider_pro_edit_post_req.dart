// To parse this JSON data, do
//
//     final UserRegisterPostRequest = UserRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

RiderProEditPostRequest cusProEditPostRequestFromJson(String str) =>
    RiderProEditPostRequest.fromJson(json.decode(str));

String cusProEditPostRequestToJson(RiderProEditPostRequest data) =>
    json.encode(data.toJson());

class RiderProEditPostRequest {
  int rid_id;
  String rid_phone;
  String rid_name;
  String rid_password;
  String rid_license;
  String rid_image;

  RiderProEditPostRequest({
    required this.rid_id,
    required this.rid_phone,
    required this.rid_name,
    required this.rid_password,
    required this.rid_license,
    required this.rid_image,
  });

  factory RiderProEditPostRequest.fromJson(Map<String, dynamic> json) =>
      RiderProEditPostRequest(
        rid_id: json['rid_id'],
        rid_phone: json['cus_phone'],
        rid_name: json['cus_name'],
        rid_password: json['cus_password'],
        rid_license: json['cus_license'],
        rid_image: json['cus_image'],
      );

  Map<String, dynamic> toJson() => {
        'rid_id': rid_id,
        'rid_phone': rid_phone,
        'rid_name': rid_name,
        'rid_password': rid_password,
        'rid_license': rid_license,
        'rid_image': rid_image,
      };
}
