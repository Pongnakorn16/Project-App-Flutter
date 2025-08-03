// To parse this JSON data, do
//
//     final UserLoginPostResponse = UserLoginPostResponseFromJson(jsonString);

import 'dart:convert';

OptionGetResponse optionGetResponseFromJson(String str) =>
    OptionGetResponse.fromJson(json.decode(str));

class OptionGetResponse {
  List<Category> categories;
  List<Option> options;

  OptionGetResponse({
    required this.categories,
    required this.options,
  });

  factory OptionGetResponse.fromJson(Map<String, dynamic> json) {
    return OptionGetResponse(
      categories: List<Category>.from(
          json["categories"].map((x) => Category.fromJson(x))),
      options:
          List<Option>.from(json["options"].map((x) => Option.fromJson(x))),
    );
  }
}

class Category {
  int opCatId;
  String opCatName;

  Category({
    required this.opCatId,
    required this.opCatName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      opCatId: json["op_cat_id"] ?? 0,
      opCatName: json["op_cat_name"] ?? '',
    );
  }
}

class Option {
  int opId;
  String opName;
  int opPrice;
  int opCatId;

  Option({
    required this.opId,
    required this.opName,
    required this.opPrice,
    required this.opCatId,
  });

  factory Option.fromJson(Map<String, dynamic> json) {
    return Option(
      opId: json["op_id"] ?? 0,
      opName: json["op_name"] ?? '',
      opPrice: json["op_price"] ?? 0,
      opCatId: json["op_cat_id"] ?? 0,
    );
  }
}
