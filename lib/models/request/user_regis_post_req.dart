// To parse this JSON data, do
//
//     final UserRegisterPostRequest = UserRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

UserRegisterPostRequest UserRegisterPostRequestFromJson(String str) =>
    UserRegisterPostRequest.fromJson(json.decode(str));

String UserRegisterPostRequestToJson(UserRegisterPostRequest data) =>
    json.encode(data.toJson());

class UserRegisterPostRequest {
  String phone;
  String name;
  String password;
  String? address;
  String? coordinate;
  String user_image;
  String user_type;
  String? license_plate;

  UserRegisterPostRequest({
    required this.phone,
    required this.name,
    required this.password,
    required this.address,
    required this.coordinate,
    required this.user_image,
    required this.user_type,
    required this.license_plate,
  });

  factory UserRegisterPostRequest.fromJson(Map<String, dynamic> json) =>
      UserRegisterPostRequest(
        phone: json["Phone"],
        name: json["Name"],
        password: json["Password"],
        user_image: json["User_image"],
        address: json["Address"],
        coordinate: json["Coordinate"],
        user_type: json["User_type"],
        license_plate: json["license_plate"],
      );

  Map<String, dynamic> toJson() => {
        "Phone": phone,
        "Name": name,
        "Password": password,
        "User_image": user_image,
        "Address": address,
        "Coordinate": coordinate,
        "User_type": user_type,
        "License_plate": license_plate,
      };
}
