// To parse this JSON data, do
//
//     final tripsGetRespones = tripsGetResponesFromJson(jsonString);

import 'dart:convert';

List<TripsGetRespones> tripsGetResponesFromJson(String str) =>
    List<TripsGetRespones>.from(
        json.decode(str).map((x) => TripsGetRespones.fromJson(x)));

String tripsGetResponesToJson(List<TripsGetRespones> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class TripsGetRespones {
  int idx;
  String name;
  String country;
  String coverimage;
  String detail;
  int price;
  int duration;
  DestinationZone destinationZone;

  TripsGetRespones({
    required this.idx,
    required this.name,
    required this.country,
    required this.coverimage,
    required this.detail,
    required this.price,
    required this.duration,
    required this.destinationZone,
  });

  factory TripsGetRespones.fromJson(Map<String, dynamic> json) =>
      TripsGetRespones(
        idx: json["idx"],
        name: json["name"],
        country: json["country"],
        coverimage: json["coverimage"],
        detail: json["detail"],
        price: json["price"],
        duration: json["duration"],
        destinationZone: destinationZoneValues.map[json["destination_zone"]]!,
      );

  Map<String, dynamic> toJson() => {
        "idx": idx,
        "name": name,
        "country": country,
        "coverimage": coverimage,
        "detail": detail,
        "price": price,
        "duration": duration,
        "destination_zone": destinationZoneValues.reverse[destinationZone],
      };
}

enum DestinationZone { DESTINATION_ZONE, EMPTY, FLUFFY, PURPLE }

final destinationZoneValues = EnumValues({
  "เอเชียตะวันออกเฉียงใต้": DestinationZone.DESTINATION_ZONE,
  "ยุโรป": DestinationZone.EMPTY,
  "ประเทศไทย": DestinationZone.FLUFFY,
  "เอเชีย": DestinationZone.PURPLE
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
