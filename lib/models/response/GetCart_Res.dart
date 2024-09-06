// To parse this JSON data, do
//
//     final getCartRes = getCartResFromJson(jsonString);

import 'dart:convert';

List<GetCartRes> getCartResFromJson(String str) =>
    List<GetCartRes>.from(json.decode(str).map((x) => GetCartRes.fromJson(x)));

String getCartResToJson(List<GetCartRes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetCartRes {
  int cid;
  int cLid;
  int cUid;
  int lid;
  String numbers;
  int statusPrize;
  int statusBuy;
  dynamic ownerUid;

  GetCartRes({
    required this.cid,
    required this.cLid,
    required this.cUid,
    required this.lid,
    required this.numbers,
    required this.statusPrize,
    required this.statusBuy,
    required this.ownerUid,
  });

  factory GetCartRes.fromJson(Map<String, dynamic> json) => GetCartRes(
        cid: json["cid"],
        cLid: json["c_lid"],
        cUid: json["c_uid"],
        lid: json["lid"],
        numbers: json["Numbers"],
        statusPrize: json["Status_prize"],
        statusBuy: json["Status_buy"],
        ownerUid: json["Owner_uid"],
      );

  Map<String, dynamic> toJson() => {
        "cid": cid,
        "c_lid": cLid,
        "c_uid": cUid,
        "lid": lid,
        "Numbers": numbers,
        "Status_prize": statusPrize,
        "Status_buy": statusBuy,
        "Owner_uid": ownerUid,
      };
}
