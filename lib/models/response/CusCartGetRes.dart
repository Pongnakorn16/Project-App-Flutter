import 'dart:convert';

CusCartGetResponse CusCartGetResponseFromJson(String str) =>
    CusCartGetResponse.fromJson(json.decode(str));

class CusCartGetResponse {
  int orlId;
  int cusId;
  Map<String, dynamic> orlOrderDetail; // JSON object ของเมนู
  // ถ้าอยากแปลงเป็น List<SelectedMenu> ก็ทำเพิ่มได้

  CusCartGetResponse({
    required this.orlId,
    required this.cusId,
    required this.orlOrderDetail,
  });

  factory CusCartGetResponse.fromJson(Map<String, dynamic> json) {
    return CusCartGetResponse(
      orlId: json['orl_id'] ?? 0,
      cusId: json['cus_id'] ?? 0,
      orlOrderDetail: json['orl_order_detail'] != null
          ? jsonDecode(json['orl_order_detail'])
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        "orl_id": orlId,
        "cus_id": cusId,
        "orl_order_detail": jsonEncode(orlOrderDetail),
      };
}
