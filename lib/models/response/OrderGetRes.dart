// To parse this JSON data, do
//
//     final UserRegisterPostRequest = UserRegisterPostRequestFromJson(jsonString);

import 'dart:convert';

// To parse this JSON data
OrderGetResponse OrderGetResponseFromJson(String str) =>
    OrderGetResponse.fromJson(json.decode(str));

String OrderGetResponseToJson(OrderGetResponse data) =>
    json.encode(data.toJson());

class OrderGetResponse {
  int ord_id;
  int cus_id;
  int res_id;
  int rid_id;
  double ord_res_income;
  double ord_rid_income;
  double ord_ad_income;
  String ord_date;
  double ord_dev_price;
  double total_order_price;
  int ord_status;

  OrderGetResponse({
    required this.ord_id,
    required this.cus_id,
    required this.res_id,
    required this.rid_id,
    required this.ord_res_income,
    required this.ord_rid_income,
    required this.ord_ad_income,
    required this.ord_date,
    required this.ord_dev_price,
    required this.total_order_price,
    required this.ord_status,
  });

  factory OrderGetResponse.fromJson(Map<String, dynamic> json) =>
      OrderGetResponse(
        ord_id: json['ord_id'],
        cus_id: json['cus_id'],
        res_id: json['res_id'],
        rid_id: json['rid_id'],
        ord_res_income: (json['ord_res_income'] ?? 0).toDouble(),
        ord_rid_income: (json['ord_rid_income'] ?? 0).toDouble(),
        ord_ad_income: (json['ord_ad_income'] ?? 0).toDouble(),
        ord_date: json['ord_date'],
        ord_dev_price: (json['ord_dev_price'] ?? 0).toDouble(),
        total_order_price: (json['total_order_price'] ?? 0).toDouble(),
        ord_status: json['ord_status'],
      );

  Map<String, dynamic> toJson() => {
        'ord_id': ord_id,
        'cus_id': cus_id,
        'res_id': res_id,
        'rid_id': rid_id,
        'ord_res_income': ord_res_income,
        'ord_rid_income': ord_rid_income,
        'ord_ad_income': ord_ad_income,
        'ord_date': ord_date,
        'ord_dev_price': ord_dev_price,
        'total_order_price': total_order_price,
        'ord_status': ord_status,
      };
}
