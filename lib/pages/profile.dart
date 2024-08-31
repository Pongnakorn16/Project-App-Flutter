import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
import 'package:mobile_miniproject_app/models/response/customers_idx_get_res.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';
import 'package:mobile_miniproject_app/pages/Shop.dart';
import 'package:mobile_miniproject_app/pages/Ticket.dart';

class ProfilePage extends StatefulWidget {
  int uid = 0;
  int wallet = 0;
  String username = '';
  int selectedIndex = 0;
  int cart_length = 0;

  ProfilePage(
      {super.key,
      required this.uid,
      required this.wallet,
      required this.username,
      required this.selectedIndex,
      required this.cart_length});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  List<GetOneUserRes> user_Info = [];
  List<GetCartRes> all_cart = [];
  TextEditingController nameCtl = TextEditingController();
  TextEditingController walletCtl = TextEditingController();
  TextEditingController emailCtl = TextEditingController();
  TextEditingController imageCtl = TextEditingController();
  int _selectedIndex = 0;

  late Future<void> loadData;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
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
                          ? Image.network(
                              user_Info[0].image,
                              width: 150,
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
                                    // Add your onPressed logic here
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
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.wallet}',
                                    style: TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black, // กำหนดสีตามต้องการ
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.00 THB',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold, // ขนาดที่เล็กกว่า
                                      color: Colors.black, // สีที่แตกต่าง
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 20),
                              child: FilledButton(
                                onPressed: () {},
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all(Colors.blue),
                                  padding: WidgetStateProperty.all(
                                    const EdgeInsets.symmetric(
                                      vertical: 2.0,
                                      horizontal: 8.0,
                                    ),
                                  ),
                                  minimumSize: WidgetStateProperty.all(Size(
                                      0, 10)), // กำหนดความสูงขั้นต่ำของปุ่ม
                                ),
                                child: const Text(
                                  'เติมเงินเข้าระบบ',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 10),
                                  child: const Text(
                                    'ประวัติ',
                                    style: TextStyle(fontSize: 15),
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

    try {
      var res = await http.get(Uri.parse("$url/db/user/${widget.uid}"));
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

      var get_history =
          await http.get(Uri.parse("$url/db/get_history/${widget.uid}"));
      if (get_history.statusCode == 200) {
        all_cart = getCartResFromJson(get_history.body);
        log(all_cart.toString());
        for (var cart in all_cart) {
          log('lid' + cart.cLid.toString());
        }
      } else {
        log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
      }
    } catch (e) {
      log("Error occurred: $e");
    }
  }

  void update() async {}

  void delete() async {
    var config = await Configuration.getConfig();
    var url = config['apiEndpoint'];

    var res = await http.delete(Uri.parse('$url/customers/${widget.uid}'));
    log(res.statusCode.toString());
    if (res.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('สำเร็จ'),
          content: Text('ลบข้อมูลสำเร็จ'),
          actions: [
            FilledButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                child: const Text('ปิด'))
          ],
        ),
      ).then((s) {
        Navigator.popUntil(
          context,
          (route) => route.isFirst,
        );
      });
    } else {
      Navigator.pop(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ผิดพลาด'),
          content: Text('ลบข้อมูลไม่สำเร็จ'),
          actions: [
            FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('ปิด'))
          ],
        ),
      );
    }
  }
}
