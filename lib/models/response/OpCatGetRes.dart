// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

List<OpCatGetResponse> OpCatGetResponseFromJson(String str) =>
    List<OpCatGetResponse>.from(
      json.decode(str).map((x) => OpCatGetResponse.fromJson(x)),
    );

class OpCatGetResponse {
  int opCatId;
  String opCatName;
  int resId;

  OpCatGetResponse({
    required this.opCatId,
    required this.opCatName,
    required this.resId,
  });

  factory OpCatGetResponse.fromJson(Map<String, dynamic> json) {
    return OpCatGetResponse(
      opCatId: json['op_cat_id'] ?? 0,
      opCatName: json['op_cat_name'] ?? '',
      resId: json['res_id'] ?? 0,
    );
  }
}
