import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OpCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OpCatLinkGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
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
                text: _restaurantInfo.isEmpty
                    ? 'กำลังโหลด...'
                    : _restaurantInfo.first.res_name,
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
          if (_restaurantCategories.isEmpty)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "กรุณาเพิ่มหมวดหมู่เมนูก่อนเป็นอันดับแรก",
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4.0, horizontal: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20, // ขนาดไอคอนใหญ่ขึ้นเล็กน้อย
                          ),
                          const SizedBox(width: 6), // spacing เพิ่มขึ้นเล็กน้อย
                          Text(
                            "Rating: ${_restaurantInfo[0].res_rating?.toStringAsFixed(1) ?? "0.0"}",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500, // ตัวหนังสือชัดขึ้น
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _restaurantInfo[0].res_open_status == 1
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red
                                .withOpacity(0.1), // สี background จาง ๆ
                        border: Border.all(
                          color: _restaurantInfo[0].res_open_status == 1
                              ? Colors.green
                              : Colors.red, // สีขอบ
                        ),
                        borderRadius: BorderRadius.circular(12), // มุมโค้ง
                      ),
                      child: Text(
                        _restaurantInfo[0].res_open_status == 1
                            ? "ร้านเปิด"
                            : "ร้านปิด",
                        style: TextStyle(
                          color: _restaurantInfo[0].res_open_status == 1
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 50),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // เหรียญ D
                          Container(
                            width: 25,
                            height: 25,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.amber,
                            ),
                            child: const Center(
                              child: Text(
                                'D',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                              width: 6), // เว้นระยะระหว่างเหรียญกับตัวเลข
                          Text(
                            NumberFormat('#,###').format(context
                                .read<ShareData>()
                                .user_info_send
                                .balance),
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                // Description
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 4.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.description_outlined,
                        color: Colors.deepPurple, // เปลี่ยนสีให้เด่นขึ้น
                        size: 20,
                      ),
                      const SizedBox(width: 8), // spacing เพิ่มขึ้น
                      Flexible(
                        child: Text(
                          "Description: ${_restaurantInfo[0].res_description ?? 'ไม่มีรายละเอียด'}",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500, // ตัวหนังสือชัดขึ้น
                            height: 1.4, // ระยะบรรทัดสวยขึ้น
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ปุ่มจัดการ
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
                  child: Wrap(
                    spacing: 12, // ระยะห่างแนวนอน
                    runSpacing: 12, // ระยะห่างแนวตั้ง
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => POP_UPCaterogy(),
                        icon: const Icon(Icons.category, color: Colors.amber),
                        label: const Text(
                          "จัดการหมวดหมู่เมนู",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple, // สีเดียวกัน
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => POP_UPMenu(),
                        icon: const Icon(Icons.fastfood, color: Colors.amber),
                        label: const Text(
                          "จัดการเมนู",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await loadAllOpCat();
                          POP_UPallOpcat();
                        },
                        icon:
                            const Icon(Icons.playlist_add, color: Colors.amber),
                        label: const Text(
                          "จัดการหมวดหมู่ตัวเลือกเพิ่มเติม",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await ChangeOpen();
                          await LoadResInfo();
                          if (mounted) setState(() {});
                        },
                        icon: const Icon(Icons.restaurant_menu,
                            color: Colors.amber),
                        label: const Text(
                          "เปิด/ปิด ร้าน",
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
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
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GridView.builder(
                            shrinkWrap:
                                true, // สำคัญ: ให้ GridView ปรับขนาดตามเนื้อหา
                            physics:
                                const NeverScrollableScrollPhysics(), // ป้องกันการ scroll ซ้อนกัน
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2, // 2 คอลัมน์
                              childAspectRatio:
                                  0.8, // อัตราส่วนความกว้าง:ความสูง
                              crossAxisSpacing: 10, // ระยะห่างระหว่างคอลัมน์
                              mainAxisSpacing: 10, // ระยะห่างระหว่างแถว
                            ),
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
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2, // ให้พื้นที่รูปภาพมากกว่า
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                  top: Radius.circular(12)),
                                          child: Image.network(
                                            menu.menu_image ?? '',
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                              color: Colors.grey[300],
                                              child: const Icon(Icons.fastfood,
                                                  size: 40),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1, // พื้นที่สำหรับข้อความ
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    menu.menu_name ?? '',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  GestureDetector(
                                                    onTap: () {
                                                      ChangMenuActivate(
                                                          menu.menu_id);
                                                      setState(() {
                                                        LoadResInfo();
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 25,
                                                      height: 25,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color:
                                                            menu.menu_status ==
                                                                    1
                                                                ? Colors.green
                                                                : Colors.red,
                                                      ),
                                                      child: Icon(
                                                        menu.menu_status == 1
                                                            ? Icons.check
                                                            : Icons.close,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                "฿${menu.menu_price?.toStringAsFixed(2) ?? '0.00'}",
                                                style: const TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
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
                                        Navigator.of(context)
                                            .pop(); // ปิด dialog

                                        POP_UPCaterogy(); // เปิด popup ใหม่ถ้าต้องการ
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
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        label: const Text("เพิ่มหมวดหมู่",
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                        ))
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
                          "ร้านไม่มีหมวดหมู่เพิ่มเติม",
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
                                        await loadAllOpCat();
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
                                                await loadAllOpCat();

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
                  await loadAllOpCat(); // โหลดข้อมูลใหม่

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
      int userId = context.read<ShareData>().user_info_send.uid;

      final res_balance =
          await http.get(Uri.parse("$url/db/loadResbalance/$userId"));
      print('Status code: ${res_balance.statusCode}');
      print('Response body: ${res_balance.body}');

      if (res_balance.statusCode == 200) {
        final data = jsonDecode(res_balance.body);
        final double balance = (data['balance'] as num).toDouble();
        context.read<ShareData>().user_info_send.balance = balance;
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
      }

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
      log("LoadResHome Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> loadAllOpCat() async {
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

  Future<void> ChangeOpen() async {
    final res_Change =
        await http.put(Uri.parse("$url/db/ChangOpenStatus/${ResId}"));

    if (res_Change.statusCode == 200) {
      Fluttertoast.showToast(
        msg: "เปลี่ยนสถานะสำเร็จ",
        backgroundColor: Color.fromARGB(255, 69, 220, 39),
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "เปลี่ยนสถานะผิดพลาด",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  Future<void> ChangMenuActivate(int menu_id) async {
    final men_Change =
        await http.put(Uri.parse("$url/db/ChangMenuStatus/${menu_id}"));

    if (men_Change.statusCode == 200) {
      Fluttertoast.showToast(
        msg: "เปลี่ยนสถานะสำเร็จ",
        backgroundColor: Color.fromARGB(255, 69, 220, 39),
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "เปลี่ยนสถานะผิดพลาด",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
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
          msg: "ไม่สามารถลบหมวดหมู่ที่มีการใช้งานอยู่ได้",
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
