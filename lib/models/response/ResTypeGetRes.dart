// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

ResTypeGetResponse ResTypeGetResponseFromJson(String str) =>
    ResTypeGetResponse.fromJson(json.decode(str));

class ResTypeGetResponse {
  int type_id;
  String type_name;
  String type_image;

  ResTypeGetResponse({
    required this.type_id,
    required this.type_name,
    required this.type_image,
  });

  factory ResTypeGetResponse.fromJson(Map<String, dynamic> json) {
    return ResTypeGetResponse(
      type_id: json['type_id'] ?? 0,
      type_name: json['type_name'] ?? 0,
      type_image: json['type_image'] ?? 0,
    );
  }
}
