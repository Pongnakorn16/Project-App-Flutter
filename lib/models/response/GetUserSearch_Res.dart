// To parse this JSON data, do
//
//     final getUserSearchRes = getUserSearchResFromJson(jsonString);

import 'dart:convert';

List<GetUserSearchRes> getUserSearchResFromJson(String str) =>
    List<GetUserSearchRes>.from(
        json.decode(str).map((x) => GetUserSearchRes.fromJson(x)));

String getUserSearchResToJson(List<GetUserSearchRes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetUserSearchRes {
  int uid;
  String phone;
  String password;
  String name;
  String userImage;
  String address;
  String? coordinates;
  String userType;
  String? licensePlate;

  GetUserSearchRes({
    required this.uid,
    required this.phone,
    required this.password,
    required this.name,
    required this.userImage,
    required this.address,
    required this.coordinates,
    required this.userType,
    required this.licensePlate,
  });

  factory GetUserSearchRes.fromJson(Map<String, dynamic> json) =>
      GetUserSearchRes(
        uid: json["uid"],
        phone: json["phone"],
        password: json["password"],
        name: json["name"],
        userImage: json["user_image"],
        address: json["address"],
        coordinates: json["coordinates"],
        userType: json["user_type"],
        licensePlate: json["license_plate"],
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "phone": phone,
        "password": password,
        "name": name,
        "user_image": userImage,
        "address": address,
        "coordinates": coordinates,
        "user_type": userType,
        "license_plate": licensePlate,
      };
}
