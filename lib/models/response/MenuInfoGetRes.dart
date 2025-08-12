// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

MenuInfoGetResponse MenuInfoGetResponseFromJson(String str) =>
    MenuInfoGetResponse.fromJson(json.decode(str));

class MenuInfoGetResponse {
  int menu_id;
  String menu_name;
  String menu_des;
  String menu_image;
  int menu_price;
  int op_cat_id;
  int cat_id;

  MenuInfoGetResponse({
    required this.menu_id,
    required this.menu_name,
    required this.menu_des,
    required this.menu_image,
    required this.menu_price,
    required this.cat_id,
    required this.op_cat_id,
  });

  factory MenuInfoGetResponse.fromJson(Map<String, dynamic> json) {
    return MenuInfoGetResponse(
      menu_id: json['menu_id'] ?? 0,
      menu_name: json['menu_name'] ?? '',
      menu_des: json['menu_des'] ?? '',
      menu_image: json['menu_image'] ?? '',
      menu_price: json['menu_price'] ?? 0,
      op_cat_id: json['op_cat_id'] ?? 0,
      cat_id: json['cat_id'] ?? 0,
    );
  }
}
