import 'dart:convert';
import 'dart:developer';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetHistory_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/models/response/customers_idx_get_res.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int selectedIndex = 0;
  int cart_length = 0;
  final VoidCallback onClose;

  ProfilePage({
    super.key,
    required this.onClose,
    required this.selectedIndex,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int cart_length = 0;
  GetStorage gs = GetStorage();
  List<GetOneUserRes> user_Info = [];
  List<GetHistoryRes> all_history = [];
  TextEditingController nameCtl = TextEditingController();
  TextEditingController walletCtl = TextEditingController();
  TextEditingController imageCtl = TextEditingController();
  int _selectedIndex = 0;

  late Future<void> loadData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    uid = context.read<ShareData>().user_info.uid;
    username = context.read<ShareData>().user_info.username;
    wallet = context.read<ShareData>().user_info.wallet;
    cart_length = context.read<ShareData>().user_info.cart_length;
    // log(widget.uid.toString());
    _selectedIndex = widget.selectedIndex;
    loadData = loadDataAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [],
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder(
          future: loadData,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            return SingleChildScrollView(
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0, bottom: 8),
                      child: user_Info.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                change_image(); // ฟังก์ชันที่จะถูกเรียกเมื่อกดที่รูป
                              },
                              child: Stack(
                                alignment: Alignment
                                    .center, // จัดตำแหน่งของไอคอนกลางรูป
                                children: [
                                  // รูปภาพหลัก
                                  Image.network(
                                    user_Info[0].image,
                                    width: 150,
                                    height:
                                        150, // กำหนดความสูงเพื่อให้รูปเป็นสี่เหลี่ยมจัตุรัส
                                    fit: BoxFit
                                        .cover, // ครอบคลุมรูปให้เต็มพื้นที่
                                  ),
                                  // ไอคอนที่บ่งบอกการแก้ไข
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons
                                            .add_a_photo, // เปลี่ยนไอคอนที่นี่หากต้องการ
                                        color: Colors.blue,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Text(
                              'No Image Available'), // หรือ placeholder อื่นๆ
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(user_Info.isNotEmpty
                              ? user_Info[0].email
                              : 'No email available'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16.0, right: 16.0, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 40.0),
                                child: Text(
                                  user_Info.isNotEmpty
                                      ? user_Info[0].username
                                      : 'No email available',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    edit_profile();
                                  },
                                  color: const Color.fromARGB(255, 254, 137,
                                      69), // Change the icon color if needed
                                  iconSize:
                                      24.0, // Change the icon size if needed
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Card(
                      margin:
                          EdgeInsets.zero, // ยกเลิก margin ของ Card หากต้องการ
                      child: Padding(
                        padding: const EdgeInsets.all(
                            16.0), // เพิ่ม padding รอบๆ Card
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min, // ใช้ขนาดของเนื้อหาภายใน Column
                          children: [
                            // แสดงยอดเงิน
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${wallet}',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.00 THB',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: FilledButton(
                                onPressed: () {
                                  top_up();
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all(Colors.blue),
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                      horizontal: 8.0,
                                    ),
                                  ),
                                  minimumSize:
                                      WidgetStateProperty.all(Size(0, 10)),
                                ),
                                child: const Text(
                                  'เติมเงินเข้าระบบ',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            // แสดงหัวข้อ 'ประวัติ'
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'ประวัติ',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' การซื้อและขึ้นเงิน Lotterys',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              color: Colors.black,
                              thickness: 2,
                              indent: 10,
                              endIndent: 10,
                            ),
                            // แสดงข้อมูลใน all_history
                            ...all_history.asMap().entries.map((entry) {
                              GetHistoryRes item =
                                  entry.value; // item เป็น GetHistoryRes
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0, horizontal: 10.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text:
                                                    '${item.hNumber.toString()} - ',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors
                                                      .black, // กำหนดสีที่ต้องการสำหรับ hNumber
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    '${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors
                                                      .black, // กำหนดสีที่ต้องการสำหรับวันที่
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Text(
                                          item.hWallet > 100
                                              ? '+${item.hWallet.toString()}'
                                              : '-${item.hWallet.toString()}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: item.hWallet > 100
                                                ? Colors.green
                                                : Colors
                                                    .red, // กำหนดสีตามเงื่อนไข
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: Colors.black,
                                    thickness: 2,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }),
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
                    builder: (context) => Home_SendPage(
                          selectedIndex: _selectedIndex,
                          onClose: () {},
                        )),
              );
              break;
            // case 1:
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => ShopPage(
            //               selectedIndex: _selectedIndex,
            //             )),
            //   );
            //   break;
            // case 2:
            //   Navigator.push(
            //     context,
            //     MaterialPageRoute(
            //         builder: (context) => TicketPage(
            //               selectedIndex: _selectedIndex,
            //             )),
            //   );
            //   break;
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
                                selectedIndex: _selectedIndex,
                                onClose: () {},
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.logout),
                        title: Text('Logout'),
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

    try {
      var res = await http.get(Uri.parse("$url/db/user/${uid}"));
      if (res.statusCode == 200) {
        user_Info = getOneUserResFromJson(res.body);
        if (user_Info != null) {
          log("user_Info : " + user_Info.toString());
        } else {
          log("Failed to parse user info.");
        }
      } else {
        log('Failed to load user info. Status code: ${res.statusCode}');
      }

      // var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
      // if (get_cart.statusCode == 200) {
      //   all_cart = getCartResFromJson(get_cart.body);
      //   log(all_cart.toString());
      //   for (var cart in all_cart) {
      //     log('lidddddddddddddddddddddd' + cart.cLid.toString());
      //   }
      // } else {
      //   log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
      // }

      var get_history = await http.get(Uri.parse("$url/db/get_history/${uid}"));
      if (get_history.statusCode == 200) {
        all_history = getHistoryResFromJson(get_history.body);
        log(all_history.toString());
        for (var history in all_history) {
          log('HISTORY_LID' + history.hNumber.toString());
        }
      } else {
        log('Failed to load lottery numbers. Status code: ${get_history.statusCode}');
      }
    } catch (e) {
      log("Error occurred: $e");
    }
  }

  void edit_profile() async {
    // รีเซ็ตค่าของ TextEditingController
    nameCtl.clear();
    showDialog(
      context: context,
      barrierDismissible: false, // กำหนดให้ dialog ไม่หายเมื่อแตะบริเวณรอบนอก
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('เปลี่ยนชื่อ'),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                size: 25,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all<Size>(const Size(30, 30)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรอกชื่อที่ต้องการเปลี่ยน'),
            const SizedBox(height: 10),
            TextField(
              controller: nameCtl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 228, 225, 225),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(width: 1),
                ),
                hintText: user_Info.first
                    .username, // กำหนดให้ hintText เป็นค่าของ user_Info.Username
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // ปรับตำแหน่งปุ่มให้ตรงกลาง
            children: [
              FilledButton(
                onPressed: () {
                  change_name();
                  setState(() {
                    loadDataAsync();
                  });
                  Navigator.pop(context);
                },
                child: const Text('ยืนยัน'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void change_name() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    // ดึงค่าจาก TextEditingController แล้วสร้าง JSON object
    var body = jsonEncode({"Username": nameCtl.text});

    var Change_name = await http.put(
      Uri.parse('$url/db/user/change_name/${uid}'),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: body,
    );

    var res = await http.get(Uri.parse("$url/db/user/${uid}"));
    if (res.statusCode == 200) {
      user_Info = getOneUserResFromJson(res.body);
      if (user_Info != null) {
        log("user_Info: " + user_Info.toString());
      } else {
        log("Failed to parse user info.");
      }
    } else {
      log('Failed to load user info. Status code: ${res.statusCode}');
    }

    if (res.statusCode == 200) {
      setState(() {
        username = user_Info.first.username;
        loadDataAsync();
      });

      Fluttertoast.showToast(
          msg: "Name has changed !!!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          // backgroundColor: Color.fromARGB(120, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 250, 150, 44),
          textColor: Colors.white,
          fontSize: 15.0);
    } else {
      // จัดการกับ error ถ้า update ไม่สำเร็จ
      print('Failed to change name: ${res.body}');
    }
  }

  void top_up() async {
    walletCtl.clear();
    showDialog(
      context: context,
      barrierDismissible: false, // กำหนดให้ dialog ไม่หายเมื่อแตะบริเวณรอบนอก
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('เติมเงิน'),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                size: 25,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all<Size>(const Size(30, 30)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ระบุจำนวน Wallet ที่ต้องการจะเติม'),
            const SizedBox(height: 10),
            TextField(
              controller: walletCtl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 228, 225, 225),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(width: 1),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // ปรับตำแหน่งปุ่มให้ตรงกลาง
            children: [
              FilledButton(
                onPressed: () {
                  wallet_add();
                  setState(() {
                    loadDataAsync();
                  });
                  Navigator.pop(context);
                },
                child: const Text('ยืนยัน'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void wallet_add() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var body = jsonEncode({"Wallet": walletCtl.text});

    var Top_up = await http.put(
      Uri.parse('$url/db/user/top_up/${uid}'),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: body,
    );

    var res = await http.get(Uri.parse("$url/db/user/${uid}"));
    if (res.statusCode == 200) {
      user_Info = getOneUserResFromJson(res.body);
      if (user_Info != null) {
        log("user_Info: " + user_Info.toString());
      } else {
        log("Failed to parse user info.");
      }
    } else {
      log('Failed to load user info. Status code: ${res.statusCode}');
    }

    if (res.statusCode == 200) {
      setState(() {
        wallet = user_Info.first.wallet;
        context.read<ShareData>().user_info.wallet = user_Info.first.wallet;
        loadDataAsync();
      });

      Fluttertoast.showToast(
          msg: "Wallet has added !!!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          // backgroundColor: Color.fromARGB(120, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 250, 150, 44),
          textColor: Colors.white,
          fontSize: 15.0);
    } else {
      // จัดการกับ error ถ้า update ไม่สำเร็จ
      print('Failed to change name: ${res.body}');
    }
  }

  void change_image() {
    imageCtl.clear();
    showDialog(
      context: context,
      barrierDismissible: false, // กำหนดให้ dialog ไม่หายเมื่อแตะบริเวณรอบนอก
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('เปลี่ยนรูป'),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Icon(
                Icons.close,
                size: 25,
              ),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero),
                minimumSize: WidgetStateProperty.all<Size>(const Size(30, 30)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('กรอก URL ของรูปที่ต้องการจะเปลี่ยน'),
            const SizedBox(height: 10),
            TextField(
              controller: imageCtl,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 228, 225, 225),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: const BorderSide(width: 1),
                ),
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center, // ปรับตำแหน่งปุ่มให้ตรงกลาง
            children: [
              FilledButton(
                onPressed: () {
                  edit_image();
                  setState(() {
                    loadDataAsync();
                  });
                  Navigator.pop(context);
                },
                child: const Text('ยืนยัน'),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void edit_image() async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var body = jsonEncode({"url_image": imageCtl.text});

    var change_image = await http.put(
      Uri.parse('$url/db/user/change_image/${uid}'),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: body,
    );

    var res = await http.get(Uri.parse("$url/db/user/${uid}"));
    if (res.statusCode == 200) {
      user_Info = getOneUserResFromJson(res.body);
      if (user_Info != null) {
        log("user_Info: " + user_Info.toString());
      } else {
        log("Failed to parse user info.");
      }
    } else {
      log('Failed to load user info. Status code: ${res.statusCode}');
    }

    if (res.statusCode == 200) {
      setState(() {
        loadDataAsync();
      });

      Fluttertoast.showToast(
          msg: "Image has changed !!!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          // backgroundColor: Color.fromARGB(120, 0, 0, 0),
          backgroundColor: Color.fromARGB(255, 250, 150, 44),
          textColor: Colors.white,
          fontSize: 15.0);
    } else {
      // จัดการกับ error ถ้า update ไม่สำเร็จ
      print('Failed to change name: ${res.body}');
    }
  }
}
