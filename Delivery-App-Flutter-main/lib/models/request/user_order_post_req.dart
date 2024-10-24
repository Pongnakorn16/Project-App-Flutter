// To parse this JSON data, do
//
//     final userOrderPostReq = userOrderPostReqFromJson(jsonString);

import 'dart:convert';

UserOrderPostReq userOrderPostReqFromJson(String str) =>
    UserOrderPostReq.fromJson(json.decode(str));

String userOrderPostReqToJson(UserOrderPostReq data) =>
    json.encode(data.toJson());

class UserOrderPostReq {
  String p_Name;
  String p_Detail;
  int se_Uid;
  int re_Uid;
  int? ri_Uid;
  int dv_Status;

  UserOrderPostReq({
    required this.p_Name,
    required this.p_Detail,
    required this.se_Uid,
    required this.re_Uid,
    required this.ri_Uid,
    required this.dv_Status,
  });

  factory UserOrderPostReq.fromJson(Map<String, dynamic> json) =>
      UserOrderPostReq(
        p_Name: json["p_name"],
        p_Detail: json["p_detail"],
        se_Uid: json["se_uid"],
        re_Uid: json["re_uid"],
        ri_Uid: json["ri_uid"],
        dv_Status: json["dv_status"],
      );

  Map<String, dynamic> toJson() => {
        "p_name": p_Name,
        "p_detail": p_Detail,
        "se_uid": se_Uid,
        "re_uid": re_Uid,
        "ri_uid": ri_Uid,
        "dv_status": dv_Status,
      };
}
