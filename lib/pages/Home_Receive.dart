import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:provider/provider.dart';
import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';

class Home_ReceivePage extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onClose;
  Home_ReceivePage(
      {Key? key, required this.onClose, required this.selectedIndex})
      : super(key: key);

  @override
  State<Home_ReceivePage> createState() => _Home_ReceivePageState();
}

class _Home_ReceivePageState extends State<Home_ReceivePage>
    with SingleTickerProviderStateMixin {
  List<GetLotteryNumbers> winlotto = [];
  int uid = 0;
  String username = '';
  int wallet = 0;
  int cart_length = 0;
  GetStorage gs = GetStorage();
  String url = '';
  List<GetCartRes> all_cart = [];
  List<GetLotteryNumbers> win_lotterys = [];
  late Future<void> loadData;
  int _selectedIndex = 0;
  bool _showReceivePage = false;
  late AnimationController _animationController;
  late Animation<Offset> _pageSlideAnimation;

  @override
  void initState() {
    super.initState();
    uid = context.read<ShareData>().user_info_send.uid;
    username = context.read<ShareData>().user_info_send.name;
    _selectedIndex = widget.selectedIndex;
    loadData = loadDataAsync();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _pageSlideAnimation = Tween<Offset>(
      begin: Offset(
          -1.0, 0.0), // เปลี่ยนจาก 1.0 เป็น -1.0 เพื่อให้ slide จากซ้ายไปขวา
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: FutureBuilder(
                      future: loadData,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return SingleChildScrollView(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (context
                                      .read<ShareData>()
                                      .winlotto
                                      .isEmpty)
                                    const Center(
                                      child: Text(
                                        "Please press the Add button below to include the items you wish to ship.",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  else
                                    ...context
                                        .read<ShareData>()
                                        .winlotto
                                        .map((lottery) =>
                                            buildLotteryItem(lottery))
                                        .toList(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Swipeable indicator
          Positioned(
            left: -80, // Move it slightly off-screen
            top: 0,
            bottom: 0,
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 10) {
                  // เปลี่ยนเงื่อนไขให้ตรวจจับการปัดจากซ้ายไปขวา
                  setState(() {
                    _showReceivePage = true;
                  });
                  _animationController.forward();
                }
              },
              child: Container(
                width: 120, // กำหนดความกว้าง
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 222, 78), // สีพื้นหลัง
                  shape: BoxShape.circle, // ทำให้เป็นวงกลม
                ),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 9,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 70),
                      child: Text(
                        'Send',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLotteryItem(GetLotteryNumbers lottery) {
    List<String> numberList = lottery.numbers.toString().split('');
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            buildPrizeStatus(lottery.status_prize),
            buildPrizeAmount(lottery.status_prize),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: IntrinsicWidth(
            child: Card(
              color: const Color.fromARGB(255, 254, 137, 69),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: numberList
                        .map((number) => buildNumberCard(number))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget buildPrizeStatus(int status_prize) {
    String status;
    double fontSize;
    Icon? icon;
    Color textColor = Colors.black;
    Color iconColor = Colors.black;

    if (status_prize == 1) {
      status = 'st';
      fontSize = 21;
      iconColor = Colors.blue;
      icon = Icon(Icons.local_fire_department, color: iconColor, size: 40);
      textColor = Colors.blue;
    } else if (status_prize == 2) {
      status = 'nd';
      fontSize = 19;
    } else if (status_prize == 3) {
      status = 'rd';
      fontSize = 17;
    } else if (status_prize >= 4) {
      status = 'th';
      fontSize = 15;
    } else {
      status = 'unknown';
      fontSize = 15;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "${status_prize}${status}",
          style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: textColor),
        ),
        if (icon != null)
          Padding(padding: const EdgeInsets.only(right: 8.0), child: icon),
      ],
    );
  }

  Widget buildPrizeAmount(int status_prize) {
    String prize;
    if (status_prize == 1) {
      prize = '10,000';
    } else if (status_prize == 2) {
      prize = '5,000';
    } else if (status_prize == 3) {
      prize = '1,000';
    } else if (status_prize == 4) {
      prize = '500';
    } else if (status_prize == 5) {
      prize = '150';
    } else {
      prize = 'unknown';
    }

    return Text(
      "เงินรางวัล $prize บาท",
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
    );
  }

  Widget buildNumberCard(String number) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: Card(
        color: const Color.fromARGB(255, 255, 255, 255),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 2),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];
    log(url);

    var response = await http.get(Uri.parse("$url/db/get_WinLottery"));
    if (response.statusCode == 200) {
      win_lotterys = getLotteryNumbersFromJson(response.body);
      if (context.read<ShareData>().winlotto.isEmpty) {
        context.read<ShareData>().winlotto = win_lotterys;
      }
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
    }

    var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
    if (get_cart.statusCode == 200) {
      all_cart = getCartResFromJson(get_cart.body);
      context.read<ShareData>().user_info.cart_length = all_cart.length;
    } else {
      log('Failed to load cart. Status code: ${get_cart.statusCode}');
    }
  }
}
