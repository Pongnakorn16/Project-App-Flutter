// To parse this JSON data, do
//
//     final testGetRes = testGetResFromJson(jsonString);

import 'dart:convert';

List<TestGetRes> testGetResFromJson(String str) =>
    List<TestGetRes>.from(json.decode(str).map((x) => TestGetRes.fromJson(x)));

String testGetResToJson(List<TestGetRes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TestGetRes {
  int uid;
  String email;
  String username;
  String password;
  Type type;
  String? bio;
  String? userImage;

  TestGetRes({
    required this.uid,
    required this.email,
    required this.username,
    required this.password,
    required this.type,
    required this.bio,
    required this.userImage,
  });

  factory TestGetRes.fromJson(Map<String, dynamic> json) => TestGetRes(
        uid: json["uid"],
        email: json["email"],
        username: json["username"],
        password: json["password"],
        type: typeValues.map[json["type"]]!,
        bio: json["bio"],
        userImage: json["user_image"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "email": email,
        "username": username,
        "password": password,
        "type": typeValues.reverse[type],
        "bio": bio,
        "user_image": userImage,
      };
}

enum Type { ADMIN, USER }

final typeValues = EnumValues({"Admin": Type.ADMIN, "User": Type.USER});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
