import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/pages/Profile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int selectedIndex = 0;
  HomePage({super.key, required this.selectedIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  @override
  void initState() {
    uid = context.read<ShareData>().user_info.uid;
    username = context.read<ShareData>().user_info.username;
    wallet = context.read<ShareData>().user_info.wallet;
    cart_length = context.read<ShareData>().user_info.cart_length;
    super.initState();
    _selectedIndex = widget.selectedIndex;
    loadData = loadDataAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: RichText(
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Welcome ',
                      style: TextStyle(
                          fontSize: 20,
                          color: Colors.black), // สีของข้อความที่เหลือ
                    ),
                    TextSpan(
                      text: username,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 1.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    size: 20,
                    color: Color.fromARGB(255, 254, 137, 69),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Wallet :  ${wallet}  THB',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color.fromARGB(255, 131, 130, 130),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.only(top: 20, bottom: 25.0, left: 10.0),
                  child: Text(
                    'Today Reward : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(5.0),
                child: FutureBuilder(
                    future: loadData,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return SingleChildScrollView(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (win_lotterys
                                    .isEmpty) // ตรวจสอบว่ารายการ win_lotterys ว่างหรือไม่
                                  const Center(
                                    child: const Text(
                                      "ยังไม่ออกรางวัล", // ข้อความที่จะแสดงเมื่อไม่มีค่าใน all_Userlotterys
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  )
                                else
                                  ...win_lotterys.map((lottery) {
                                    List<String> numberList =
                                        lottery.numbers.toString().split('');
                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Builder(
                                              builder: (context) {
                                                String status;
                                                double fontSize;
                                                Icon? icon;
                                                Color textColor = Colors.black;
                                                Color iconColor = Colors.black;

                                                if (lottery.status_prize == 1) {
                                                  status = 'st';
                                                  fontSize = 21;
                                                  iconColor = Colors.blue;
                                                  icon = Icon(
                                                    Icons.local_fire_department,
                                                    color: iconColor,
                                                    size: 40,
                                                  );
                                                  textColor = Colors.blue;
                                                } else if (lottery
                                                        .status_prize ==
                                                    2) {
                                                  status = 'nd';
                                                  fontSize = 19;
                                                } else if (lottery
                                                        .status_prize ==
                                                    3) {
                                                  status = 'rd';
                                                  fontSize = 17;
                                                } else if (lottery
                                                        .status_prize >=
                                                    4) {
                                                  status = 'th';
                                                  fontSize = 15;
                                                } else {
                                                  status = 'unknown';
                                                  fontSize = 15;
                                                }

                                                return Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "${lottery.status_prize}${status}",
                                                      style: TextStyle(
                                                        fontSize: fontSize,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    if (icon != null)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 8.0),
                                                        child: icon,
                                                      ),
                                                  ],
                                                );
                                              },
                                            ),
                                            Builder(
                                              builder: (context) {
                                                String prize;
                                                if (lottery.status_prize == 1) {
                                                  prize = '10,000';
                                                } else if (lottery
                                                        .status_prize ==
                                                    2) {
                                                  prize = '5,000';
                                                } else if (lottery
                                                        .status_prize ==
                                                    3) {
                                                  prize = '1,000';
                                                } else if (lottery
                                                        .status_prize ==
                                                    4) {
                                                  prize = '500';
                                                } else if (lottery
                                                        .status_prize ==
                                                    5) {
                                                  prize = '150';
                                                } else {
                                                  prize = 'unknown';
                                                }

                                                return Text(
                                                  "เงินรางวัล $prize  บาท",
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: IntrinsicWidth(
                                            child: Card(
                                              color: const Color.fromARGB(
                                                  255, 254, 137, 69),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(30.0),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                child: SingleChildScrollView(
                                                  scrollDirection:
                                                      Axis.horizontal,
                                                  child: Row(
                                                    children: numberList
                                                        .map(
                                                            (number) => Padding(
                                                                  padding: const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          5,
                                                                      vertical:
                                                                          5),
                                                                  child: Card(
                                                                    color: const Color
                                                                        .fromARGB(
                                                                        255,
                                                                        255,
                                                                        255,
                                                                        255),
                                                                    shape:
                                                                        RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              50.0),
                                                                    ),
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .symmetric(
                                                                          horizontal:
                                                                              10.0,
                                                                          vertical:
                                                                              2),
                                                                      child:
                                                                          Center(
                                                                        child:
                                                                            Text(
                                                                          number,
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                21,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color:
                                                                                Colors.black,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ))
                                                        .toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    );
                                  }).toList(),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });

          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => HomePage(
                          selectedIndex: _selectedIndex,
                        )),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ShopPage(
                          selectedIndex: _selectedIndex,
                        )),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TicketPage(
                          selectedIndex: _selectedIndex,
                        )),
              );
              break;
            case 3:
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.account_circle),
                        title: const Text('Profile'),
                        onTap: () {
                          Navigator.pop(context); // ปิด BottomSheet ก่อน
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                selectedIndex: _selectedIndex,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Logout'),
                        onTap: () {
                          gs.remove('Email'); // ปิด BottomSheet ก่อน
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                      ),
                    ],
                  );
                },
              );
              break;
          }
        },
        selectedItemColor: const Color.fromARGB(255, 250, 150, 44),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.card_giftcard),
            label: 'Ticket',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Future<void> loadDataAsync() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var response = await http.get(Uri.parse("$url/db/get_WinLottery"));
    if (response.statusCode == 200) {
      win_lotterys = getLotteryNumbersFromJson(response.body);
      log(win_lotterys.toString());
      for (var lottery in win_lotterys) {
        log(lottery.numbers.toString());
      }
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
    }

    var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
    if (get_cart.statusCode == 200) {
      all_cart = getCartResFromJson(get_cart.body);
      log(all_cart.toString());
      context.read<ShareData>().user_info.cart_length = all_cart.length;
      for (var cart in all_cart) {
        log('lid' + cart.cLid.toString());
      }
    } else {
      log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
    }
  }
}
