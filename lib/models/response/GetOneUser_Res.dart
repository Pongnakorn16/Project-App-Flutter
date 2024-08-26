// To parse this JSON data, do
//
//     final getOneUserRes = getOneUserResFromJson(jsonString);

import 'dart:convert';

List<GetOneUserRes> getOneUserResFromJson(String str) =>
    List<GetOneUserRes>.from(
        json.decode(str).map((x) => GetOneUserRes.fromJson(x)));

String getOneUserResToJson(List<GetOneUserRes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetOneUserRes {
  int uid;
  String email;
  String username;
  String password;
  int wallet;
  int typeId;
  String image;

  GetOneUserRes({
    required this.uid,
    required this.email,
    required this.username,
    required this.password,
    required this.wallet,
    required this.typeId,
    required this.image,
  });

  factory GetOneUserRes.fromJson(Map<String, dynamic> json) => GetOneUserRes(
        uid: json["uid"],
        email: json["Email"],
        username: json["Username"],
        password: json["Password"],
        wallet: json["Wallet"],
        typeId: json["TypeID"],
        image: json["image"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "Email": email,
        "Username": username,
        "Password": password,
        "Wallet": wallet,
        "TypeID": typeId,
        "image": image,
      };
}
