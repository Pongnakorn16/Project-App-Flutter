// To parse this JSON data, do
//
//     final RiderAddressPostRequest = RiderAddressPostRequestFromJson(jsonString);

import 'dart:convert';

RiderAddressPostRequest RiderAddressPostRequestFromJson(String str) =>
    RiderAddressPostRequest.fromJson(json.decode(str));

String RiderAddressPostRequestToJson(RiderAddressPostRequest data) =>
    json.encode(data.toJson());

class RiderAddressPostRequest {
  String? address;
  String? coordinate;

  RiderAddressPostRequest({
    required this.address,
    required this.coordinate,
  });

  factory RiderAddressPostRequest.fromJson(Map<String, dynamic> json) =>
      RiderAddressPostRequest(
        address: json["Address"],
        coordinate: json["Coordinate"],
      );

  Map<String, dynamic> toJson() => {
        "Address": address,
        "Coordinate": coordinate,
      };
}
