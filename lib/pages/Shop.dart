// import 'dart:convert';
// import 'dart:developer';
// import 'dart:math' hide log;
// import 'package:flutter/material.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
// import 'package:mobile_miniproject_app/config/config.dart';
// import 'package:mobile_miniproject_app/models/request/cart_post_req.dart';
// import 'package:mobile_miniproject_app/models/response/GetCart_Res.dart';
// import 'package:mobile_miniproject_app/models/response/GetLotteryNumbers_Res.dart';
// import 'package:mobile_miniproject_app/models/response/GetOneUser_Res.dart';
// import 'package:mobile_miniproject_app/pages/Home.dart';
// import 'package:mobile_miniproject_app/pages/Ticket.dart';
// import 'package:mobile_miniproject_app/pages/Profile.dart';
// import 'package:mobile_miniproject_app/shared/share_data.dart';
// import 'package:provider/provider.dart';

// class ShopPage extends StatefulWidget {
//   int selectedIndex = 0;
//   int cart_length = 0;
//   ShopPage({
//     super.key,
//     required this.selectedIndex,
//   });

//   @override
//   State<ShopPage> createState() => _ShopPageState();
// }

// class CartLotteryItem {
//   final int lid;
//   final List<String> numbers;

//   CartLotteryItem({required this.lid, required this.numbers});
// }

// class _ShopPageState extends State<ShopPage> {
//   int uid = 0;
//   int wallet = 0;
//   String username = '';
//   int cart_length = 0;
//   GetStorage gs = GetStorage();

//   String url = '';
//   TextEditingController searchCtl = TextEditingController();
//   List<GetLotteryNumbers> all_lotterys = [];
//   List<GetLotteryNumbers> filteredLotterys = []; // List ล็อตเตอรี่ที่กรองแล้ว
//   List<GetCartRes> all_cart = [];
//   List<CartLotteryItem> cart_lotterys = [];
//   List<GetOneUserRes> userInfo = [];
//   late Future<void> loadData;
//   int _selectedIndex = 0;

//   @override
//   void initState() {
//     uid = context.read<ShareData>().user_info.uid;
//     username = context.read<ShareData>().user_info.username;
//     wallet = context.read<ShareData>().user_info.wallet;
//     cart_length = context.read<ShareData>().user_info.cart_length;
//     super.initState();
//     _selectedIndex = widget.selectedIndex;
//     log(_selectedIndex.toString());
//     loadData = loadDataAsync();
//     log("CHECKKKKKKKKK length" + all_cart.length.toString());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.only(top: 5),
//                       child: RichText(
//                         text: TextSpan(
//                           children: [
//                             TextSpan(
//                               text: 'Welcome ',
//                               style: const TextStyle(
//                                   fontSize: 20, color: Colors.black),
//                             ),
//                             TextSpan(
//                               text: username,
//                               style: const TextStyle(
//                                   fontSize: 20,
//                                   color: Colors.blue,
//                                   fontWeight: FontWeight.bold),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.only(top: 10, left: 1.5),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.account_balance_wallet,
//                             size: 20,
//                             color: Color.fromARGB(255, 254, 137, 69),
//                           ),
//                           SizedBox(width: 5),
//                           Text(
//                             'Wallet :  ${wallet}  THB',
//                             style: const TextStyle(
//                               fontSize: 15,
//                               color: Color.fromARGB(255, 131, 130, 130),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//                 Stack(
//                   clipBehavior: Clip.none,
//                   alignment: Alignment.center,
//                   children: [
//                     IconButton(
//                       icon: const Icon(
//                         Icons.shopping_cart,
//                         color: Color.fromARGB(255, 254, 137, 69),
//                         size: 29.0,
//                       ),
//                       onPressed: () {
//                         show_cart();
//                       },
//                     ),
//                     Positioned(
//                       top: 3,
//                       right: 6,
//                       child: Container(
//                         padding: const EdgeInsets.all(4),
//                         decoration: BoxDecoration(
//                           color: Colors.red,
//                           shape: BoxShape.circle,
//                         ),
//                         child: Text(
//                           '${cart_length}',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ],
//         ),
//         automaticallyImplyLeading: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(2.0),
//         child: Column(
//           children: [
//             // ช่องค้นหา
//             Padding(
//               padding: const EdgeInsets.only(top: 10, left: 10, right: 10),
//               child: TextField(
//                 controller: searchCtl,
//                 onChanged: (value) {
//                   filterSearch(
//                       value); // เรียกค้นหาทุกครั้งที่มีการเปลี่ยนข้อความ
//                 },
//                 decoration: InputDecoration(
//                   hintText: 'ค้นหาหมายเลขล็อตเตอรี่',
//                   prefixIcon: Icon(Icons.search),
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide: BorderSide.none,
//                   ),
//                   filled: true,
//                   fillColor: Colors.grey[200],
//                 ),
//               ),
//             ),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.all(5.0),
//                 child: FutureBuilder(
//                   future: loadData,
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState != ConnectionState.done) {
//                       return const Center(
//                         child: CircularProgressIndicator(),
//                       );
//                     }
//                     return ListView.builder(
//                       itemCount: filteredLotterys.length,
//                       itemBuilder: (context, index) {
//                         final lottery = filteredLotterys[index];
//                         List<String> numberList =
//                             lottery.numbers.toString().split('');
//                         return Card(
//                           color: Colors
//                               .transparent, // ทำให้พื้นหลังของ Card เป็นโปร่งใส
//                           elevation: 0, // ปิดการแสดงเงา
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(
//                                 10.0), // กำหนดความโค้งมนของมุม
//                           ),
//                           child: Padding(
//                             padding: const EdgeInsets.all(3.0),
//                             child: Column(
//                               children: [
//                                 Padding(
//                                   padding: const EdgeInsets.only(bottom: 10),
//                                   child: IntrinsicWidth(
//                                       child: Row(
//                                     children: [
//                                       Container(
//                                         decoration: BoxDecoration(
//                                           borderRadius:
//                                               BorderRadius.circular(10.0),
//                                           gradient: LinearGradient(
//                                             colors: [
//                                               const Color.fromARGB(255, 254,
//                                                   137, 69), // สีที่กำหนด
//                                               Colors.white.withOpacity(
//                                                   0), // สีขาวที่โปร่งแสง
//                                             ],
//                                             stops: [
//                                               0.75,
//                                               1.0
//                                             ], // ตำแหน่งของการเปลี่ยนสี
//                                             begin: Alignment.topCenter,
//                                             end: Alignment.bottomCenter,
//                                           ),
//                                         ),
//                                         child: Padding(
//                                           padding: const EdgeInsets.symmetric(
//                                               horizontal: 2),
//                                           child: SingleChildScrollView(
//                                             scrollDirection: Axis.horizontal,
//                                             child: Row(
//                                               children: [
//                                                 ...numberList
//                                                     .map(
//                                                       (number) => Padding(
//                                                         padding:
//                                                             const EdgeInsets
//                                                                 .symmetric(
//                                                                 horizontal: 3.5,
//                                                                 vertical: 5),
//                                                         child: Card(
//                                                           color: const Color
//                                                               .fromARGB(255,
//                                                               255, 255, 255),
//                                                           shape:
//                                                               RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         50.0),
//                                                           ),
//                                                           child: Padding(
//                                                             padding:
//                                                                 const EdgeInsets
//                                                                     .symmetric(
//                                                                     horizontal:
//                                                                         5.0,
//                                                                     vertical:
//                                                                         2),
//                                                             child: Center(
//                                                               child: Text(
//                                                                 number,
//                                                                 style:
//                                                                     const TextStyle(
//                                                                   fontSize: 18,
//                                                                   fontWeight:
//                                                                       FontWeight
//                                                                           .bold,
//                                                                   color: Colors
//                                                                       .black,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     )
//                                                     .toList(),
//                                               ],
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                       Padding(
//                                         padding:
//                                             const EdgeInsets.only(left: 25.0),
//                                         child: FilledButton(
//                                           onPressed: () {
//                                             int number =
//                                                 int.parse(lottery.numbers);
//                                             // ใช้ตัวแปรนี้เป็น int
//                                             List<String> Lot_Num = [
//                                               number.toString()
//                                             ]; // สร้าง List<String> จาก int เดียว
//                                             add_toCart(lottery.lid, Lot_Num);
//                                             // ส่ง List<String> ไปยัง add_toCart
//                                           },
//                                           style: ButtonStyle(
//                                             backgroundColor:
//                                                 WidgetStateProperty.all(
//                                                     Colors.blue),
//                                             foregroundColor:
//                                                 WidgetStateProperty.all(
//                                                     Colors.white),
//                                           ),
//                                           child: const Icon(
//                                             Icons.add_shopping_cart,
//                                             size: 24,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   )),
//                                 ),
//                                 Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     Padding(
//                                       padding: const EdgeInsets.only(
//                                           bottom: 10.0, left: 10.0),
//                                       child: Text(
//                                         'งวดวันที่ : ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
//                                         style: const TextStyle(fontSize: 15),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       },
//                     );
//                   },
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         onTap: (index) {
//           setState(() {
//             _selectedIndex = index;
//           });

//           switch (index) {
//             case 0:
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => HomePage(
//                           selectedIndex: _selectedIndex,
//                         )),
//               );
//               break;
//             case 1:
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => ShopPage(
//                           selectedIndex: _selectedIndex,
//                         )),
//               );
//               break;
//             case 2:
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(
//                     builder: (context) => TicketPage(
//                           selectedIndex: _selectedIndex,
//                         )),
//               );
//               break;
//             case 3:
//               showModalBottomSheet(
//                 context: context,
//                 builder: (context) {
//                   return Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ListTile(
//                         leading: Icon(Icons.account_circle),
//                         title: Text('Profile'),
//                         onTap: () {
//                           Navigator.pop(context); // ปิด BottomSheet ก่อน
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => ProfilePage(
//                                 selectedIndex: _selectedIndex,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                       ListTile(
//                         leading: Icon(Icons.logout),
//                         title: Text('Logout'),
//                         onTap: () {
//                           gs.remove('Email'); // ปิด BottomSheet ก่อน
//                           Navigator.of(context)
//                               .popUntil((route) => route.isFirst);
//                         },
//                       ),
//                     ],
//                   );
//                 },
//               );
//               break;
//           }
//         },
//         selectedItemColor:
//             const Color.fromARGB(255, 250, 150, 44), // สีของไอคอนที่เลือก
//         unselectedItemColor: Colors.grey, // สีของไอคอนที่ไม่เลือก
//         backgroundColor: Colors.white, // สีพื้นหลังของแถบเมนู
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.home),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.shopping_cart),
//             label: 'Shop',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.card_giftcard),
//             label: 'Ticket',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.more_horiz),
//             label: 'More',
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> loadDataAsync() async {
//     var value = await Configuration.getConfig();
//     String url = value['apiEndpoint'];

//     var response = await http.get(Uri.parse("$url/db/get_allLottery"));
//     if (response.statusCode == 200) {
//       all_lotterys = getLotteryNumbersFromJson(response.body);
//       log(all_lotterys.toString());
//       for (var lottery in all_lotterys) {
//         log(lottery.numbers.toString());
//       }
//     } else {
//       log('Failed to load lottery numbers. Status code: ${response.statusCode}');
//     }

//     var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
//     if (get_cart.statusCode == 200) {
//       all_cart = getCartResFromJson(get_cart.body);
//       log(all_cart.toString());
//       for (var cart in all_cart) {
//         log('lid' + cart.cLid.toString());
//       }
//     } else {
//       log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
//     }

//     filteredLotterys = all_lotterys;
//   }

//   void add_toCart(int lid, List<String> Lot_Num) async {
//     var value = await Configuration.getConfig();
//     String url = value['apiEndpoint'];

//     try {
//       // สร้าง JSON payload ที่ต้องการส่งไปยังเซิร์ฟเวอร์
//       var requestBody = CartPostRequest(
//         cLid: lid,
//         cUid: uid,
//       );

//       var add_cart = await http.post(Uri.parse("$url/db/add_toCart"),
//           headers: {"Content-Type": "application/json; charset=utf-8"},
//           body:
//               cartPostRequestToJson((requestBody)) // ใช้ List<CartPostRequest>
//           );

//       var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
//       if (get_cart.statusCode == 200) {
//         all_cart = getCartResFromJson(get_cart.body);
//         log(all_cart.toString());
//         for (var cart in all_cart) {
//           log('lid' + cart.cLid.toString());
//         }
//       } else {
//         log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
//       }

//       // ตรวจสอบสถานะการตอบกลับของเซิร์ฟเวอร์
//       if (add_cart.statusCode == 200) {
//         log('Response data: ${add_cart.body}');
//         setState(() {
//           cart_length = all_cart.length;
//           context.read<ShareData>().user_info.cart_length = all_cart.length;
//           loadDataAsync();
//         });
//       } else {
//         Fluttertoast.showToast(
//             msg: "ท่านได้มีหมายเลขนี้ในรถเข็นอยู่แล้ว",
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.CENTER,
//             timeInSecForIosWeb: 1,
//             // backgroundColor: Color.fromARGB(120, 0, 0, 0),
//             backgroundColor: Color.fromARGB(255, 255, 0, 0),
//             textColor: Colors.white,
//             fontSize: 15.0);
//       }
//     } catch (err) {
//       log(err.toString());
//     }

//     log('Items in cart: $cart_lotterys');
//   }

//   void purchase(int wallet_pay) async {
//     log("Purchase success!!!");
//     var value = await Configuration.getConfig();
//     String url = value['apiEndpoint'];

//     List<int> CLid = all_cart.map((item) => item.cLid).toList();

//     // สร้าง JSON body สำหรับ PUT request
//     var body = jsonEncode({"lids": CLid});

//     try {
//       var res = await http.put(
//         Uri.parse('$url/db/purchase/${wallet_pay}/${uid}'),
//         headers: {"Content-Type": "application/json; charset=utf-8"},
//         body: body,
//       );
//       var get_user = await http.get(Uri.parse("$url/db/user/${uid}"));
//       if (get_user.statusCode == 200) {
//         List<GetOneUserRes> userInfoList = getOneUserResFromJson(get_user.body);
//         log("UserInfoooooooooooooooooooooooooo$userInfoList");

//         // สมมติว่ามีแค่หนึ่งผู้ใช้ในรายการ
//         if (userInfoList.isNotEmpty) {
//           GetOneUserRes userInfo = userInfoList.first;
//           setState(() {
//             wallet =
//                 context.read<ShareData>().user_info.wallet = userInfo.wallet;
//             ;
//           });
//         }
//       }

//       var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
//       if (get_cart.statusCode == 200) {
//         all_cart = getCartResFromJson(get_cart.body);
//         log(all_cart.toString());
//         for (var cart in all_cart) {
//           log('lid' + cart.cLid.toString());
//         }
//       } else {
//         log('Failed to load lottery numbers. Status code: ${get_cart.statusCode}');
//       }

//       log(res.body);
//       var result = jsonDecode(res.body);
//       // Need to know json's property by reading from API Tester
//       log(result['message']);

//       if (get_cart.statusCode == 200) {
//         log('Response data: ${get_cart.body}');
//         setState(() {
//           log(all_cart.length.toString());
//           cart_length =
//               context.read<ShareData>().user_info.cart_length = all_cart.length;

//           loadDataAsync().then((_) {
//             setState(() {}); // เรียก setState อีกครั้งหลังจากโหลดข้อมูลเสร็จ
//           });
//         });
//         Fluttertoast.showToast(
//             msg: "สำเร็จ Purchase Successful",
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.CENTER,
//             timeInSecForIosWeb: 1,
//             // backgroundColor: Color.fromARGB(120, 0, 0, 0),
//             backgroundColor: Color.fromARGB(255, 3, 252, 32),
//             textColor: Colors.white,
//             fontSize: 15.0);
//       } else {
//         Fluttertoast.showToast(
//             msg: "ผิดพลาด Purchase Failed",
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.CENTER,
//             timeInSecForIosWeb: 1,
//             // backgroundColor: Color.fromARGB(120, 0, 0, 0),
//             backgroundColor: Color.fromARGB(255, 255, 0, 0),
//             textColor: Colors.white,
//             fontSize: 15.0);
//       }
//       // showDialog(
//       //   context: context,
//       //   builder: (context) => AlertDialog(
//       //     title: const Text('สำเร็จ'),
//       //     content: const Text('Purchase Successful'),
//       //     actions: [
//       //       Row(
//       //         mainAxisAlignment: MainAxisAlignment.end,
//       //         children: [
//       //           FilledButton(
//       //             onPressed: () {
//       //               setState(() {
//       //                 cart_length = all_cart.length;
//       //               });
//       //               Navigator.pop(context);
//       //             },
//       //             child: const Text('ปิด'),
//       //             style: ButtonStyle(
//       //                 backgroundColor: WidgetStateProperty.all(Colors.red)),
//       //           ),
//       //         ],
//       //       ),
//       //     ],
//       //   ),
//       // );
//     } catch (err) {
//       Fluttertoast.showToast(
//           msg: "ผิดพลาด Purchase Failed",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.CENTER,
//           timeInSecForIosWeb: 1,
//           // backgroundColor: Color.fromARGB(120, 0, 0, 0),
//           backgroundColor: Color.fromARGB(255, 255, 0, 0),
//           textColor: Colors.white,
//           fontSize: 15.0);
//     }
//   }

//   void remove_cart(int cLid) async {
//     var value = await Configuration.getConfig();
//     String url = value['apiEndpoint'];

//     var remove_cart =
//         await http.delete(Uri.parse("$url/db/remove_cart/${cLid}"));

//     if (remove_cart.statusCode == 200) {
//       setState(() async {
//         var get_cart = await http.get(Uri.parse("$url/db/get_cart/${uid}"));
//         all_cart = getCartResFromJson(get_cart.body);
//         log("CHECKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK ${all_cart.length.toString()}");
//         log("CHECKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKKK222222222222 ${all_cart.length.toString()}");
//         Navigator.pop(context);
//         show_cart();
//       });
//     } else {
//       Fluttertoast.showToast(
//           msg: "นำออกจากรถเข็นไม่สำเร็จ",
//           toastLength: Toast.LENGTH_SHORT,
//           gravity: ToastGravity.CENTER,
//           timeInSecForIosWeb: 1,
//           // backgroundColor: Color.fromARGB(120, 0, 0, 0),
//           backgroundColor: Color.fromARGB(255, 255, 0, 0),
//           textColor: Colors.white,
//           fontSize: 15.0);
//     }
//   }

//   void show_cart() {
//     int wallet_pay = all_cart.length * 100;
//     showDialog(
//       barrierDismissible: false,
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             const Text('รถเข็นของฉัน'),
//             FilledButton(
//               onPressed: () {
//                 setState(() {
//                   cart_length = all_cart.length;
//                 });
//                 Navigator.pop(context);
//               },
//               child: Icon(
//                 Icons.close,
//                 size: 25,
//               ),
//               style: ButtonStyle(
//                 backgroundColor:
//                     WidgetStateProperty.all(Colors.red), // สีพื้นหลังของปุ่ม
//                 foregroundColor:
//                     WidgetStateProperty.all(Colors.white), // สีของข้อความบนปุ่ม
//                 padding: WidgetStateProperty.all<EdgeInsets>(EdgeInsets.zero),
//                 minimumSize: WidgetStateProperty.all<Size>(
//                     Size(30, 30)), // ขนาดของ padding ภายในปุ่ม
//                 shape: WidgetStateProperty.all<RoundedRectangleBorder>(
//                   RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(
//                         30), // มุมโค้งของปุ่มให้กลายเป็นวงกลม
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//         content: all_cart.isEmpty
//             ? Text('ไม่มีล็อตเตอรี่ในรถเข็น',
//                 style: TextStyle(fontSize: 16, color: Colors.red))
//             : SingleChildScrollView(
//                 child: Column(
//                   children: all_cart.asMap().entries.map((entry) {
//                     int index = entry.key + 1;
//                     GetCartRes item = entry.value;
//                     List<String> numbers = [item.numbers.toString()];

//                     return SingleChildScrollView(
//                       scrollDirection: Axis.horizontal,
//                       child: Row(
//                         children: [
//                           Text(
//                             '$index. รหัส  ${numbers.join()} งวดวันที่ ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
//                             style: TextStyle(fontSize: 9),
//                           ),
//                           SizedBox(width: 10),
//                           Text(
//                             'ราคา 100 บาท',
//                             style: TextStyle(fontSize: 9),
//                           ),
//                           SizedBox(width: 10),
//                           FilledButton(
//                             onPressed: () {
//                               remove_cart(item.cLid);
//                               Navigator.pop(context);
//                               show_cart();
//                             },
//                             child: Icon(
//                               Icons.close,
//                               size: 18,
//                             ),
//                             style: ButtonStyle(
//                               backgroundColor:
//                                   WidgetStateProperty.all(Colors.red),
//                               foregroundColor:
//                                   WidgetStateProperty.all(Colors.white),
//                               padding: WidgetStateProperty.all<EdgeInsets>(
//                                   EdgeInsets.zero),
//                               minimumSize:
//                                   WidgetStateProperty.all<Size>(Size(25, 25)),
//                               shape: WidgetStateProperty.all<
//                                   RoundedRectangleBorder>(
//                                 RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(30),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//         actions: [
//           const Padding(
//             padding: EdgeInsets.only(top: 25.0, bottom: 5.0),
//             child: Divider(
//               color: Colors.grey,
//               thickness: 1,
//             ),
//           ),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "ราคารวม : $wallet_pay บาท",
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   Text(
//                     'จำนวน ${all_cart.length} ใบ',
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Color.fromARGB(255, 131, 130, 130),
//                     ),
//                   ),
//                 ],
//               ),
//               FilledButton(
//                 onPressed: () {
//                   if (wallet < wallet_pay) {
//                     Fluttertoast.showToast(
//                         msg: "ยอด Wallet ของท่านไม่เพียงพอกรุณาเติมเงิน!!!",
//                         toastLength: Toast.LENGTH_SHORT,
//                         gravity: ToastGravity.CENTER,
//                         timeInSecForIosWeb: 1,
//                         // backgroundColor: Color.fromARGB(120, 0, 0, 0),
//                         backgroundColor: Color.fromARGB(255, 255, 0, 0),
//                         textColor: Colors.white,
//                         fontSize: 15.0);
//                   } else {
//                     purchase(wallet_pay);
//                     Navigator.pop(context);
//                   }
//                 },
//                 child: const Text('Purchase'),
//                 style: ButtonStyle(
//                   backgroundColor:
//                       WidgetStateProperty.all(Colors.blue), // สีพื้นหลังของปุ่ม
//                   foregroundColor: WidgetStateProperty.all(
//                       Colors.white), // สีของข้อความบนปุ่ม
//                   padding: WidgetStateProperty.all<EdgeInsets>(
//                       EdgeInsets.symmetric(
//                           horizontal: 10,
//                           vertical: 10)), // ขนาดของ padding ภายในปุ่ม
//                   textStyle: WidgetStateProperty.all<TextStyle>(TextStyle(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold)), // ขนาดของข้อความในปุ่ม
//                 ),
//               )
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   void filterSearch(String query) async {
//     var value = await Configuration.getConfig();
//     String url = value['apiEndpoint'];

//     var response = await http.get(Uri.parse("$url/db/get_allLottery"));
//     if (response.statusCode == 200) {
//       all_lotterys = getLotteryNumbersFromJson(response.body);
//       log(all_lotterys.toString());
//       for (var lottery in all_lotterys) {
//         log('load all_lotterys comlplete. Status code: ${response.statusCode}');
//       }
//     } else {
//       log('Failed to load lottery numbers. Status code: ${response.statusCode}');
//     }

//     setState(() {
//       if (query.isEmpty) {
//         filteredLotterys = all_lotterys; // ถ้าช่องค้นหาว่างให้แสดงข้อมูลทั้งหมด
//       } else {
//         filteredLotterys = all_lotterys.where((lottery) {
//           // ตรวจสอบว่าแต่ละตำแหน่งของ numbers ตรงกับ query ที่พิมพ์ทีละตัว
//           if (query.length <= lottery.numbers.length) {
//             return lottery.numbers.substring(0, query.length) == query;
//           }
//           return false;
//         }).toList();
//       }
//     });
//   }
// }
