// To parse this JSON data, do
//
//     final getSendOrder = getSendOrderFromJson(jsonString);

import 'dart:convert';

List<GetSendOrder> getSendOrderFromJson(String str) => List<GetSendOrder>.from(
    json.decode(str).map((x) => GetSendOrder.fromJson(x)));

String getSendOrderToJson(List<GetSendOrder> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetSendOrder {
  int oid;
  String p_Name;
  String p_Detail;
  int se_Uid;
  int re_Uid;
  int? ri_Uid;
  int dv_Status;

  GetSendOrder({
    required this.oid,
    required this.p_Name,
    required this.p_Detail,
    required this.se_Uid,
    required this.re_Uid,
    required this.ri_Uid,
    required this.dv_Status,
  });

  factory GetSendOrder.fromJson(Map<String, dynamic> json) => GetSendOrder(
        oid: json["oid"],
        p_Name: json["p_name"],
        p_Detail: json["p_detail"],
        se_Uid: json["se_uid"],
        re_Uid: json["re_uid"],
        ri_Uid: json["ri_uid"],
        dv_Status: json["dv_status"],
      );

  Map<String, dynamic> toJson() => {
        "oid": oid,
        "p_name": p_Name,
        "p_detail": p_Detail,
        "se_uid": se_Uid,
        "re_uid": re_Uid,
        "ri_uid": ri_Uid,
        "dv_status": dv_Status,
      };
}
