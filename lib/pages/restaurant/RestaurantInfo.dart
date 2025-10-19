import 'dart:convert';
import 'dart:developer';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/Add_Cart_post_req.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusCartGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OpCatLinkGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Cart.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerHome.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/restaurant/Option.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class RestaurantinfoPage extends StatefulWidget {
  final int ResId;
  const RestaurantinfoPage({super.key, required this.ResId});

  @override
  State<RestaurantinfoPage> createState() => _HomePageState();
}

class _HomePageState extends State<RestaurantinfoPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isFavorite = false;
  bool _isDeleting = false;
  String? _address; // เก็บที่อยู่ที่ได้
  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
  List<OpCatLinkGetResponse> _Menu_check = [];
  Map<int, int> _selectedMenu_no_op = {};
  List<SelectedMenu> _selectedMenu_op = [];
  List<Map<String, dynamic>> mergedMenus = [];
  List<CusCartGetResponse> _Cus_CartInfo_Check = [];
  List<CusCartGetResponse> _Cus_CartInfo_thisRes = [];

  // เพิ่ม Map สำหรับเก็บ GlobalKey ของแต่ละหมวดหมู่
  Map<int, GlobalKey> _categoryKeys = {};

  List<MenuInfoGetResponse> get selectedMenus {
    return _restaurantMenu
        .where((menu) => _selectedMenu_no_op.containsKey(menu.menu_id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];

      context.read<ShareData>().res_id = widget.ResId;
      final allCart = context.read<ShareData>().cus_all_cart;
      context.read<ShareData>().orl_id = 0;
      log(jsonEncode(allCart) + " TEST CART");
      _Cus_CartInfo_Check =
          allCart.where((cart) => cart.resId == widget.ResId).toList();
      log("🛒 Found ${_Cus_CartInfo_Check.length} carts for ResID: ${widget.ResId}  Info:${jsonEncode(_Cus_CartInfo_Check)}");
      if (_Cus_CartInfo_Check.isNotEmpty) {
        context.read<ShareData>().orl_id = _Cus_CartInfo_Check[0].orlId;
      }
      log(context.read<ShareData>().orl_id.toString() +
          "XKASDKLAJDLAKJSDLAJDLAKJDSLASDJaLKJSDL");
      LoadCartRes();
      LoadResInfo();
      final cus_id = context.read<ShareData>().user_info_send.uid;
      OrderNotificationService().listenOrderChanges(context, cus_id,
          (orderId, newStep) {
        if (!mounted) return;
      });
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _getAddressFromCoordinates();
      });
    });
    _pageController = PageController();
  }

  // ฟังก์ชันเลื่อนไปยังหมวดหมู่
  void _scrollToCategory(int categoryId) {
    final key = _categoryKeys[categoryId];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // เลื่อนให้หมวดหมู่อยู่ด้านบนเล็กน้อย
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topAdd = context.watch<ShareData>().customer_addresses;
    int Cart_count = 0;
    log(context.read<ShareData>().orl_id.toString() + "TEST ORD_ID",
        stackTrace: StackTrace.current);

    // ✅ ย้ายการเช็ค orl_id มาไว้ด้านบนก่อน
    if (context.read<ShareData>().orl_id == 0) {
      _selectedMenu_no_op = {};
      _selectedMenu_op = [];
      _Cus_CartInfo_thisRes = [];
    } else {
      // ✅ ประมวลผลเฉพาะเมื่อมี cart
      for (var order in _Cus_CartInfo_thisRes) {
        final List<dynamic> details = order.orlOrderDetail;

        _selectedMenu_op = details
            .map((item) => SelectedMenu(
                  menuId: item['menu_id'],
                  menuName: item['menu_name'],
                  menuImage: item['menu_image'],
                  count: item['count'],
                  menuPrice: item['menu_price'],
                  selectedOptions: List<Map<String, dynamic>>.from(
                      item['selectedOptions'] ?? []),
                ))
            .toList();

        // ✅ สร้าง Map ชั่วคราวแทนการรีเซ็ตทันที
        Map<int, int> tempNoOp = {};
        for (var menu in _selectedMenu_op) {
          if (menu.selectedOptions.isEmpty) {
            tempNoOp[menu.menuId] = menu.count;
          }
        }

        // ✅ เก็บค่า count = 0 ที่ user กำลังลบอยู่
        _selectedMenu_no_op.forEach((key, value) {
          if (value == 0 && !tempNoOp.containsKey(key)) {
            tempNoOp[key] = 0;
          }
        });

        // ✅ อัปเดต Map ทีเดียว
        _selectedMenu_no_op = tempNoOp;

        log(_selectedMenu_no_op.toString() +
            " CHECK_SELECT_NO_OP เฉพาะเมนูไม่มี OP");

        // คำนวณ Cart_count ตามปกติ
        int orderCount =
            details.fold<int>(0, (sum, item) => sum + (item['count'] as int));
        Cart_count += orderCount;
      }
    }

    int totalCount = Cart_count;

    final CurrentRes =
        _Cus_CartInfo_thisRes.where((menu) => menu.resId == widget.ResId)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดร้านอาหาร"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => CustomerHomePage()),
            );
          },
        ),
      ),
      body: buildMainContent(),
      bottomSheet: _selectedMenu_no_op.isNotEmpty ||
              _selectedMenu_op.isNotEmpty ||
              _Cus_CartInfo_thisRes.isNotEmpty
          ? Container(
              height: 60,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "ในตะกร้า (${totalCount} รายการ)",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      mergedMenus.clear();
                      // จาก _selectedMenus (เมนูมี option)
                      mergedMenus.addAll(_selectedMenu_op.map((e) => {
                            "menu_id": e.menuId,
                            "menu_name": e.menuName,
                            "menu_image": e.menuImage,
                            "menu_price": e.menuPrice, // เพิ่มบรรทัดนี้
                            "count": e.count,
                            "selectedOptions": e.selectedOptions,
                          }));

                      // ส่งรายการไปหน้าตะกร้า
                      Get.to(() => CartPage(
                          mergedMenus: mergedMenus,
                          orl_id: context.read<ShareData>().orl_id));
                    },
                    child: const Text(
                      "สั่งซื้อ",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget buildCategoryChip(String label, int categoryId) {
    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.deepPurple, width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextButton(
          onPressed: () {
            // เลื่อนไปยังหมวดหมู่ที่เลือก
            _scrollToCategory(categoryId);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMainContent() {
    final Caterogy = context.watch<ShareData>().restaurant_type;
    final AllRes = context.watch<ShareData>().restaurant_all;
    final topAdd = context.watch<ShareData>().customer_addresses;

    final matchedRestaurant =
        AllRes.firstWhere((res) => res.res_id == widget.ResId);

    // ถ้าไม่มีพิกัดลูกค้า
    if (topAdd.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final customer = topAdd[0];

    // แยกพิกัดร้าน
    final coordsRes = matchedRestaurant.res_coordinate.split(',');
    final double resLat = double.parse(coordsRes[0]);
    final double resLng = double.parse(coordsRes[1]);

    // แยกพิกัดลูกค้า
    final coordsCus = customer.ca_coordinate.split(',');
    final double cusLat = double.parse(coordsCus[0]);
    final double cusLng = double.parse(coordsCus[1]);

    // คำนวณระยะทาง
    double distanceInMeters =
        Geolocator.distanceBetween(cusLat, cusLng, resLat, resLng);
    double distanceInKm = distanceInMeters / 1000;

    // คำนวณเวลาโดยเงื่อนไขที่ให้มา
    String deliveryTime;
    if (distanceInKm <= 1) {
      deliveryTime = "10 นาที";
    } else if (distanceInKm <= 2) {
      deliveryTime = "15 นาที";
    } else if (distanceInKm <= 3) {
      deliveryTime = "20 นาที";
    } else if (distanceInKm <= 4) {
      deliveryTime = "25 นาที";
    } else if (distanceInKm <= 5) {
      deliveryTime = "30 นาที";
    } else {
      deliveryTime = "35 นาทีขึ้นไป";
    }

    // สร้าง GlobalKey สำหรับแต่ละหมวดหมู่
    for (var category in _restaurantCategories) {
      if (!_categoryKeys.containsKey(category.cat_id)) {
        _categoryKeys[category.cat_id] = GlobalKey();
      }
    }

    List<Widget> categoryCards = _restaurantCategories
        .map((category) {
          final menusInCategory = _restaurantMenu
              .where((menu) => menu.cat_id == category.cat_id)
              .toList();

          if (menusInCategory.isEmpty) {
            // ถ้าไม่มีเมนูในหมวดนี้ ไม่ต้องแสดงอะไรเลย
            return SizedBox.shrink();
          }

          return Card(
            key: _categoryKeys[category.cat_id], // เพิ่ม key ให้กับ Card
            margin: const EdgeInsets.only(bottom: 20),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.cat_name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...menusInCategory
                      .map((menu) => buildMenuItem(menu))
                      .toList(),
                ],
              ),
            ),
          );
        })
        .where((widget) => widget is! SizedBox)
        .toList(); // กรอง SizedBox.shrink() ออก

    // ถ้าไม่มี card ไหนเลย แสดงข้อความ "ไม่มีเมนูในร้าน"
    if (categoryCards.isEmpty) {
      categoryCards.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: Text(
              "ไม่มีเมนูในร้าน",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 10, left: 30, right: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                matchedRestaurant.res_image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.fastfood, size: 60),
                loadingBuilder: (_, child, loading) {
                  if (loading == null) return child;
                  return const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    matchedRestaurant.res_name,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),

            Container(
              child: Text(
                (_address ?? "กำลังโหลดที่อยู่...").trimLeft(),
                style: const TextStyle(
                    fontSize: 15, height: 1.2, letterSpacing: 0),
                textAlign: TextAlign.left,
              ),
            ),

            const SizedBox(height: 10),

            // แถวแสดงระยะทาง + เวลาจัดส่ง
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  "ระยะทาง: ${distanceInKm.toStringAsFixed(2)} กม.",
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 15),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(
                        width: 4), // เว้นระยะห่างระหว่างไอคอนกับข้อความ
                    Text(
                      "เวลาจัดส่ง: $deliveryTime",
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            buildRatingStars(matchedRestaurant.res_rating),
            const SizedBox(
              height: 10,
            ),
            Text(
              "หมวดหมู่อาหารภายในร้าน",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _restaurantCategories.map((category) {
                  return buildCategoryChip(category.cat_name, category.cat_id);
                }).toList(),
              ),
            ),

            const SizedBox(height: 20),
            ...categoryCards,
          ],
        ),
      ),
    );
  }

  void _getAddressFromCoordinates() async {
    final AllRes = context.read<ShareData>().restaurant_all;
    final matchedRestaurant =
        AllRes.firstWhere((res) => res.res_id == widget.ResId);

    final coords = matchedRestaurant.res_coordinate.split(',');
    final double lat = double.parse(coords[0]);
    final double lng = double.parse(coords[1]);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;

        setState(() {
          _address =
              "${(place.subLocality ?? '').trim()} ${(place.locality ?? '').trim()} ${(place.administrativeArea ?? '').trim()} ${(place.postalCode ?? '').trim()}";
        });
      }
    } catch (e) {
      print("Error in geocoding: $e");
      setState(() {
        _address = "ไม่พบที่อยู่";
      });
    }
  }

  String calculateDeliveryTime({
    required double customerLat,
    required double customerLng,
    required double restaurantLat,
    required double restaurantLng,
  }) {
    double distanceInMeters = Geolocator.distanceBetween(
      customerLat,
      customerLng,
      restaurantLat,
      restaurantLng,
    );

    double distanceInKm = distanceInMeters / 1000;

    if (distanceInKm <= 1)
      return "10 นาที";
    else if (distanceInKm <= 2)
      return "15 นาที";
    else if (distanceInKm <= 3)
      return "20 นาที";
    else if (distanceInKm <= 4)
      return "25 นาที";
    else if (distanceInKm <= 5)
      return "30 นาที";
    else
      return "35 นาทีขึ้นไป";
  }

  Widget buildRatingStars(double rating) {
    List<Widget> stars = [];

    int fullStars = rating.floor(); // จำนวนดาวเต็ม
    bool hasHalfStar = (rating - fullStars) >= 0.5;
    int emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    // ดาวเต็ม
    for (int i = 0; i < fullStars; i++) {
      stars.add(const Icon(Icons.star, color: Colors.amber, size: 20));
    }

    // ดาวครึ่ง
    if (hasHalfStar) {
      stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 20));
    }

    // ดาวว่าง
    for (int i = 0; i < emptyStars; i++) {
      stars.add(const Icon(Icons.star_border, color: Colors.amber, size: 20));
    }

    // ตัวเลข rating ตามท้าย
    stars.add(const SizedBox(width: 6));
    stars.add(Text(
      "(${rating.toStringAsFixed(1)})",
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ));

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: stars,
    );
  }

  int getTotalCountForMenu(int menuId) {
    int total = 0;

    for (var order in _Cus_CartInfo_thisRes) {
      // แปลง String → List<dynamic>
      final List<dynamic> details = order.orlOrderDetail;

      for (var menu in details) {
        if (menu['menu_id'] == menuId) {
          total += menu['count'] as int;
        }
      }
    }

    return total;
  }

  Widget buildMenuItem(MenuInfoGetResponse menu) {
    var cal_count = getTotalCountForMenu(menu.menu_id);
    var count = _selectedMenu_no_op[menu.menu_id] ?? 0;

    // ✅ เช็คสถานะเมนู
    bool isDisabled = menu.menu_status == 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Opacity(
        // ✅ ถ้าเมนูถูกปิด (status == 0) จะทำให้จางลง
        opacity: isDisabled ? 0.4 : 1.0,
        child: IgnorePointer(
          // ✅ ถ้าเมนูปิด จะไม่สามารถกดได้เลย
          ignoring: isDisabled,
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // รูปภาพเมนู (สามารถกดได้)
                  InkWell(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        menu.menu_image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.fastfood),
                        // ✅ แปลงภาพเป็นขาวดำถ้าเมนูถูกปิด
                        color: isDisabled ? Colors.grey : null,
                        colorBlendMode:
                            isDisabled ? BlendMode.saturation : BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ข้อมูลเมนู (ชื่อ + ราคา)
                  Expanded(
                    child: InkWell(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            menu.menu_name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "${menu.menu_price} บาท",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ปุ่ม + / -
                  if (!isDisabled)
                    Row(
                      children: [
                        if (_Menu_check.any(
                            (item) => item.menu_id == menu.menu_id))
                          cal_count > 0
                              ? GestureDetector(
                                  onTap: () {
                                    _showEditMenuDialog(menu.menu_id);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '$cal_count',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OptionPage(menu_id: menu.menu_id),
                                      ),
                                    );

                                    if (result != null && result is Map) {
                                      final int returnedMenuId =
                                          result['menu_id'];
                                      final String returnedMenuName =
                                          result['menu_name'];
                                      final String returnedMenuImage =
                                          result['menu_image'];
                                      final int returnedCount = result['count'];
                                      final int returnedPrice = result['price'];
                                      final List<Map<String, dynamic>>
                                          returnedOptions =
                                          List<Map<String, dynamic>>.from(
                                              result['selectedOptions']);

                                      setState(() async {
                                        var model = AddCartPostRequest(
                                          menuId: returnedMenuId,
                                          menuName: returnedMenuName,
                                          menuImage: returnedMenuImage,
                                          count: returnedCount,
                                          menuPrice: returnedPrice,
                                          selectedOptions: returnedOptions,
                                        );

                                        log("Add to Cart: ${AddCartPostRequestToJson(model)}");
                                        await AddToCart(model);
                                        await LoadOrl_id();
                                        LoadCartRes();

                                        _selectedMenu_op.add(
                                          SelectedMenu(
                                            menuId: returnedMenuId,
                                            menuName: returnedMenuName,
                                            menuImage: returnedMenuImage,
                                            count: returnedCount,
                                            menuPrice: returnedPrice,
                                            selectedOptions: returnedOptions,
                                          ),
                                        );
                                      });
                                    }
                                  },
                                )
                        else
                        // เมนูไม่มี option
                        if (!isDisabled)
                          Row(
                            children: [
                              if (count > 0)
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      if (_selectedMenu_no_op[menu.menu_id]! >
                                          1) {
                                        _selectedMenu_no_op[menu.menu_id] =
                                            _selectedMenu_no_op[menu.menu_id]! -
                                                1;
                                      } else {
                                        _selectedMenu_no_op[menu.menu_id] = 0;
                                      }
                                    });

                                    EasyDebounce.debounce(
                                      'remove-from-cart-${menu.menu_id}',
                                      const Duration(milliseconds: 500),
                                      () async {
                                        final currentCount =
                                            _selectedMenu_no_op[menu.menu_id] ??
                                                0;
                                        int Last_count =
                                            currentCount > 1 ? 1 : -1;

                                        await RemoveFromCart(
                                          menu.menu_id,
                                          Last_count,
                                          [],
                                        );

                                        await LoadCartRes();

                                        if (mounted) {
                                          setState(() {
                                            if (_selectedMenu_no_op[
                                                    menu.menu_id] ==
                                                0) {
                                              _selectedMenu_no_op
                                                  .remove(menu.menu_id);
                                            }
                                          });
                                        }
                                      },
                                    );
                                  },
                                ),
                              if (count > 0)
                                Text(
                                  '$count',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    _selectedMenu_no_op[menu.menu_id] =
                                        (_selectedMenu_no_op[menu.menu_id] ??
                                                0) +
                                            1;
                                  });

                                  EasyDebounce.debounce(
                                    'add-to-cart-${menu.menu_id}',
                                    const Duration(milliseconds: 500),
                                    () async {
                                      var model = AddCartPostRequest(
                                        menuId: menu.menu_id,
                                        menuName: menu.menu_name,
                                        menuImage: menu.menu_image,
                                        count: 1,
                                        menuPrice: menu.menu_price,
                                        selectedOptions: [],
                                      );

                                      log("Add to Cart: ${AddCartPostRequestToJson(model)}");
                                      await AddToCart(model);
                                      await LoadOrl_id();
                                      LoadCartRes();
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                      ],
                    )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditMenuDialog(int menu_id) {
    showDialog(
      context: context,
      barrierDismissible: !_isDeleting, // ปิดได้เมื่อไม่ได้ loading เท่านั้น
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // ย้าย filteredMenus มาไว้ใน builder เพื่อให้อัพเดททุกครั้ง
            final filteredMenus =
                _selectedMenu_op.where((m) => m.menuId == menu_id).toList();

            return AlertDialog(
              title: const Text('แก้ไขเมนู'),
              content: SizedBox(
                height: 300,
                width: double.maxFinite,
                child: _isDeleting
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('กำลังลบรายการ...'),
                          ],
                        ),
                      )
                    : filteredMenus.isEmpty
                        ? const Center(
                            child: Text('ไม่มีรายการในตะกร้า'),
                          )
                        : ListView.builder(
                            itemCount: filteredMenus.length,
                            itemBuilder: (context, index) {
                              final menu = filteredMenus[index];

                              return Slidable(
                                key: ValueKey(
                                    "${menu.menuId}_${menu.selectedOptions}"),
                                endActionPane: ActionPane(
                                  motion: const DrawerMotion(),
                                  children: [
                                    CustomSlidableAction(
                                      onPressed: (context) async {
                                        // เริ่ม loading
                                        setDialogState(() {
                                          _isDeleting = true;
                                        });

                                        await RemoveFromCart(
                                          menu.menuId,
                                          -2,
                                          menu.selectedOptions,
                                        );
                                        LoadCartRes();

                                        // รอสักครู่ (simulate processing)
                                        await Future.delayed(
                                            const Duration(milliseconds: 800));

                                        // ลบข้อมูลจริง
                                        final indexToRemove =
                                            _selectedMenu_op.indexWhere((m) =>
                                                m.menuId == menu.menuId &&
                                                _isSameOption(m.selectedOptions,
                                                    menu.selectedOptions));
                                        if (indexToRemove != -1) {
                                          _selectedMenu_op
                                              .removeAt(indexToRemove);
                                        }

                                        // หยุด loading และ refresh dialog
                                        setDialogState(() {
                                          _isDeleting = false;
                                        });

                                        // อัพเดท main widget state เพื่อให้ UI หลักเปลี่ยน
                                        setState(() {});
                                      },
                                      backgroundColor: Colors.red,
                                      borderRadius: BorderRadius.circular(90),
                                      padding: const EdgeInsets.all(1),
                                      child: SizedBox(
                                        width: 35,
                                        height: 35,
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                child: Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    leading: Image.network(
                                      menu.menuImage,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                    ),
                                    title: Text(menu.menuName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: menu.selectedOptions.map((op) {
                                        return Text(
                                          '${op['op_name']}',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        );
                                      }).toList(),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        GestureDetector(
                                          onTap: () async {
                                            Navigator.pop(context);
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    OptionPage(
                                                  menu_id: menu.menuId,
                                                  initSelectedOptions:
                                                      menu.selectedOptions,
                                                  initCount: menu.count,
                                                ),
                                              ),
                                            );

                                            if (result != null &&
                                                result
                                                    is Map<String, dynamic>) {
                                              var model = AddCartPostRequest(
                                                  menuId: result['menu_id'],
                                                  menuName:
                                                      result['menu_name'] +
                                                          "NM",
                                                  menuImage:
                                                      result['menu_image'],
                                                  count: result['count'],
                                                  menuPrice: result['price'],
                                                  selectedOptions: List<
                                                      Map<String,
                                                          dynamic>>.from(result[
                                                      'selectedOptions']));

                                              log("Add to Cart: ${AddCartPostRequestToJson(model)}");

                                              if (menu.menuId ==
                                                      result[
                                                          'original_menu_id'] &&
                                                  !_isSameOption(
                                                      result['selectedOptions'],
                                                      result[
                                                          'originalOptions'])) {
                                                await ReplaceMenu(
                                                    result['original_menu_id'],
                                                    result['originalOptions']);
                                                var model_replace =
                                                    AddCartPostRequest(
                                                        menuId:
                                                            result['menu_id'],
                                                        menuName:
                                                            result['menu_name'],
                                                        menuImage: result[
                                                            'menu_image'],
                                                        count: result['count'],
                                                        menuPrice:
                                                            result['price'],
                                                        selectedOptions: List<
                                                            Map<String,
                                                                dynamic>>.from(result[
                                                            'selectedOptions']));
                                                await AddToCart(model_replace);
                                                LoadCartRes();
                                              } else {
                                                await AddToCart(model);
                                                LoadCartRes();
                                              }

                                              final updatedMenu = SelectedMenu(
                                                menuId: result['menu_id'],
                                                menuName: result['menu_name'],
                                                menuImage: result['menu_image'],
                                                count: result['count'],
                                                menuPrice: result['price'],
                                                selectedOptions: List<
                                                        Map<String,
                                                            dynamic>>.from(
                                                    result['selectedOptions']),
                                              );

                                              setState(() {
                                                log("menuId: ${menu.menuId}, original: ${result['original_menu_id']}");
                                                log("selectedOptions: ${jsonEncode(menu.selectedOptions)}");
                                                log("originalOptions: ${jsonEncode(result['originalOptions'])}");
                                                log("isSameOption: ${_isSameOption(menu.selectedOptions, result['originalOptions'])}");

                                                final indexToRemove =
                                                    _selectedMenu_op.indexWhere((m) =>
                                                        m.menuId ==
                                                            result[
                                                                'original_menu_id'] &&
                                                        _isSameOption(
                                                            m.selectedOptions,
                                                            List<
                                                                Map<String,
                                                                    dynamic>>.from(result[
                                                                'originalOptions'])));

                                                if (indexToRemove != -1) {
                                                  _selectedMenu_op
                                                      .removeAt(indexToRemove);
                                                }

                                                final existingIndex =
                                                    _selectedMenu_op.indexWhere((m) =>
                                                        m.menuId ==
                                                            updatedMenu
                                                                .menuId &&
                                                        _isSameOption(
                                                            m.selectedOptions,
                                                            updatedMenu
                                                                .selectedOptions));

                                                if (existingIndex != -1) {
                                                  final existing =
                                                      _selectedMenu_op[
                                                          existingIndex];
                                                  _selectedMenu_op[
                                                          existingIndex] =
                                                      SelectedMenu(
                                                    menuId: existing.menuId,
                                                    menuName: existing.menuName,
                                                    menuImage:
                                                        existing.menuImage,
                                                    count: existing.count +
                                                        updatedMenu.count,
                                                    menuPrice:
                                                        existing.menuPrice,
                                                    selectedOptions: existing
                                                        .selectedOptions,
                                                  );
                                                } else {
                                                  _selectedMenu_op
                                                      .add(updatedMenu);
                                                }
                                              });
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              '${menu.count}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              actions: [
                if (!_isDeleting &&
                    filteredMenus
                        .isNotEmpty) // แสดงปุ่มเฉพาะเมื่อไม่ loading และมีรายการ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.deepPurple,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);

                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OptionPage(menu_id: menu_id),
                          ),
                        );

                        if (result != null && result is Map) {
                          final int returnedMenuId = result['menu_id'];
                          final String returnedMenuName = result['menu_name'];
                          final String returnedMenuImage = result['menu_image'];
                          final int returnedCount = result['count'];
                          final int returnedPrice = result['price'];
                          final List<Map<String, dynamic>> returnedOptions =
                              List<Map<String, dynamic>>.from(
                                  result['selectedOptions']);

                          setState(() async {
                            var model = AddCartPostRequest(
                              menuId: returnedMenuId,
                              menuName: returnedMenuName,
                              menuImage: returnedMenuImage,
                              count: returnedCount,
                              menuPrice: returnedPrice,
                              selectedOptions: returnedOptions,
                            );

                            log("Add to Cart: ${AddCartPostRequestToJson(model)}");
                            await AddToCart(model);
                            LoadCartRes();

                            bool found = false;

                            for (int i = 0; i < _selectedMenu_op.length; i++) {
                              final existing = _selectedMenu_op[i];
                              if (existing.menuId == returnedMenuId &&
                                  _isSameOption(existing.selectedOptions,
                                      returnedOptions)) {
                                _selectedMenu_op[i] = SelectedMenu(
                                  menuId: existing.menuId,
                                  menuName: existing.menuName,
                                  menuImage: existing.menuImage,
                                  count: existing.count + returnedCount,
                                  menuPrice: existing.menuPrice,
                                  selectedOptions: existing.selectedOptions,
                                );
                                found = true;
                                break;
                              }
                            }

                            if (!found) {
                              _selectedMenu_op.add(
                                SelectedMenu(
                                  menuId: returnedMenuId,
                                  menuName: returnedMenuName,
                                  menuImage: returnedMenuImage,
                                  count: returnedCount,
                                  menuPrice: returnedPrice,
                                  selectedOptions: returnedOptions,
                                ),
                              );
                            }
                          });
                        }
                      },
                      child: const Text(
                        "ต้องการสั่งเมนูนี้เพิ่ม",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                if (_isDeleting ||
                    filteredMenus
                        .isEmpty) // ปุ่มปิดเมื่อ loading หรือไม่มีรายการ
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isDeleting
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      child: Text(
                        _isDeleting ? "กำลังประมวลผล..." : "ปิด",
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  bool _isSameOption(
      List<Map<String, dynamic>> a, List<Map<String, dynamic>> b) {
    if (a.length != b.length) return false;

    a.sort((x, y) => x['op_cat_id'].compareTo(y['op_cat_id']));
    b.sort((x, y) => x['op_cat_id'].compareTo(y['op_cat_id']));

    for (int i = 0; i < a.length; i++) {
      if (a[i]['op_cat_id'] != b[i]['op_cat_id'] ||
          a[i]['op_id'] != b[i]['op_id']) {
        return false;
      }
    }

    return true;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void LoadResInfo() async {
    try {
      int userId = context.read<ShareData>().user_info_send.uid;

      context.read<ShareData>().customer_addresses = [];
      final res_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$userId"));
      if (res_Add.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(res_Add.body);
        final List<CusAddressGetResponse> res_addList =
            jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();
        if (res_addList.isNotEmpty) {
          context.read<ShareData>().customer_addresses = [res_addList[0]];
        }
      }

      final res_Cat =
          await http.get(Uri.parse("$url/db/loadCat/${widget.ResId}"));

      if (res_Cat.statusCode == 200) {
        final List<ResCatGetResponse> list = (json.decode(res_Cat.body) as List)
            .map((e) => ResCatGetResponse.fromJson(e))
            .toList();
        setState(() {
          _restaurantCategories = list;
        });
      }

      final res_Menu =
          await http.get(Uri.parse("$url/db/loadMenu/${widget.ResId}"));
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

  Future<void> LoadCartRes() async {
    int orl_id = context.read<ShareData>().orl_id;
    final Cart_res =
        await http.get(Uri.parse("$url/db/loadCusCartRes/$orl_id"));
    log("Raw JSON from API: ${Cart_res.body}");

    if (Cart_res.statusCode == 200) {
      final List<CusCartGetResponse> list = (json.decode(Cart_res.body) as List)
          .map((e) => CusCartGetResponse.fromJson(e))
          .toList();

      setState(() {
        _Cus_CartInfo_thisRes = list;
        log("Cart Check: $_Cus_CartInfo_thisRes");
      });
    } else {
      context.read<ShareData>().orl_id = 0;
      _Cus_CartInfo_thisRes = [];
      log(context.read<ShareData>().orl_id.toString() + "NO CART");
    }
  }

  Future<void> AddToCart(AddCartPostRequest model) async {
    final cus_id = context.read<ShareData>().user_info_send.uid;
    var Value = await http.post(Uri.parse("$url/db/AddToCart/${cus_id}"),
        headers: {"Content-Type": "application/json; charset=utf-8"},
        body: AddCartPostRequestToJson(model));

    if (Value.statusCode == 200) {
      log('AddToCart is successful');
    } else {
      // ถ้า status code ไม่ใช่ 200 ให้ดึงข้อความจาก response body
      var responseBody = jsonDecode(Value.body);
      setState(() {
        Fluttertoast.showToast(
            msg: "เพิ่มเมนูใส่ตะกร้าไม่สำเร็จ!!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            // backgroundColor: Color.fromARGB(120, 0, 0, 0),
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      });
      log(responseBody['error']);
    }
  }

  Future<void> RemoveFromCart(
      int menuId, int count, List<dynamic> selectedOptions) async {
    final cus_id = context.read<ShareData>().user_info_send.uid;

    final Value = await http.put(
      Uri.parse("$url/db/RemoveFromCart/$cus_id"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode({
        "menu_id": menuId,
        "orl_id": context.read<ShareData>().orl_id,
        "count": count,
        "selectedOptions": selectedOptions,
      }),
    );

    if (Value.statusCode == 200) {
      log('✅ RemoveFromCart is successful');
    } else {
      var responseBody = jsonDecode(Value.body);
      Fluttertoast.showToast(msg: "ลบเมนูออกจากตะกร้าไม่สำเร็จ!!!");
      log("❌ ${responseBody['error']}");
    }
  }

  Future<void> ReplaceMenu(int menuId, List<dynamic> selectedOptions) async {
    final cus_id = context.read<ShareData>().user_info_send.uid;
    log(selectedOptions.toString() + "SELECTED OP");
    var Value = await http.put(
      Uri.parse("$url/db/ReplaceToCart/${cus_id}"),
      headers: {"Content-Type": "application/json; charset=utf-8"},
      body: jsonEncode({
        "menu_id": menuId,
        "selectedOptions": selectedOptions,
      }),
    );

    if (Value.statusCode == 200) {
      log('AddToCart is successful');
    } else {
      // ถ้า status code ไม่ใช่ 200 ให้ดึงข้อความจาก response body
      var responseBody = jsonDecode(Value.body);
      setState(() {
        log(responseBody['error'] + "REPLACERCERCERCER");
        Fluttertoast.showToast(
            msg: "เปลี่ยนแปลงเมนูใส่ตะกร้าไม่สำเร็จ!!!",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.CENTER,
            timeInSecForIosWeb: 1,
            // backgroundColor: Color.fromARGB(120, 0, 0, 0),
            backgroundColor: Color.fromARGB(255, 255, 0, 0),
            textColor: Colors.white,
            fontSize: 15.0);
      });
      log(responseBody['error']);
    }
  }

  Future<void> LoadOrl_id() async {
    final cus_id = context.read<ShareData>().user_info_send.uid;
    final orl_res =
        await http.get(Uri.parse("$url/db/loadOrl_id/$cus_id/${widget.ResId}"));
    log("FROM LoadOrl_id API: ${orl_res.body}");

    if (orl_res.statusCode == 200) {
      final data = jsonDecode(orl_res.body) as List<dynamic>;
      setState(() {
        context.read<ShareData>().orl_id = data[0]['orl_id'];
      });
    }
  }
}
