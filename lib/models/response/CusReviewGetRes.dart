import 'dart:convert';

List<CusReviewGetRespone> CusReviewReportFromJson(String str) =>
    List<CusReviewGetRespone>.from(
        json.decode(str).map((x) => CusReviewGetRespone.fromJson(x)));

class CusReviewGetRespone {
  int res_review_status;
  int rid_review_status;
  int res_report_status;
  int rid_report_status;
  int resId;
  String resName;
  String resImage;
  int ridId;
  String ridName;
  String ridImage;

  CusReviewGetRespone({
    required this.res_review_status,
    required this.rid_review_status,
    required this.res_report_status,
    required this.rid_report_status,
    required this.resId,
    required this.resName,
    required this.resImage,
    required this.ridId,
    required this.ridName,
    required this.ridImage,
  });

  factory CusReviewGetRespone.fromJson(Map<String, dynamic> json) =>
      CusReviewGetRespone(
        res_review_status: json['res_review_status'] ?? 0,
        rid_review_status: json['rid_review_status'] ?? 0,
        res_report_status: json['res_report_status'] ?? 0,
        rid_report_status: json['rid_report_status'] ?? 0,
        resId: json['res_id'] ?? 0,
        resName: json['res_name'] ?? '',
        resImage: json['res_image'] ?? '',
        ridId: json['rid_id'] ?? 0,
        ridName: json['rid_name'] ?? '',
        ridImage: json['rid_image'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'res_review_status': res_review_status,
        'rid_review_status': rid_review_status,
        'res_report_status': res_report_status,
        'rid_report_status': rid_report_status,
        'res_id': resId,
        'res_name': resName,
        'res_image': resImage,
        'rid_id': ridId,
        'rid_name': ridName,
        'rid_image': ridImage,
      };
}
