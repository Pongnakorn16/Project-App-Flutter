// To parse this JSON data, do
//
//     final cartPostRequest = cartPostRequestFromJson(jsonString);

import 'dart:convert';

CartPostRequest cartPostRequestFromJson(String str) =>
    CartPostRequest.fromJson(json.decode(str));

String cartPostRequestToJson(CartPostRequest data) =>
    json.encode(data.toJson());

class CartPostRequest {
  int cLid;
  int cUid;

  CartPostRequest({
    required this.cLid,
    required this.cUid,
  });

  factory CartPostRequest.fromJson(Map<String, dynamic> json) =>
      CartPostRequest(
        cLid: json["c_lid"],
        cUid: json["c_uid"],
      );

  Map<String, dynamic> toJson() => {
        "c_lid": cLid,
        "c_uid": cUid,
      };
}
