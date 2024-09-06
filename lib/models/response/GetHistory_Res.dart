// To parse this JSON data, do
//
//     final getHistoryRes = getHistoryResFromJson(jsonString);

import 'dart:convert';

List<GetHistoryRes> getHistoryResFromJson(String str) =>
    List<GetHistoryRes>.from(
        json.decode(str).map((x) => GetHistoryRes.fromJson(x)));

String getHistoryResToJson(List<GetHistoryRes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetHistoryRes {
  int hid;
  int hLid;
  String hNumber;
  int hUid;
  int hWallet;

  GetHistoryRes({
    required this.hid,
    required this.hLid,
    required this.hNumber,
    required this.hUid,
    required this.hWallet,
  });

  factory GetHistoryRes.fromJson(Map<String, dynamic> json) => GetHistoryRes(
        hid: json["hid"],
        hLid: json["h_lid"],
        hNumber: json["h_number"],
        hUid: json["h_uid"],
        hWallet: json["h_wallet"],
      );

  Map<String, dynamic> toJson() => {
        "hid": hid,
        "h_lid": hLid,
        "h_number": hNumber,
        "h_uid": hUid,
        "h_wallet": hWallet,
      };
}
