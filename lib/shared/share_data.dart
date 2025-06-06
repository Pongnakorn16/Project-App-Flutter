import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/models/response/GetSendOrder_Res.dart';

class ShareData with ChangeNotifier {
  //Shared data
  int check_prizeOut = 1;

  late User_Info_Send user_info_send;
  late User_Info_Receive user_info_receive;

  List<GetSendOrder> send_order_share = [];
  List<GetSendOrder> snack_order_share = [];
  List<GetSendOrder> receive_order_share = [];
  List<GetSendOrder> rider_order_share = [];

  StreamSubscription? listener;
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
