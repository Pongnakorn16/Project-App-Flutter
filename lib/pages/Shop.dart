import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/cart_post_req.dart';
import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';
import 'package:mobile_miniproject_app/pages/profile.dart';

class ShopPage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int selectedIndex = 0;
  int cart_length = 0;
  ShopPage(
      {super.key,
      required this.uid,
      required this.wallet,
      required this.username,
      required this.selectedIndex,
      required this.cart_length});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class CartLotteryItem {
  final int lid;
  final List<String> numbers;

  CartLotteryItem({required this.lid, required this.numbers});
}

class _ShopPageState extends State<ShopPage> {
  String url = '';

  List<GetLotteryNumbers> all_lotterys = [];
  List<GetCartRes> all_cart = [];
  List<CartLotteryItem> cart_lotterys = [];
  List<GetOneUserRes> userInfo = [];
  late Future<void> loadData;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
    log(_selectedIndex.toString());
    loadData = loadDataAsync();
    log("CHECKKKKKKKKK length" + all_cart.length.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart,
                    color: Color.fromARGB(255, 254, 137, 69),
                    size: 29.0,
                  ),
                  onPressed: () {
                    int wallet_pay = all_cart.length * 100;
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('รถเข็นของฉัน'),
                            FilledButton(
                              onPressed: () {
                                setState(() {
                                  widget.cart_length = all_cart.length;
                                });
                                Navigator.pop(context);
                              },
                              child: Icon(
                                Icons.close,
                                size: 25,
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all(
                                    Colors.red), // สีพื้นหลังของปุ่ม
                                foregroundColor: WidgetStateProperty.all(
                                    Colors.white), // สีของข้อความบนปุ่ม
                                padding: WidgetStateProperty.all<EdgeInsets>(
                                    EdgeInsets.zero),
                                minimumSize: WidgetStateProperty.all<Size>(
                                    Size(30, 30)), // ขนาดของ padding ภายในปุ่ม
                                shape: WidgetStateProperty.all<
                                    RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        30), // มุมโค้งของปุ่มให้กลายเป็นวงกลม
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        content: SingleChildScrollView(
                          child: Column(
                            children: all_cart.asMap().entries.map((entry) {
                              int index = entry.key +
                                  1; // กำหนดหมายเลขลำดับ (เริ่มจาก 1)
                              GetCartRes item =
                                  entry.value; // item เป็น GetCartRes
                              List<String> numbers = [
                                item.numbers.toString()
                              ]; // แปลง GetCartRes เป็น numbers

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    Text(
                                      '$index. รหัส  ${numbers.join()} งวดวันที่ ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                      style: TextStyle(
                                          fontSize: 9), // กำหนดขนาดของข้อความ
                                    ),
                                    SizedBox(
                                        width:
                                            10), // เพิ่มระยะห่างระหว่างข้อความ
                                    Text(
                                      'ราคา 100 บาท',
                                      style: TextStyle(fontSize: 9),
                                    ),
                                    SizedBox(
                                        width:
                                            10), // เพิ่มระยะห่างระหว่างข้อความและปุ่ม
                                    FilledButton(
                                      onPressed: () {
                                        remove_cart(item.cLid);
                                        setState(() {}); // ลบรายการจากรถเข็น
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                      ),
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(Colors
                                                .red), // สีพื้นหลังของปุ่ม
                                        foregroundColor:
                                            WidgetStateProperty.all(Colors
                                                .white), // สีของข้อความบนปุ่ม
                                        padding:
                                            WidgetStateProperty.all<EdgeInsets>(
                                                EdgeInsets.zero),
                                        minimumSize:
                                            WidgetStateProperty.all<Size>(
                                                Size(25, 25)), // ขนาดของปุ่ม
                                        shape: WidgetStateProperty.all<
                                            RoundedRectangleBorder>(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                30), // มุมโค้งของปุ่มให้กลายเป็นวงกลม
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        actions: [
                          const Padding(
                            padding: EdgeInsets.only(top: 25.0, bottom: 5.0),
                            child: Divider(
                              color: Colors.grey,
                              thickness: 1,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "ราคารวม : $wallet_pay บาท",
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'จำนวน ${all_cart.length} ใบ',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 131, 130, 130),
                                    ),
                                  ),
                                ],
                              ),
                              FilledButton(
                                onPressed: () {
                                  purchase(wallet_pay);
                                  Navigator.pop(context);
                                },
                                child: const Text('Purchase'),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStateProperty.all(
                                      Colors.blue), // สีพื้นหลังของปุ่ม
                                  foregroundColor: WidgetStateProperty.all(
                                      Colors.white), // สีของข้อความบนปุ่ม
                                  padding: WidgetStateProperty.all<EdgeInsets>(
                                      EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical:
                                              10)), // ขนาดของ padding ภายในปุ่ม
                                  textStyle: WidgetStateProperty.all<TextStyle>(
                                      TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight
                                              .bold)), // ขนาดของข้อความในปุ่ม
                                ),
                              )
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Positioned(
                  top: 3,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.cart_length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(2.0),
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
                          color: Colors
                              .transparent, // ทำให้พื้นหลังของ Card เป็นโปร่งใส
                          elevation: 0, // ปิดการแสดงเงา
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                10.0), // กำหนดความโค้งมนของมุม
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: IntrinsicWidth(
                                      child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10.0),
                                          gradient: LinearGradient(
                                            colors: [
                                              const Color.fromARGB(255, 254,
                                                  137, 69), // สีที่กำหนด
                                              Colors.white.withOpacity(
                                                  0), // สีขาวที่โปร่งแสง
                                            ],
                                            stops: [
                                              0.75,
                                              1.0
                                            ], // ตำแหน่งของการเปลี่ยนสี
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 2),
                                          child: SingleChildScrollView(
                                            scrollDirection: Axis.horizontal,
                                            child: Row(
                                              children: [
                                                ...numberList
                                                    .map(
                                                      (number) => Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 3.5,
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
                                                                        5.0,
                                                                    vertical:
                                                                        2),
                                                            child: Center(
                                                              child: Text(
                                                                number,
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize: 18,
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
                                                      ),
                                                    )
                                                    .toList(),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 25.0),
                                        child: FilledButton(
                                          onPressed: () {
                                            int number = lottery
                                                .numbers; // ใช้ตัวแปรนี้เป็น int
                                            List<String> Lot_Num = [
                                              number.toString()
                                            ]; // สร้าง List<String> จาก int เดียว
                                            add_toCart(lottery.lid, Lot_Num);
                                            // ส่ง List<String> ไปยัง add_toCart
                                          },
                                          style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                    Colors.blue),
                                            foregroundColor:
                                                WidgetStateProperty.all(
                                                    Colors.white),
                                          ),
                                          child: const Icon(
                                            Icons.add_shopping_cart,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: 10.0, left: 10.0),
                                      child: Text(
                                        'งวดวันที่ : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                        style: const TextStyle(fontSize: 15),
                                      ),
                                    ),
                                  ],
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

  void add_toCart(int lid, List<String> Lot_Num) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    try {
      // สร้าง JSON payload ที่ต้องการส่งไปยังเซิร์ฟเวอร์
      var requestBody = CartPostRequest(
        cLid: lid,
        cUid: widget.uid,
      );

      var add_cart = await http.post(Uri.parse("$url/db/add_toCart"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body:
              cartPostRequestToJson((requestBody)) // ใช้ List<CartPostRequest>
          );

      var get_cart =
          await http.get(Uri.parse("$url/db/get_cart/${widget.uid}"));
      if (get_cart.statusCode == 200) {
        all_cart = getCartResFromJson(get_cart.body);
        log(all_cart.toString());
        for (var cart in all_cart) {
          log('lid' + cart.cLid.toString());
        }
      } else {
        log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
      }

      // ตรวจสอบสถานะการตอบกลับของเซิร์ฟเวอร์
      if (add_cart.statusCode == 200) {
        log('Response data: ${add_cart.body}');
        setState(() {
          widget.cart_length = all_cart.length;
          loadDataAsync();
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('แจ้งเตือน'),
            content: Text('ท่านได้มีหมายเลขนี้ในรถเข็นอยู่แล้ว'),
            actions: [
              const Padding(
                padding: EdgeInsets.only(top: 25.0, bottom: 5.0),
                child: Divider(
                  color: Colors.grey,
                  thickness: 1,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('ปิด'),
                    style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    } catch (err) {
      log(err.toString());
    }

    log('Items in cart: $cart_lotterys');
  }

  void purchase(int wallet_pay) async {
    log("Purchase success!!!");
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    List<int> CLid = all_cart.map((item) => item.cLid).toList();

    // สร้าง JSON body สำหรับ PUT request
    var body = jsonEncode({"lids": CLid});

    try {
      var res = await http.put(
        Uri.parse('$url/db/purchase/${wallet_pay}/${widget.uid}'),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: body,
      );
      var get_user = await http.get(Uri.parse("$url/db/user/${widget.uid}"));
      if (get_user.statusCode == 200) {
        List<GetOneUserRes> userInfoList = getOneUserResFromJson(get_user.body);
        log("UserInfoooooooooooooooooooooooooo$userInfoList");

        // สมมติว่ามีแค่หนึ่งผู้ใช้ในรายการ
        if (userInfoList.isNotEmpty) {
          GetOneUserRes userInfo = userInfoList.first;
          setState(() {
            widget.wallet = userInfo.wallet;
            loadDataAsync();
          });
        }
      }

      log(res.body);
      var result = jsonDecode(res.body);
      // Need to know json's property by reading from API Tester
      log(result['message']);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('สำเร็จ'),
          content: const Text('Purchase Successful'),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ปิด'),
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red)),
                ),
              ],
            ),
          ],
        ),
      );
    } catch (err) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ผิดพลาด'),
          content: Text('Purchase Failed ' + err.toString()),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ปิด'),
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void remove_cart(int cLid) async {
    var value = await Configuration.getConfig();
    String url = value['apiEndpoint'];

    var remove_cart =
        await http.delete(Uri.parse("$url/db/remove_cart/${cLid}"));

    if (remove_cart.statusCode == 200) {
      setState(() async {
        var get_cart =
            await http.get(Uri.parse("$url/db/get_cart/${widget.uid}"));
        all_cart = getCartResFromJson(get_cart.body);
        log("CHECKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK ${all_cart.length.toString()}");
        log("CHECKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK222222222222 ${all_cart.length.toString()}");
      });
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('แจ้งเตือน'),
          content: Text('นำออกจากรถเข็นไม่สำเร็จ'),
          actions: [
            const Padding(
              padding: EdgeInsets.only(top: 25.0, bottom: 5.0),
              child: Divider(
                color: Colors.grey,
                thickness: 1,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('ปิด'),
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red)),
                ),
              ],
            ),
          ],
        ),
      );
    }
  }

  void show_cart() {}

  Future<void> get_cart() async {
    var get_cart = await http.get(Uri.parse("$url/db/get_cart/${widget.uid}"));
    setState(() {
      all_cart = getCartResFromJson(get_cart.body);
      log("ALL cart check ${all_cart.length.toString()}"); // ตรวจสอบจำนวนรายการ
    });
  }
}
