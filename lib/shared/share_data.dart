import 'package:flutter/material.dart';

class ShareData with ChangeNotifier {
  //Shared data
  late User_info user_info;
}

class User_info {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int cart_length = 0;
}
