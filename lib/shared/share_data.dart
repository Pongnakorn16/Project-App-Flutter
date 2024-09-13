import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';

class ShareData with ChangeNotifier {
  //Shared data
  int check_prizeOut = 3;
  late User_info user_info;

  List<GetLotteryNumbers> winlotto = [];
}

class User_info {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int cart_length = 0;
}
