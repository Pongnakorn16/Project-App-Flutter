import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/restaurant/Option.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class OptionPage extends StatefulWidget {
  final int menu_id;
  final List<Map<String, dynamic>>? initSelectedOptions;
  final int? initCount;
  final int? menuIndex;
  const OptionPage({
    super.key,
    this.initSelectedOptions,
    required this.menu_id,
    this.initCount,
    this.menuIndex,
  });

  @override
  State<OptionPage> createState() => _HomePageState();
}

class _HomePageState extends State<OptionPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';
  bool isFavorite = false;
  String? _address; // เก็บที่อยู่ที่ได้
  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
  OptionGetResponse? _restaurantOption;
  int _menuCount = 1; // จำนวนเมนูที่สั่ง
  Map<int, int> _selectedOptions = {}; // op_cat_id -> op_id ที่เลือก

  Map<int, int> _selectedMenuCounts = {};
  List<MenuInfoGetResponse> get selectedMenus {
    return _restaurantMenu
        .where((menu) => _selectedMenuCounts.containsKey(menu.menu_id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    // ✅ โหลดค่าจาก parameter ที่ส่งเข้ามา
    if (widget.initSelectedOptions != null) {
      for (var option in widget.initSelectedOptions!) {
        final opCatId = option['op_cat_id'];
        final opId = option['op_id'];
        _selectedOptions[opCatId] = opId;
      }
    }

    if (widget.initCount != null) {
      _menuCount = widget.initCount!;
    }
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadResInfo();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    });
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายละเอียดตัวเลือกเพิ่มเติม"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // กดแล้วกลับไปหน้าก่อนหน้า
          },
        ),
      ),
      body: buildMainContent(),
    );
  }

  Widget buildMainContent() {
    final menu_in_res = context.watch<ShareData>().all_menu_in_res;
    final matchedMenu =
        menu_in_res.firstWhere((men) => men.menu_id == widget.menu_id);

    if (_restaurantOption == null) {
      return const Center(child: CircularProgressIndicator());
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
                matchedMenu.menu_image,
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
                    matchedMenu.menu_name,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            /// ✅ แสดงหมวดหมู่ + options ตาม op_cat_id
            ..._restaurantOption!.categories.map((category) {
              final catOptions = _restaurantOption!.options
                  .where((op) => op.opCatId == category.opCatId)
                  .toList();

              // ถ้าไม่มี options → แสดงแค่ปุ่มเพิ่มลด
              if (catOptions.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.opCatName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            setState(() {
                              if (_menuCount > 1) _menuCount--;
                            });
                          },
                        ),
                        Text('$_menuCount',
                            style: const TextStyle(fontSize: 18)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() {
                              _menuCount++;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                );
              }

              // ถ้ามี options → แสดงหมวดพร้อม radio ให้เลือก
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.opCatName,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      ...catOptions.map((op) => RadioListTile<int>(
                            title: Text(op.opName),
                            subtitle: op.opPrice == 0
                                ? null
                                : Text("+${op.opPrice} บาท"),
                            value: op.opId,
                            groupValue: _selectedOptions[category.opCatId],
                            onChanged: (value) {
                              setState(() {
                                _selectedOptions[category.opCatId] = value!;
                              });
                            },
                          )),
                    ],
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: () {
                    setState(() {
                      if (_menuCount > 1) _menuCount--;
                    });
                  },
                ),
                Text('$_menuCount', style: const TextStyle(fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      _menuCount++;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // ✅ ตรวจสอบว่าผู้ใช้เลือก Option ครบทุกหมวดหมู่หรือไม่
                    if (!_validateAllOptionsSelected()) {
                      Fluttertoast.showToast(
                        msg: "กรุณาเลือกตัวเลือกเพิ่มเติมให้ครบก่อน",
                        backgroundColor: Colors.amber,
                        textColor: Colors.white,
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                      );
                      return; // หยุดการดำเนินการ
                    }

                    final selectedOptionsWithNames =
                        _selectedOptions.entries.map((entry) {
                      final opCatId = entry.key;
                      final opId = entry.value;

                      final catName = _restaurantOption!.categories
                          .firstWhere((cat) => cat.opCatId == opCatId)
                          .opCatName;

                      final opData = _restaurantOption!.options
                          .firstWhere((op) => op.opId == opId);

                      return {
                        'op_cat_id': opCatId,
                        'op_cat_name': catName,
                        'op_id': opId,
                        'op_name': opData.opName,
                        'op_price': opData.opPrice,
                      };
                    }).toList();

                    final matchedMenu = context
                        .read<ShareData>()
                        .all_menu_in_res
                        .firstWhere((men) => men.menu_id == widget.menu_id);

                    Navigator.pop(context, {
                      'menu_id': widget.menu_id,
                      'menu_name': matchedMenu.menu_name,
                      'menu_image': matchedMenu.menu_image,
                      'price': matchedMenu.menu_price,
                      'count': _menuCount,
                      'selectedOptions': selectedOptionsWithNames,

                      // ส่งค่าเมนูเดิมเพื่อจะได้ลบออกได้
                      'original_menu_id': widget.menu_id,
                      'originalOptions': widget.initSelectedOptions,
                    });
                  },
                  child: Text(
                    widget.initSelectedOptions != null
                        ? "อัปเดตตระกร้า"
                        : "เพิ่มลงในตะกร้า",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// ✅ ฟังก์ชันตรวจสอบว่าเลือก Option ครบทุกหมวดหมู่หรือไม่
  bool _validateAllOptionsSelected() {
    if (_restaurantOption == null) return false;

    // หาทุกหมวดหมู่ที่มี options (ไม่ใช่หมวดเปล่าๆ)
    for (var category in _restaurantOption!.categories) {
      final catOptions = _restaurantOption!.options
          .where((op) => op.opCatId == category.opCatId)
          .toList();

      // ถ้าหมวดนี้มี options แต่ยังไม่ได้เลือก
      if (catOptions.isNotEmpty) {
        // ตรวจสอบว่าได้เลือก option ในหมวดนี้หรือยัง
        final selectedOptionId = _selectedOptions[category.opCatId];
        if (selectedOptionId == null) {
          return false; // ยังไม่ได้เลือกในหมวดนี้
        }

        // ตรวจสอบว่า option ที่เลือกมีอยู่จริงในหมวดนี้หรือไม่
        bool optionExists = catOptions.any((op) => op.opId == selectedOptionId);
        if (!optionExists) {
          return false; // option ที่เลือกไม่มีอยู่ในหมวดนี้
        }
      }
    }

    return true; // เลือกครบทุกหมวดแล้ว
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void LoadResInfo() async {
    try {
      int userId = context.read<ShareData>().user_info_send.uid;

      var menu_id = widget.menu_id;

      final res = await http.get(Uri.parse("$url/db/loadOption/$menu_id"));
      if (res.statusCode == 200) {
        final OptionGetResponse data =
            OptionGetResponse.fromJson(json.decode(res.body));
        setState(() {
          _restaurantOption = data;
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
}
