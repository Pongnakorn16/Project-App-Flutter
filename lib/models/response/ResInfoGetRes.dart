// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

ResInfoResponse ResInfoResponseFromJson(String str) =>
    ResInfoResponse.fromJson(json.decode(str));

class ResInfoResponse {
  int res_id;
  String res_email;
  int res_password;
  String res_phone;
  String res_name;
  String res_image;
  String res_discription;
  String res_coordinate;
  String res_opening_time;
  String res_closing_time;
  int res_type_id;
  int res_rating;
  int res_balance;
  int res_active_status;
  double? distanceFromCustomer;

  ResInfoResponse({
    required this.res_id,
    required this.res_email,
    required this.res_password,
    required this.res_phone,
    required this.res_name,
    required this.res_image,
    required this.res_discription,
    required this.res_coordinate,
    required this.res_opening_time,
    required this.res_closing_time,
    required this.res_type_id,
    required this.res_rating,
    required this.res_balance,
    required this.res_active_status,
    this.distanceFromCustomer,
  });

  factory ResInfoResponse.fromJson(Map<String, dynamic> json) {
    return ResInfoResponse(
      res_id: json['res_id'] ?? 0,
      res_email: json['res_email'] ?? '',
      res_password: json['res_password'] ?? 0,
      res_phone: json['res_phone'] ?? '',
      res_name: json['res_name'] ?? '',
      res_image: json['res_image'] ?? '',
      res_discription: json['res_discription'] ?? '',
      res_coordinate: json['res_coordinate'] ?? '',
      res_opening_time: json['res_opening_time'] ?? '',
      res_closing_time: json['res_closing_time'] ?? '',
      res_type_id: json['res_type_id'] ?? 0,
      res_rating: json['res_rating'] ?? 0,
      res_balance: json['res_balance'] ?? 0,
      res_active_status: json['res_active_status'] ?? 0,
    );
  }
}
