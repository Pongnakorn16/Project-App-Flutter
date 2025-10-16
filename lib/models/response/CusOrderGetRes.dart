import 'dart:convert';

List<CusOrderGetResponse> CusOrderGetResponseFromJson(String str) =>
    List<CusOrderGetResponse>.from(
        json.decode(str).map((x) => CusOrderGetResponse.fromJson(x)));

class CusOrderGetResponse {
  int ordId;
  int cusId;
  int resId;
  int? ridId;
  double? ordResIncome;
  double? ordRidIncome;
  double? ordAdIncome;
  DateTime ordDate;
  int ordDevPrice;
  int totalOrderPrice;
  int ordStatus;
  List<dynamic> orlOrderDetail;

  CusOrderGetResponse({
    required this.ordId,
    required this.cusId,
    required this.resId,
    this.ridId,
    this.ordResIncome,
    this.ordRidIncome,
    this.ordAdIncome,
    required this.ordDate,
    required this.ordDevPrice,
    required this.totalOrderPrice,
    required this.ordStatus,
    required this.orlOrderDetail,
  });

  factory CusOrderGetResponse.fromJson(Map<String, dynamic> json) =>
      CusOrderGetResponse(
        ordId: json['ord_id'] ?? 0,
        cusId: json['cus_id'] ?? 0,
        resId: json['res_id'] ?? 0,
        ridId: json['rid_id'],
        ordResIncome: json['ord_res_income'] != null
            ? double.tryParse(json['ord_res_income'].toString())
            : null,
        ordRidIncome: json['ord_rid_income'] != null
            ? double.tryParse(json['ord_rid_income'].toString())
            : null,
        ordAdIncome: json['ord_ad_income'] != null
            ? double.tryParse(json['ord_ad_income'].toString())
            : null,
        ordDate: DateTime.parse(json['ord_date']),
        ordDevPrice: json['ord_dev_price'] ?? 0,
        totalOrderPrice: json['total_order_price'] ?? 0,
        ordStatus: json['ord_status'] ?? 0,
        orlOrderDetail: json['orl_order_detail'] != null
            ? List<dynamic>.from(jsonDecode(json['orl_order_detail']))
            : [],
      );
}
