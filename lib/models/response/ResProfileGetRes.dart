import 'dart:convert';

ResProfileGetResponse resProfileGetResponseFromJson(String str) =>
    ResProfileGetResponse.fromJson(json.decode(str));

String resProfileGetResponseToJson(ResProfileGetResponse data) =>
    json.encode(data.toJson());

class ResProfileGetResponse {
  int res_id;
  String res_name;
  String res_email;
  String res_password;
  String res_phone;
  String res_image;
  String res_description;
  String res_coordinate;
  String res_opening_time;
  String res_closing_time;
  double res_rating;
  int res_balance;
  int res_active_status;

  ResProfileGetResponse({
    this.res_id = 0,
    this.res_name = '',
    this.res_email = '',
    this.res_password = '',
    this.res_phone = '',
    this.res_image = '',
    this.res_description = '',
    this.res_coordinate = '',
    this.res_opening_time = '',
    this.res_closing_time = '',
    this.res_rating = 0.0,
    this.res_balance = 0,
    this.res_active_status = 0,
  });

  factory ResProfileGetResponse.fromJson(Map<String, dynamic> json) {
    return ResProfileGetResponse(
      res_id: json['res_id'] ?? 0,
      res_name: json['res_name'] ?? '',
      res_email: json['res_email'] ?? '',
      res_password: json['res_password'].toString(),
      res_phone: json['res_phone'] ?? '',
      res_image: json['res_image'] ?? '',
      res_description: json['res_description'] ?? '',
      res_coordinate: json['res_coordinate'] ?? '',
      res_opening_time: json['res_opening_time'] ?? '',
      res_closing_time: json['res_closing_time'] ?? '',
      res_rating: (json['res_rating'] != null)
          ? double.tryParse(json['res_rating'].toString()) ?? 0.0
          : 0.0,
      res_balance: json['res_balance'] ?? 0,
      res_active_status: json['res_active_status'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'res_id': res_id,
        'res_name': res_name,
        'res_email': res_email,
        'res_password': res_password,
        'res_phone': res_phone,
        'res_image': res_image,
        'res_description': res_description,
        'res_coordinate': res_coordinate,
        'res_opening_time': res_opening_time,
        'res_closing_time': res_closing_time,
        'res_rating': res_rating,
        'res_balance': res_balance,
        'res_active_status': res_active_status,
      };
}
