import 'dart:convert';

List<CusReviewGetRespone> CusReviewReportFromJson(String str) =>
    List<CusReviewGetRespone>.from(
        json.decode(str).map((x) => CusReviewGetRespone.fromJson(x)));

class CusReviewGetRespone {
  int resId;
  String resName;
  String resImage;
  int ridId;
  String ridName;
  String ridImage;

  CusReviewGetRespone({
    required this.resId,
    required this.resName,
    required this.resImage,
    required this.ridId,
    required this.ridName,
    required this.ridImage,
  });

  factory CusReviewGetRespone.fromJson(Map<String, dynamic> json) =>
      CusReviewGetRespone(
        resId: json['res_id'] ?? 0,
        resName: json['res_name'] ?? '',
        resImage: json['res_image'] ?? '',
        ridId: json['rid_id'] ?? 0,
        ridName: json['rid_name'] ?? '',
        ridImage: json['rid_image'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'res_id': resId,
        'res_name': resName,
        'res_image': resImage,
        'rid_id': ridId,
        'rid_name': ridName,
        'rid_image': ridImage,
      };
}
