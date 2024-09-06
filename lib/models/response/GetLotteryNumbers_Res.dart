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
  String numbers;
  int status_prize;
  int status_buy;

  GetLotteryNumbers({
    required this.lid,
    required this.numbers,
    required this.status_prize,
    required this.status_buy,
  });

  factory GetLotteryNumbers.fromJson(Map<String, dynamic> json) =>
      GetLotteryNumbers(
        lid: json["lid"],
        numbers: json["Numbers"],
        status_prize: json["Status_prize"],
        status_buy: json["Status_buy"],
      );

  Map<String, dynamic> toJson() => {
        "lid": lid,
        "Numbers": numbers,
        "Status_prize": status_prize,
        "Status_buy": status_buy,
      };
}
