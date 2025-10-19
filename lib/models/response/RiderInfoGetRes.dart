// To parse this JSON data, do
//
//     final riderList = riderInfoGetResponseFromJson(jsonString);

import 'dart:convert';

List<RiderInfoGetResponse> riderInfoGetResponseFromJson(String str) =>
    List<RiderInfoGetResponse>.from(
        json.decode(str).map((x) => RiderInfoGetResponse.fromJson(x)));

String riderInfoGetResponseToJson(List<RiderInfoGetResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class RiderInfoGetResponse {
  int rid_id;
  String rid_name;
  String rid_email;
  String rid_password;
  String rid_phone;
  String rid_image;
  double rid_balance;
  String rid_address;
  String rid_license;
  int rid_rating;
  int rid_active_status;

  RiderInfoGetResponse({
    this.rid_id = 0,
    this.rid_name = '',
    this.rid_email = '',
    this.rid_password = '',
    this.rid_phone = '',
    this.rid_image = '',
    this.rid_balance = 0.0,
    this.rid_address = '',
    this.rid_license = '',
    this.rid_rating = 0,
    this.rid_active_status = 0,
  });

  factory RiderInfoGetResponse.fromJson(Map<String, dynamic> json) {
    return RiderInfoGetResponse(
      rid_id: json['rid_id'] ?? 0,
      rid_name: json['rid_name'] ?? '',
      rid_email: json['rid_email'] ?? '',
      rid_password: json['rid_password'] ?? '',
      rid_phone: json['rid_phone'] ?? '',
      rid_image: json['rid_image'] ?? '',
      rid_balance: (json['rid_balance'] as num?)?.toDouble() ?? 0.0,
      rid_address: json['rid_address'] ?? '',
      rid_license: json['rid_license'] ?? '',
      rid_rating: json['rid_rating'] ?? 0,
      rid_active_status: json['rid_active_status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'rid_id': rid_id,
        'rid_name': rid_name,
        'rid_email': rid_email,
        'rid_password': rid_password,
        'rid_phone': rid_phone,
        'rid_image': rid_image,
        'rid_balance': rid_balance,
        'rid_address': rid_address,
        'rid_license': rid_license,
        'rid_rating': rid_rating,
        'rid_active_status': rid_active_status,
      };
}
