// To parse this JSON data, do
//
//     final getNewOidRes = getNewOidResFromJson(jsonString);

import 'dart:convert';

GetNewOidRes getNewOidResFromJson(String str) =>
    GetNewOidRes.fromJson(json.decode(str));

String getNewOidResToJson(GetNewOidRes data) => json.encode(data.toJson());

class GetNewOidRes {
  int oid;

  GetNewOidRes({
    required this.oid,
  });

  factory GetNewOidRes.fromJson(Map<String, dynamic> json) => GetNewOidRes(
        oid: json["oid"],
      );

  Map<String, dynamic> toJson() => {
        "oid": oid,
      };
}
