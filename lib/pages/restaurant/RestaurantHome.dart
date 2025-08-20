import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OpCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OpCatLinkGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/Home_Receive.dart';
import 'package:mobile_miniproject_app/pages/Home_Send.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/restaurant/AddMenu.dart';
import 'package:mobile_miniproject_app/pages/restaurant/EditMenu.dart';
import 'package:mobile_miniproject_app/pages/restaurant/EditOption.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResAllOrder.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResProfile.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class RestaurantHomePage extends StatefulWidget {
  RestaurantHomePage({
    super.key,
  });

  @override
  State<RestaurantHomePage> createState() => _HomePageState();
}

class _HomePageState extends State<RestaurantHomePage> {
  int uid = 0;
  String name = '';
  int _selectedIndex = 0;
  int _currentPage = 0;
  late PageController _pageController;
  String url = '';
  int ResId = 0;

  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
  List<OpCatLinkGetResponse> _Menu_check = [];
  List<ResInfoResponse> _restaurantInfo = [];
  List<OpCatGetResponse> _AllOpcat = [];

  @override
  void initState() {
    super.initState();
    ResId = context.read<ShareData>().user_info_send.uid;
    _pageController = PageController();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadResInfo();
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'หน้าร้านค้า : ',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: context.read<ShareData>().user_info_send.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 241, 199, 12),
                ),
              ),
            ],
          ),
        ),
        automaticallyImplyLeading: false,
      ),

      // PageView แทน body ปกติ
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          LoadResInfo();
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          buildRestaurantHomeBody(), // หน้าหลักร้าน (ย้าย body เดิมมาใส่ในฟังก์ชันนี้)
          ResAllOrderPage(), // หน้ารับออเดอร์
          ResProfilePage(onClose: () {}, selectedIndex: 2), // โปรไฟล์
        ],
      ),

      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildRestaurantHomeBody() {
    if (_restaurantInfo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // รูป + ข้อมูลร้าน
          Stack(
            children: [
              Image.network(
                _restaurantInfo[0].res_image ?? '',
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[300],
                  height: 200,
                  child: const Icon(Icons.store, size: 80),
                ),
              ),
            ],
          ),
          // Description, คะแนน, ปุ่มจัดการ ฯลฯ
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.yellow, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      "Rating : ${_restaurantInfo[0].res_rating ?? 0.0}",
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Description
                Row(
                  children: [
                    const Icon(Icons.description_outlined,
                        color: Colors.black, size: 18),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        "Description : ${_restaurantInfo[0].res_description ?? ''}",
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                // ปุ่มจัดการ
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => POP_UPCaterogy(),
                        icon: const Icon(Icons.category),
                        label: const Text("จัดการหมวดหมู่เมนู"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => POP_UPMenu(),
                        icon: const Icon(Icons.fastfood),
                        label: const Text("จัดการเมนู"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          loadAllCat();
                          POP_UPallOpcat();
                        },
                        icon: const Icon(Icons.playlist_add),
                        label: const Text("จัดการหมวดหมู่ตัวเลือกเพิ่มเติม"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // หมวดหมู่ + เมนู
          ..._restaurantCategories.map((cat) {
            final menusInCat = _restaurantMenu
                .where((menu) => menu.cat_id == cat.cat_id)
                .toList();
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      cat.cat_name ?? '',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  menusInCat.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text("ไม่มีเมนูในหมวดหมู่นี้"),
                        )
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: menusInCat.length,
                            itemBuilder: (context, index) {
                              final menu = menusInCat[index];
                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EditMenuPage(
                                        menu_id: menu.menu_id,
                                        restaurantCategories:
                                            _restaurantCategories,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await LoadResInfo();
                                    POP_UPMenu();
                                  }
                                },
                                child: Container(
                                  width: 150,
                                  margin: const EdgeInsets.only(left: 16),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(12)),
                                          child: Image.network(
                                            menu.menu_image ?? '',
                                            height: 100,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color: Colors.grey[300],
                                              height: 100,
                                              child: const Icon(Icons.fastfood,
                                                  size: 50),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            menu.menu_name ?? '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                            "฿${menu.menu_price?.toStringAsFixed(2) ?? '0.00'}",
                                            style: const TextStyle(
                                                color: Colors.green),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40.0)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2)),
        ],
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color.fromARGB(255, 115, 28, 168),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        iconSize: 20,
        selectedLabelStyle:
            const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'Order'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void POP_UPCaterogy() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("รายการหมวดหมู่เมนูที่มี"),
          content: SizedBox(
            width: double.maxFinite,
            // จำกัดความสูงสูงสุด แต่ยืดได้ตามข้อมูล
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.6, // สูงสุด 60% ของจอ
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // แสดงรายการหมวดหมู่
                    ..._restaurantCategories.map((cat) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(cat.cat_name ?? ''),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min, // ทำให้ Row กว้างแค่พอดีไอคอน
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  final TextEditingController
                                      _editCatController =
                                      TextEditingController(
                                          text: cat.cat_name ?? '');

                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text("แก้ไขชื่อหมวดหมู่"),
                                        content: TextField(
                                          controller: _editCatController,
                                          decoration: InputDecoration(
                                            hintText: 'กรอกชื่อหมวดหมู่',
                                            labelText: 'ชื่อหมวดหมู่',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // ยกเลิกปิด dialog
                                            },
                                            child: const Text("ยกเลิก"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final newName = _editCatController
                                                  .text
                                                  .trim();
                                              if (newName.isNotEmpty) {
                                                await UpdateCaterogy(newName,
                                                    cat.cat_id); // ถ้า UpdateCaterogy เป็น async รอให้เสร็จด้วย
                                                await LoadResInfo(); // โหลดข้อมูลใหม่รอให้เสร็จ
                                                Fluttertoast.showToast(
                                                    msg: "แก้ไขข้อมูลแล้ว",
                                                    backgroundColor:
                                                        Colors.green,
                                                    textColor: Colors.white);

                                                Navigator.of(context).pop();
                                                Navigator.of(context)
                                                    .pop(); // ปิด dialog แก้ไข

                                                // เปิด popup ใหม่ถ้าต้องการ
                                                POP_UPCaterogy();

                                                // หรือถ้าแค่ refresh หน้าจอที่มีข้อมูลก็เรียก setState() หรืออะไรก็ได้
                                              } else {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          "กรุณากรอกชื่อหมวดหมู่")),
                                                );
                                              }
                                            },
                                            child: const Text("บันทึก"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // โค้ดลบหมวดหมู่
                                  // แนะนำให้แสดง confirm dialog ก่อนลบจริง
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('ยืนยันการลบ'),
                                        content: Text(
                                            'ต้องการลบหมวดหมู่ "${cat.cat_name}" หรือไม่?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('ยกเลิก'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // เรียกฟังก์ชันลบหมวดหมู่ เช่น DeleteCategory(cat.cat_id);
                                              await DeleteCategory(cat.cat_id);
                                              await LoadResInfo();

                                              Navigator.of(context)
                                                  .pop(); // ปิด confirm dialog
                                              Navigator.of(context)
                                                  .pop(); // ปิด popup list หมวดหมู่

                                              // เปิด popup ใหม่ เพื่อ refresh ข้อมูล
                                              POP_UPCaterogy();

                                              Fluttertoast.showToast(
                                                msg: 'ลบหมวดหมู่เรียบร้อยแล้ว',
                                                backgroundColor: Colors.green,
                                                textColor: Colors.white,
                                              );
                                            },
                                            child: const Text('ตกลง'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    // ปุ่มเพิ่มหมวดหมู่
                    ElevatedButton.icon(
                      onPressed: () {
                        final TextEditingController _AddCatController =
                            TextEditingController();

                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("เพิ่มหมวดหมู่เมนูอาหาร"),
                              content: TextField(
                                controller:
                                    _AddCatController, // ผูก controller ที่นี่
                                decoration: InputDecoration(
                                  hintText: 'กรอกชื่อหมวดหมู่',
                                  labelText: 'ชื่อหมวดหมู่',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context)
                                        .pop(); // ยกเลิก ปิด dialog
                                  },
                                  child: const Text("ยกเลิก"),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    final newName =
                                        _AddCatController.text.trim();
                                    if (newName.isNotEmpty) {
                                      await AddCaterogy(
                                          newName); // รอเพิ่มข้อมูล
                                      await LoadResInfo(); // รอโหลดข้อมูลใหม่

                                      Fluttertoast.showToast(
                                        msg: "เพิ่มข้อมูลแล้ว",
                                        backgroundColor: Colors.green,
                                        textColor: Colors.white,
                                      );

                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop(); // ปิด dialog

                                      POP_UPCaterogy(); // เปิด popup ใหม่ถ้าต้องการ
                                    } else {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text("กรุณากรอกชื่อหมวดหมู่")),
                                      );
                                    }
                                  },
                                  child: const Text("บันทึก"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text("เพิ่มหมวดหมู่"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  void POP_UPMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("รายการเมนูที่มี"),
          content: SizedBox(
            width: double.maxFinite,
            // จำกัดความสูงสูงสุด แต่ยืดได้ตามข้อมูล
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height *
                    0.6, // สูงสุด 60% ของจอ
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // แสดงรายการหมวดหมู่
                    ..._restaurantMenu.map((men) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(men.menu_name ?? ''),
                          trailing: Row(
                            mainAxisSize:
                                MainAxisSize.min, // ทำให้ Row กว้างแค่พอดีไอคอน
                            children: [
                              IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.blue),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditMenuPage(
                                          menu_id: men.menu_id,
                                          restaurantCategories:
                                              _restaurantCategories,
                                        ),
                                      ),
                                    );

                                    if (result == true) {
                                      await LoadResInfo();
                                      Navigator.of(context).pop();
                                      POP_UPMenu();
                                    }
                                  }),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  // โค้ดลบหมวดหมู่
                                  // แนะนำให้แสดง confirm dialog ก่อนลบจริง
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('ยืนยันการลบ'),
                                        content: Text(
                                            'ต้องการลบเมนู "${men.menu_name}" หรือไม่?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: const Text('ยกเลิก'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              // เรียกฟังก์ชันลบเมนู
                                              await DeleteMenu(men.menu_id);
                                              await LoadResInfo();

                                              Navigator.of(context)
                                                  .pop(); // ปิด confirm dialog
                                              Navigator.of(context)
                                                  .pop(); // ปิด popup list หมวดหมู่

                                              // เปิด popup ใหม่ เพื่อ refresh ข้อมูล
                                              POP_UPMenu();

                                              Fluttertoast.showToast(
                                                msg: 'ลบหมวดหมู่เรียบร้อยแล้ว',
                                                backgroundColor: Colors.green,
                                                textColor: Colors.white,
                                              );
                                            },
                                            child: const Text('ตกลง'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    // ปุ่มเพิ่มเมนู
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddMenuPage(
                              restaurantCategories: _restaurantCategories,
                            ),
                          ),
                        );

                        if (result == true) {
                          await LoadResInfo();
                          Navigator.of(context).pop(); // รีเฟรชข้อมูล
                          POP_UPMenu();
                        }
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      label: const Text("เพิ่มเมนู",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  void POP_UPallOpcat() {
    bool hasAllOpCat = _AllOpcat.isNotEmpty;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("รายการหมวดหมู่ตัวเลือกเพิ่มเติมทั้งหมดของร้าน"),
          content: SizedBox(
            width: double.maxFinite,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!hasAllOpCat)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "เมนูนี้ยังไม่ได้เลือกหมวดหมู่เพิ่มเติม",
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    if (hasAllOpCat)
                      ..._AllOpcat!.map((opt) {
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(opt.opCatName ?? ''),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditOptionPage(
                                              op_cat_id: opt.opCatId),
                                        ),
                                      );

                                      if (result == true) {
                                        await loadAllCat();
                                        Navigator.of(context).pop();
                                        POP_UPallOpcat();
                                      }
                                    }),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    // ลบหมวดหมู่
                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          title: const Text('ยืนยันการลบ'),
                                          content: Text(
                                              'ต้องการลบหมวดหมู่ "${opt.opCatName}" ออกจากเมนูนี้หรือไม่?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: const Text('ยกเลิก'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () async {
                                                await DeleteInAllOpCat(
                                                    opt.opCatId);
                                                await loadAllCat();

                                                Navigator.of(context)
                                                    .pop(); // ปิด confirm
                                                Navigator.of(context)
                                                    .pop(); // ปิด popup list
                                                POP_UPallOpcat(); // refresh

                                                Fluttertoast.showToast(
                                                  msg:
                                                      'ลบหมวดหมู่เรียบร้อยแล้ว',
                                                  backgroundColor: Colors.green,
                                                  textColor: Colors.white,
                                                );
                                              },
                                              child: const Text('ตกลง'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 8),
                    // ปุ่มเพิ่มเมนู
                    ElevatedButton.icon(
                      onPressed: () async {
                        POP_UPAddOpcat();
                      },
                      icon: const Icon(
                        Icons.add,
                        color: Colors.white,
                      ),
                      label: const Text("เพิ่ม",
                          style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("ปิด"),
            ),
          ],
        );
      },
    );
  }

  void POP_UPAddOpcat() {
    final TextEditingController editCatController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("เพิ่มหมวดหมู่ตัวเลือกเพิ่มเติม"),
          content: TextField(
            controller: editCatController,
            decoration: const InputDecoration(
              hintText: 'กรอกชื่อหมวดหมู่',
              labelText: 'ชื่อหมวดหมู่',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // ปิด dialog
              child: const Text("ยกเลิก"),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = editCatController.text.trim();

                if (newName.isEmpty) {
                  Fluttertoast.showToast(
                    msg: "กรุณากรอกชื่อหมวดหมู่",
                    backgroundColor: Colors.orange,
                    textColor: Colors.white,
                  );
                  return;
                }

                try {
                  await AddNewOpCat(newName); // รอแก้ไขเสร็จ
                  Navigator.of(context).pop();
                  await loadAllCat(); // โหลดข้อมูลใหม่

                  Fluttertoast.showToast(
                    msg: "เพิ่มข้อมูลแล้ว",
                    backgroundColor: Colors.green,
                    textColor: Colors.white,
                  );

                  Navigator.of(context).pop(); // ปิด dialog ปัจจุบัน

                  // ถ้าต้องการเปิด popup อื่นต่อ
                  POP_UPallOpcat();
                } catch (e) {
                  Fluttertoast.showToast(
                    msg: "เกิดข้อผิดพลาด: $e",
                    backgroundColor: Colors.red,
                    textColor: Colors.white,
                  );
                }
              },
              child: const Text("บันทึก"),
            ),
          ],
        );
      },
    );
  }

  Future<void> LoadResInfo() async {
    try {
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/loadResInfo/${ResId}"));

      if (res_ResInfo.statusCode == 200) {
        final List<ResInfoResponse> list =
            (json.decode(res_ResInfo.body) as List)
                .map((e) => ResInfoResponse.fromJson(e))
                .toList();
        setState(() {
          _restaurantInfo = list;
          context.read<ShareData>().res_info = list.first;
        });
      }

      final res_Cat = await http.get(Uri.parse("$url/db/loadCat/${ResId}"));

      if (res_Cat.statusCode == 200) {
        final List<ResCatGetResponse> list = (json.decode(res_Cat.body) as List)
            .map((e) => ResCatGetResponse.fromJson(e))
            .toList();
        setState(() {
          _restaurantCategories = list;
        });
      }

      final res_Menu = await http.get(Uri.parse("$url/db/loadMenu/${ResId}"));
      log("Raw JSON from API: ${res_Menu.body}");
      if (res_Menu.statusCode == 200) {
        final List<MenuInfoGetResponse> list =
            (json.decode(res_Menu.body) as List)
                .map((e) => MenuInfoGetResponse.fromJson(e))
                .toList();
        setState(() {
          _restaurantMenu = list;
          context.read<ShareData>().all_menu_in_res = list;
          log("MENUUUUUUUUUUUUUUUUUUUUUUUU" + _restaurantMenu.toString());
        });
      }

      final Menu_check = await http.get(Uri.parse("$url/db/loadOpCatLink"));
      log("Raw JSON from API: ${Menu_check.body}");
      if (Menu_check.statusCode == 200) {
        final List<OpCatLinkGetResponse> list =
            (json.decode(Menu_check.body) as List)
                .map((e) => OpCatLinkGetResponse.fromJson(e))
                .toList();
        setState(() {
          _Menu_check = list;
          log("MENUUUUUUCKKKKKKKKKKKKKKKKKKKKKKKK" + _Menu_check.toString());
        });
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> loadAllCat() async {
    final res_id = context.read<ShareData>().user_info_send.uid;
    final res_Cat = await http.get(Uri.parse("$url/db/loadAllOpCat/${ResId}"));

    if (res_Cat.statusCode == 200) {
      final List<OpCatGetResponse> list = (json.decode(res_Cat.body) as List)
          .map((e) => OpCatGetResponse.fromJson(e))
          .toList();
      setState(() {
        _AllOpcat = list;
      });
    }
  }

  Future<void> AddNewOpCat(String NewOpCat) async {
    final res_id = context.read<ShareData>().user_info_send.uid;
    try {
      final opcat_add_to_menu = await http.post(
        Uri.parse("$url/db/add_op_cat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"op_cat_name": NewOpCat, "res_id": res_id}),
      );

      if (opcat_add_to_menu.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        log(opcat_add_to_menu.body);
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> UpdateCaterogy(String newName, int cat_id) async {
    try {
      final res_Add = await http.put(
        Uri.parse("$url/db/edit_catName"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "NewCatName": newName,
          "cat_id": cat_id,
        }),
      );

      if (res_Add.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> AddCaterogy(String newName) async {
    int res_id = context.read<ShareData>().user_info_send.uid;

    try {
      final res_Add = await http.post(
        Uri.parse("$url/db/add_catName"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "NewCatName": newName,
          "res_id": res_id,
        }),
      );

      if (res_Add.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> AddMenu(String name, String desc, double price, String imageUrl,
      int catId) async {
    try {
      final res_Add = await http.post(
        Uri.parse("$url/db/add_Menu"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "menu_name": name,
          "menu_des": desc,
          "menu_price": price,
          "menu_image": imageUrl,
          "cat_id": catId,
        }),
      );

      if (res_Add.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> DeleteCategory(int cat_id) async {
    try {
      final cat_del = await http.delete(
        Uri.parse("$url/db/delete_catName/${cat_id}"),
        headers: {"Content-Type": "application/json"},
      );

      if (cat_del.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> DeleteMenu(int menu_id) async {
    try {
      final men_del = await http.delete(
        Uri.parse("$url/db/delete_menu/${menu_id}"),
        headers: {"Content-Type": "application/json"},
      );

      if (men_del.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> DeleteInAllOpCat(int opCat_id) async {
    try {
      final opcat_del_from_menu = await http.delete(
        Uri.parse("$url/db/delete_opcat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"opCat_id": opCat_id}),
      );

      if (opcat_del_from_menu.statusCode == 200) {
        // ทำอย่างอื่นถ้าต้องการ
      } else {
        // handle error กรณี response ไม่ใช่ 200
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดจาก server",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
