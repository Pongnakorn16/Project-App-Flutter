// To parse this JSON data, do
//
//     final tripIdxGetResponse = tripIdxGetResponseFromJson(jsonString);

import 'dart:convert';

TripIdxGetResponse tripIdxGetResponseFromJson(String str) =>
    TripIdxGetResponse.fromJson(json.decode(str));

String tripIdxGetResponseToJson(TripIdxGetResponse data) =>
    json.encode(data.toJson());

class TripIdxGetResponse {
  int idx;
  String name;
  String country;
  String coverimage;
  String detail;
  int price;
  int duration;
  String destinationZone;

  TripIdxGetResponse({
    required this.idx,
    required this.name,
    required this.country,
    required this.coverimage,
    required this.detail,
    required this.price,
    required this.duration,
    required this.destinationZone,
  });

  factory TripIdxGetResponse.fromJson(Map<String, dynamic> json) =>
      TripIdxGetResponse(
        idx: json["idx"],
        name: json["name"],
        country: json["country"],
        coverimage: json["coverimage"],
        detail: json["detail"],
        price: json["price"],
        duration: json["duration"],
        destinationZone: json["destination_zone"],
      );

  Map<String, dynamic> toJson() => {
        "idx": idx,
        "name": name,
        "country": country,
        "coverimage": coverimage,
        "detail": detail,
        "price": price,
        "duration": duration,
        "destination_zone": destinationZone,
      };
}
