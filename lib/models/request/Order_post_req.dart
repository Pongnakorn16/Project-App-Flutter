// To parse this JSON data, do
//
//     final UserRegisterPostRequest = UserRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

import 'package:intl/intl.dart';

// To parse this JSON data
OrderPostRequest OrderPostRequestFromJson(String str) =>
    OrderPostRequest.fromJson(json.decode(str));

String OrderPostRequestToJson(OrderPostRequest data) =>
    json.encode(data.toJson());

class OrderPostRequest {
  int cus_id;
  int res_id;
  String ord_date;
  int ord_dev_price;
  int total_order_price;
  int ord_status;

  OrderPostRequest({
    required this.cus_id,
    required this.res_id,
    required this.ord_date,
    required this.ord_dev_price,
    required this.total_order_price,
    required this.ord_status,
  });

  factory OrderPostRequest.fromJson(Map<String, dynamic> json) =>
      OrderPostRequest(
        cus_id: json['cus_id'],
        res_id: json['res_id'],
        ord_date: json['ord_date'],
        ord_dev_price: (json['ord_dev_price'] ?? 0),
        total_order_price: (json['total_order_price'] ?? 0),
        ord_status: json['ord_status'],
      );

  Map<String, dynamic> toJson() => {
        'cus_id': cus_id,
        'res_id': res_id,
        'ord_date': ord_date,
        'ord_dev_price': ord_dev_price,
        'total_order_price': total_order_price,
        'ord_status': ord_status,
      };
}
