import 'dart:convert';

List<ReportTopicGetRespone> ReportTopicGetResponeFromJson(String str) =>
    List<ReportTopicGetRespone>.from(
        json.decode(str).map((x) => ReportTopicGetRespone.fromJson(x)));

String ReportTopicGetResponeToJson(List<ReportTopicGetRespone> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class ReportTopicGetRespone {
  int reptId;
  String reptTopic;

  ReportTopicGetRespone({
    required this.reptId,
    required this.reptTopic,
  });

  factory ReportTopicGetRespone.fromJson(Map<String, dynamic> json) =>
      ReportTopicGetRespone(
        reptId: json['rept_id'] ?? 0,
        reptTopic: json['rept_topic'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'rept_id': reptId,
        'rept_topic': reptTopic,
      };
}
