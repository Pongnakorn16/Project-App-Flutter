import 'dart:convert';

// ฟังก์ชันแปลง JSON string → List<AddCartPostRequest>
AddCartPostRequest AddCartPostRequestFromJson(String str) =>
    AddCartPostRequest.fromJson(json.decode(str));

String AddCartPostRequestToJson(AddCartPostRequest data) =>
    json.encode(data.toJson());

class AddCartPostRequest {
  final int menuId;
  final String menuName;
  final String menuImage;
  final int count;
  final int menuPrice;
  final List<Map<String, dynamic>> selectedOptions;

  AddCartPostRequest({
    required this.menuId,
    required this.menuName,
    required this.menuImage,
    required this.count,
    required this.menuPrice,
    required this.selectedOptions,
  });

  factory AddCartPostRequest.fromJson(Map<String, dynamic> json) =>
      AddCartPostRequest(
        menuId: json["menu_id"],
        menuName: json["menu_name"],
        menuImage: json["menu_image"],
        count: json["count"],
        menuPrice: json["menu_price"],
        selectedOptions: List<Map<String, dynamic>>.from(
            json["selectedOptions"].map((x) => Map<String, dynamic>.from(x))),
      );

  Map<String, dynamic> toJson() => {
        "menu_id": menuId,
        "menu_name": menuName,
        "menu_image": menuImage,
        "count": count,
        "menu_price": menuPrice,
        "selectedOptions": List<dynamic>.from(selectedOptions.map((x) => x)),
      };
}
