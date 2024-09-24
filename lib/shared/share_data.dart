import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';

class ShareData with ChangeNotifier {
  //Shared data
  int check_prizeOut = 1;
  late User_info user_info;
  late User_Info user_Info;

  List<GetLotteryNumbers> winlotto = [];
}

class User_info {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int cart_length = 0;
}

class User_Info {
  int uid = 0;
  String name = '';
  String user_type = '';
}
