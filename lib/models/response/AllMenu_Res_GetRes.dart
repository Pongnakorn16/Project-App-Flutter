// To parse this JSON data, do
//
//     final menuList = menuInfoGetResponseFromJson(jsonString);

import 'dart:convert';

List<AllMenu_Res_GetResponse> AllMenu_Res_GetResponseFromJson(String str) =>
    List<AllMenu_Res_GetResponse>.from(
        json.decode(str).map((x) => AllMenu_Res_GetResponse.fromJson(x)));

String AllMenu_Res_GetResponseToJson(List<AllMenu_Res_GetResponse> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AllMenu_Res_GetResponse {
  int menu_id;
  String menu_name;
  String menu_des;
  String menu_image;
  int menu_price;
  int menu_status;
  int cat_id;
  String res_name;

  AllMenu_Res_GetResponse({
    this.menu_id = 0,
    this.menu_name = '',
    this.menu_des = '',
    this.menu_image = '',
    this.menu_price = 0,
    this.menu_status = 0,
    this.cat_id = 0,
    this.res_name = '',
  });

  factory AllMenu_Res_GetResponse.fromJson(Map<String, dynamic> json) =>
      AllMenu_Res_GetResponse(
        menu_id: json["menu_id"] ?? 0,
        menu_name: json["menu_name"] ?? '',
        menu_des: json["menu_des"] ?? '',
        menu_image: json["menu_image"] ?? '',
        menu_price: json["menu_price"] ?? 0,
        menu_status: json["menu_status"] ?? 0,
        cat_id: json["cat_id"] ?? 0,
        res_name: json["res_name"] ?? '',
      );

  Map<String, dynamic> toJson() => {
        "menu_id": menu_id,
        "menu_name": menu_name,
        "menu_des": menu_des,
        "menu_image": menu_image,
        "menu_price": menu_price,
        "menu_status": menu_status,
        "cat_id": cat_id,
        "res_name": res_name,
      };
}
