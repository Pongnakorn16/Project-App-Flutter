// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

ResCatGetResponse ResTypeGetResponseFromJson(String str) =>
    ResCatGetResponse.fromJson(json.decode(str));

class ResCatGetResponse {
  int cat_id;
  String cat_name;
  int res_id;

  ResCatGetResponse({
    required this.cat_id,
    required this.cat_name,
    required this.res_id,
  });

  factory ResCatGetResponse.fromJson(Map<String, dynamic> json) {
    return ResCatGetResponse(
      cat_id: json['cat_id'] ?? 0,
      cat_name: json['cat_name'] ?? 0,
      res_id: json['res_id'] ?? 0,
    );
  }
}
