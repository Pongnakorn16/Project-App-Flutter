import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/pages/profile.dart';

class ShopPage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int selectedIndex = 0;
  ShopPage(
      {super.key,
      required this.uid,
      required this.wallet,
      required this.username,
      required this.selectedIndex});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String url = '';

  List<GetLotteryNumbers> all_lotterys = [];
  late Future<void> loadData;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // randomNumbers();
    _selectedIndex = widget.selectedIndex;
    log(_selectedIndex.toString());
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
                    return ListView.builder(
                      itemCount: all_lotterys.length,
                      itemBuilder: (context, index) {
                        final lottery = all_lotterys[index];
                        List<String> numberList =
                            lottery.numbers.toString().split('');
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Column(
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

                                        if (lottery.status == 1) {
                                          status = 'st';
                                          fontSize = 21;
                                          iconColor = Colors.blue;
                                          icon = Icon(
                                            Icons.local_fire_department,
                                            color: iconColor,
                                            size: 40,
                                          );
                                          textColor = Colors.blue;
                                        } else if (lottery.status == 2) {
                                          status = 'nd';
                                          fontSize = 19;
                                        } else if (lottery.status == 3) {
                                          status = 'rd';
                                          fontSize = 17;
                                        } else if (lottery.status >= 4) {
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
                                              "${lottery.status}${status}",
                                              style: TextStyle(
                                                fontSize: fontSize,
                                                fontWeight: FontWeight.bold,
                                                color: textColor,
                                              ),
                                            ),
                                            if (icon != null)
                                              Padding(
                                                padding: const EdgeInsets.only(
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
                                        if (lottery.status == 1) {
                                          prize = '10,000';
                                        } else if (lottery.status == 2) {
                                          prize = '5,000';
                                        } else if (lottery.status == 3) {
                                          prize = '1,000';
                                        } else if (lottery.status == 4) {
                                          prize = '500';
                                        } else if (lottery.status == 5) {
                                          prize = '150';
                                        } else {
                                          prize = 'unknown';
                                        }

                                        return Text(
                                          "เงินรางวัล $prize บาท",
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
                                  padding: const EdgeInsets.only(bottom: 10),
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
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 5,
                                                          vertical: 5),
                                                      child: Card(
                                                        color: const Color
                                                            .fromARGB(
                                                            255, 255, 255, 255),
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
                                                                  vertical: 2),
                                                          child: Center(
                                                            child: Text(
                                                              number,
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 21,
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
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
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
                        )),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TicketPage()),
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
                              builder: (context) =>
                                  ProfilePage(idx: widget.uid),
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
        selectedItemColor:
            const Color.fromARGB(255, 250, 150, 44), // สีของไอคอนที่เลือก
        unselectedItemColor: Colors.grey, // สีของไอคอนที่ไม่เลือก
        backgroundColor: Colors.white, // สีพื้นหลังของแถบเมนู
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

    var response = await http.get(Uri.parse("$url/db/get_allLottery"));
    if (response.statusCode == 200) {
      all_lotterys = getLotteryNumbersFromJson(response.body);
      log(all_lotterys.toString());
      for (var lottery in all_lotterys) {
        log(lottery.numbers.toString());
      }
    } else {
      log('Failed to load lottery numbers. Status code: ${response.statusCode}');
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

  // void getTrips(String? zone) async {
  //   // 1. Load url from config
  //   var value = await Configuration.getConfig();
  //   String url = value['apiEndpoint'];

  //   // 2. Call Get / trips
  //   var json = await http.get(Uri.parse("$url/trips"));
  //   trips = tripsGetResponesFromJson(json.body);
  //   log('API response body: ${json.body}');

  //   // 3. Put response data to model
  //   List<TripsGetRespones> filteredTrips = [];
  //   // 3.1 Check if zone is "ทั้งหมด" (all)
  //   if (zone == null) {
  //     filteredTrips = trips; // Show all trips
  //   } else {
  //     for (var trip in trips) {
  //       String tripZone = destinationZoneValues.reverse[trip.destinationZone]!;
  //       if (tripZone == zone) {
  //         filteredTrips.add(trip);
  //       }
  //     }
  //   }

  //   trips = filteredTrips;

  //   // 4. Log number of trips
  //   log(trips.length.toString());
  //   setState(() {});
  // }
}
