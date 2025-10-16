import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusCartGetRes.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';

class ShareData with ChangeNotifier {
  //Shared data
  int selected_index = 0;
  int selected_ca_id = 0;
  int selected_address_index = 0;
  int res_id = 0;
  int orl_id = 0;
  int Cart_count = 0;
  int Refund_balance = 0;
  String cus_selected_add = "";
  String res_selected_add = "";
  late User_Info_Send user_info_send;
  late User_Info_Receive user_info_receive;
  late ResInfoResponse res_info;
  List<CusAddressGetResponse> customer_addresses = [];
  List<ResTypeGetResponse> restaurant_type = [];
  List<ResInfoResponse> restaurant_near = [];
  List<ResInfoResponse> restaurant_all = [];
  List<MenuInfoGetResponse> all_menu_in_res = [];

  List<GetSendOrder> send_order_share = [];
  List<GetSendOrder> snack_order_share = [];
  List<GetSendOrder> receive_order_share = [];
  List<GetSendOrder> rider_order_share = [];

  StreamSubscription? listener;
  List<CusCartGetResponse> cus_all_cart = [];
}

class User_Info_Send {
  int uid = 0;
  String email = '';
  String name = '';
  String phone = '';
  String user_image = '';
  int balance = 0;
  int active_status = 0;
  String user_type = '';
}

class User_Info_Receive {
  int uid = 0;
  String name = '';
  String user_type = '';
  String user_image = '';
}

class SelectedMenu {
  final int menuId;
  final String menuName;
  final String menuImage;
  final int count;
  final int menuPrice; // เพิ่มตรงนี้
  final List<Map<String, dynamic>> selectedOptions; // เก็บชื่อด้วย

  SelectedMenu({
    required this.menuId,
    required this.menuName,
    required this.menuImage,
    required this.count,
    required this.menuPrice, // เพิ่มใน constructor ด้วย
    required this.selectedOptions,
  });
}
