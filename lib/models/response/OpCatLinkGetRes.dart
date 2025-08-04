// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

OpCatLinkGetResponse OpCatLinkGetResponseFromJson(String str) =>
    OpCatLinkGetResponse.fromJson(json.decode(str));

class OpCatLinkGetResponse {
  int op_cat_link_id;
  int op_cat_id;
  int menu_id;

  OpCatLinkGetResponse({
    required this.op_cat_link_id,
    required this.op_cat_id,
    required this.menu_id,
  });

  factory OpCatLinkGetResponse.fromJson(Map<String, dynamic> json) {
    return OpCatLinkGetResponse(
      op_cat_link_id: json['op_cat_link_id'] ?? 0,
      op_cat_id: json['op_cat_id'] ?? 0,
      menu_id: json['menu_id'] ?? 0,
    );
  }
}
