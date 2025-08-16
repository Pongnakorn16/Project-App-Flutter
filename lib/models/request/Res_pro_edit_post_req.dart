import 'dart:convert';

ResProEditPostRequest resProEditPostRequestFromJson(String str) =>
    ResProEditPostRequest.fromJson(json.decode(str));

String resProEditPostRequestToJson(ResProEditPostRequest data) =>
    json.encode(data.toJson());

class ResProEditPostRequest {
  int res_id;
  String res_password;
  String res_phone;
  String res_name;
  String res_image;
  String res_description;
  String res_coordinate;
  String res_opening_time;
  String res_closing_time;

  ResProEditPostRequest({
    required this.res_id,
    required this.res_password,
    required this.res_phone,
    required this.res_name,
    required this.res_image,
    required this.res_description,
    required this.res_coordinate,
    required this.res_opening_time,
    required this.res_closing_time,
  });

  factory ResProEditPostRequest.fromJson(Map<String, dynamic> json) =>
      ResProEditPostRequest(
        res_id: json['res_id'],
        res_password: json['res_password'].toString(),
        res_phone: json['res_phone'],
        res_name: json['res_name'],
        res_image: json['res_image'],
        res_description: json['res_description'],
        res_coordinate: json['res_coordinate'],
        res_opening_time: json['res_opening_time'],
        res_closing_time: json['res_closing_time'],
      );

  Map<String, dynamic> toJson() => {
        'res_id': res_id,
        'res_password': res_password,
        'res_phone': res_phone,
        'res_name': res_name,
        'res_image': res_image,
        'res_description': res_description,
        'res_coordinate': res_coordinate,
        'res_opening_time': res_opening_time,
        'res_closing_time': res_closing_time,
      };
}
