import 'dart:convert';
import 'dart:developer';
import 'dart:ffi';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/TEST.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/pages/profile.dart';
import 'package:mobile_miniproject_app/pages/trip.dart';

class HomePage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int selectedIndex = 0;
  HomePage(
      {super.key,
      required this.uid,
      required this.wallet,
      required this.username,
      required this.selectedIndex});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String url = '';
  List<GetCartRes> all_cart = [];
  List<GetLotteryNumbers> win_lotterys = [];
  late Future<void> loadData;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // randomNumbers();
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
                    TextSpan(
                      text: 'Welcome ',
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black), // สีของข้อความที่เหลือ
                    ),
                    TextSpan(
                      text: widget.username,
                      style: const TextStyle(
                          fontSize: 20,
                          color: Colors.blue,
                          fontWeight:
                              FontWeight.bold), // สีของ ${widget.username}
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
                  SizedBox(width: 5),
                  Text(
                    'Wallet :  ${widget.wallet}  THB',
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
                              children: win_lotterys.map((lottery) {
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
                                            Color textColor = Colors
                                                .black; // สีเริ่มต้นของตัวหนังสือ
                                            Color iconColor = Colors
                                                .black; // สีเริ่มต้นของไอคอน

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
                                            } else if (lottery.status_prize ==
                                                2) {
                                              status = 'nd';
                                              fontSize = 19;
                                            } else if (lottery.status_prize ==
                                                3) {
                                              status = 'rd';
                                              fontSize = 17;
                                            } else if (lottery.status_prize >=
                                                4) {
                                              status = 'th';
                                              fontSize = 15;
                                            } else {
                                              status = 'unknown';
                                              fontSize =
                                                  15; // หรือค่าอื่น ๆ หาก status ไม่ตรงตามที่ระบุ
                                            }

                                            return Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                // แสดงไอคอนเฉพาะเมื่อไม่เป็น null
                                                Text(
                                                  "${lottery.status_prize}${status}",
                                                  style: TextStyle(
                                                    fontSize: fontSize,
                                                    fontWeight: FontWeight.bold,
                                                    color: textColor,
                                                  ),
                                                ),
                                                if (icon != null)
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .only(
                                                        right:
                                                            8.0), // เว้นระยะห่างระหว่างไอคอนกับข้อความ
                                                    child: icon,
                                                  ),
                                              ],
                                            );
                                          },
                                        ),
                                        Builder(
                                          builder: (context) {
                                            // กำหนดตัวแปร status ตามค่า lottery.status
                                            String prize;
                                            if (lottery.status_prize == 1) {
                                              prize = '10,000';
                                            } else if (lottery.status_prize ==
                                                2) {
                                              prize = '5,000';
                                            } else if (lottery.status_prize ==
                                                3) {
                                              prize = '1,000';
                                            } else if (lottery.status_prize ==
                                                4) {
                                              prize = '500';
                                            } else if (lottery.status_prize ==
                                                5) {
                                              prize = '150';
                                            } else {
                                              prize =
                                                  'unknown'; // หรือค่าอื่น ๆ หาก status ไม่ตรงตามที่ระบุ
                                            }

                                            return Text(
                                              "เงินรางวัล $prize  บาท",
                                              style: TextStyle(
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
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 2),
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children: numberList
                                                    .map((number) => Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal: 5,
                                                                  vertical: 5),
                                                          child: Card(
                                                            color: const Color
                                                                .fromARGB(255,
                                                                255, 255, 255),
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          50.0),
                                                            ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10.0,
                                                                      vertical:
                                                                          2),
                                                              child: Center(
                                                                child: Text(
                                                                  number,
                                                                  style:
                                                                      const TextStyle(
                                                                    fontSize:
                                                                        21,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .black,
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

                                    // คุณสามารถเพิ่มเนื้อหาหรือวิดเจ็ตเพิ่มเติมที่นี่ตามที่ต้องการ
                                  ],
                                );
                              }).toList(),
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
                          uid: widget.uid,
                          wallet: widget.wallet,
                          username: widget.username,
                          selectedIndex: _selectedIndex,
                        )),
              );
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ShopPage(
                          uid: widget.uid,
                          wallet: widget.wallet,
                          username: widget.username,
                          selectedIndex: _selectedIndex,
                          cart_length: all_cart.length,
                        )),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => TicketPage(
                          uid: widget.uid,
                          wallet: widget.wallet,
                          username: widget.username,
                          selectedIndex: _selectedIndex,
                          cart_length: all_cart.length,
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
                        leading: Icon(Icons.account_circle),
                        title: Text('Profile'),
                        onTap: () {
                          Navigator.pop(context); // ปิด BottomSheet ก่อน
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                uid: widget.uid,
                                wallet: widget.wallet,
                                username: widget.username,
                                selectedIndex: _selectedIndex,
                                cart_length: all_cart.length,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
                        onTap: () {
                          Navigator.pop(context); // ปิด BottomSheet ก่อน
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

    var get_cart = await http.get(Uri.parse("$url/db/get_cart/${widget.uid}"));
    if (get_cart.statusCode == 200) {
      all_cart = getCartResFromJson(get_cart.body);
      log(all_cart.toString());
      for (var cart in all_cart) {
        log('lid' + cart.cLid.toString());
      }
    } else {
      log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
    }
  }

  void randomNumbers() async {
    Set<String> uniqueNumbers = Set();

    while (uniqueNumbers.length < 10) {
      String number = Random().nextInt(999999).toString().padLeft(6, '0');
      uniqueNumbers.add(number);
    }
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    List<String> numbers = uniqueNumbers.toList();

    try {
      var response = await http.post(Uri.parse("$url/db/random"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: jsonEncode({'numbers': numbers}));

      if (response.statusCode == 200) {
        print('Insert success');
      } else {
        print('Failed to insert. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}
