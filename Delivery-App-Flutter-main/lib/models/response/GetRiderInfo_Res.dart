// To parse this JSON data, do
//
//     final getUserSearchRes = getUserSearchResFromJson(jsonString);

import 'dart:convert';

List<GetRiderInfoRes> getRiderInfoResFromJson(String str) =>
    List<GetRiderInfoRes>.from(
        json.decode(str).map((x) => GetRiderInfoRes.fromJson(x)));

String getRiderInfoResToJson(List<GetRiderInfoRes> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetRiderInfoRes {
  int uid;
  String phone;
  String password;
  String name;
  String userImage;
  String address; // ใช้ String แทน String?
  String coordinates; // ใช้ String แทน String?
  String userType;
  String licensePlate;

  GetRiderInfoRes({
    required this.uid,
    required this.phone,
    required this.password,
    required this.name,
    required this.userImage,
    String? address,
    String? coordinates,
    required this.userType,
    required this.licensePlate,
  })  : this.address = address ?? '', // ใช้ค่าว่างแทนถ้าเป็น null
        this.coordinates = coordinates ?? ''; // ใช้ค่าว่างแทนถ้าเป็น null

  factory GetRiderInfoRes.fromJson(Map<String, dynamic> json) =>
      GetRiderInfoRes(
        uid: json["uid"],
        phone: json["phone"],
        password: json["password"],
        name: json["name"],
        userImage: json["user_image"],
        address: json["address"], // สามารถเป็น null ได้
        coordinates: json["coordinates"], // สามารถเป็น null ได้
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
