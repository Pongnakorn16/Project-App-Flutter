import 'dart:convert';

CusCartGetResponse CusCartGetResponseFromJson(String str) =>
    CusCartGetResponse.fromJson(json.decode(str));

class CusCartGetResponse {
  int orlId;
  int cusId;
  List<dynamic> orlOrderDetail;
  String resName;
  String resImage;

  CusCartGetResponse({
    required this.orlId,
    required this.cusId,
    required this.orlOrderDetail,
    required this.resName,
    required this.resImage,
  });

  factory CusCartGetResponse.fromJson(Map<String, dynamic> json) {
    return CusCartGetResponse(
      orlId: json['orl_id'] ?? 0,
      cusId: json['cus_id'] ?? 0,
      orlOrderDetail: json['orl_order_detail'] != null
          ? List<dynamic>.from(jsonDecode(json['orl_order_detail']))
          : [],
      resName: json['res_name'] ?? '',
      resImage: json['res_image'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        "orl_id": orlId,
        "cus_id": cusId,
        "orl_order_detail": jsonEncode(orlOrderDetail),
        "res_name": resName,
        "res_image": resImage,
      };
}
