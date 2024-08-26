// To parse this JSON data, do
//
//     final getLotteryNumbers = getLotteryNumbersFromJson(jsonString);

import 'dart:convert';

List<GetLotteryNumbers> getLotteryNumbersFromJson(String str) =>
    List<GetLotteryNumbers>.from(
        json.decode(str).map((x) => GetLotteryNumbers.fromJson(x)));

String getLotteryNumbersToJson(List<GetLotteryNumbers> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class GetLotteryNumbers {
  int lid;
  int numbers;
  int status;

  GetLotteryNumbers({
    required this.lid,
    required this.numbers,
    required this.status,
  });

  factory GetLotteryNumbers.fromJson(Map<String, dynamic> json) =>
      GetLotteryNumbers(
        lid: json["lid"],
        numbers: json["Numbers"],
        status: json["Status"],
      );

  Map<String, dynamic> toJson() => {
        "lid": lid,
        "Numbers": numbers,
        "Status": status,
      };
}
