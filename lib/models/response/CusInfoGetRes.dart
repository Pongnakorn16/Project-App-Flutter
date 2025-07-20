// To parse this JSON data, do
//
//     final user = cusInfoGetResponseFromJson(jsonString);

import 'dart:convert';

CusInfoGetResponse cusInfoGetResponseFromJson(String str) =>
    CusInfoGetResponse.fromJson(json.decode(str));

String cusInfoGetResponseToJson(CusInfoGetResponse data) =>
    json.encode(data.toJson());

class CusInfoGetResponse {
  int cus_id;
  String cus_name;
  String cus_email;
  String cus_password;
  String cus_phone;
  String cus_image;
  int cus_balance;
  int cus_active_status;

  CusInfoGetResponse({
    this.cus_id = 0,
    this.cus_name = '',
    this.cus_email = '',
    this.cus_password = '',
    this.cus_phone = '',
    this.cus_image = '',
    this.cus_balance = 0,
    this.cus_active_status = 0,
  });

  factory CusInfoGetResponse.fromJson(Map<String, dynamic> json) {
    return CusInfoGetResponse(
      cus_id: json['cus_id'] ?? 0,
      cus_name: json['cus_name'] ?? '',
      cus_email: json['cus_email'] ?? '',
      cus_password: json['cus_password'] ?? '',
      cus_phone: json['cus_phone'] ?? '',
      cus_image: json['cus_image'] ?? '',
      cus_balance: json['cus_balance'] ?? 0,
      cus_active_status: json['cus_active_status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'cus_id': cus_id,
        'cus_name': cus_name,
        'cus_email': cus_email,
        'cus_password': cus_password,
        'cus_phone': cus_phone,
        'cus_image': cus_image,
        'cus_balance': cus_balance,
        'cus_active_status': cus_active_status,
      };
}
