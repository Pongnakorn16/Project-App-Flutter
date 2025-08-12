import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/Add_Item.dart';
import 'package:mobile_miniproject_app/pages/customer/Cart.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/restaurant/Option.dart';
import 'package:mobile_miniproject_app/pages/restaurant/RestaurantInfo.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class EditMenuPage extends StatefulWidget {
  final List<ResCatGetResponse> restaurantCategories;
  final int menu_id;
  const EditMenuPage({
    super.key,
    required this.restaurantCategories,
    required this.menu_id,
  });

  @override
  State<EditMenuPage> createState() => _HomePageState();
}

class _HomePageState extends State<EditMenuPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';

  List<ResCatGetResponse> _restaurantCategories = [];
  MenuInfoGetResponse? _MenuInfo;

  int? _selectedCatId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _restaurantCategories = widget.restaurantCategories;

    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadMenuInfo();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // แสดง loading ถ้ายังไม่มีข้อมูล
    if (_MenuInfo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('แก้ไขเมนู')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขเมนูอาหาร"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // รูปเมนูพร้อมปุ่มแก้ไข
            Stack(
              children: [
                // รูปเมนู (กดได้)
                GestureDetector(
                  onTap: () {
                    uploadMenuImage();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isLoading
                        ? Container(
                            width: double.infinity,
                            height: 200,
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Image.network(
                            _MenuInfo!.menu_image ?? '',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[300],
                              child: const Icon(Icons.fastfood, size: 60),
                            ),
                            loadingBuilder: (_, child, loading) {
                              if (loading == null) return child;
                              return Container(
                                width: double.infinity,
                                height: 200,
                                color: Colors.grey[300],
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              );
                            },
                          ),
                  ),
                ),

                // ไอคอนแก้ไขที่มุมขวาบน (กดได้)
                Positioned(
                  top: 8,
                  right: 8,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      uploadMenuImage();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Dropdown หมวดหมู่
            TextField(
              controller: _categoryController,
              readOnly: true, // กดพิมพ์ไม่ได้
              decoration: InputDecoration(
                labelText: 'หมวดหมู่เมนู',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    // เปิด popup ให้เลือกหมวดหมู่
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return ListView(
                            shrinkWrap: true,
                            children: _restaurantCategories.map((cat) {
                              return ListTile(
                                title: Text(cat.cat_name ?? 'ไม่ระบุ'),
                                selected: _selectedCatId == cat.cat_id,
                                onTap: () {
                                  setState(() {
                                    _selectedCatId = cat.cat_id;
                                    _categoryController.text =
                                        cat.cat_name ?? 'ไม่ระบุ';
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            }).toList(),
                          );
                        });
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ชื่อเมนู
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อเมนู',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // รายละเอียดเมนู
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'รายละเอียด',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // ราคา
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'ราคา (บาท)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // ปุ่มตัวเลือกเพิ่มเติม
            TextButton(
              onPressed: () {
                // TODO: ทำ logic เปิดหน้า/popup ตัวเลือกเพิ่มเติม
                Fluttertoast.showToast(msg: "ตัวเลือกเพิ่มเติม กดแล้ว");
              },
              child: const Text(
                "ตัวเลือกเพิ่มเติม",
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
            const SizedBox(height: 24),

            // ปุ่มบันทึกและยกเลิก
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _saveMenuChanges();
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "บันทึก",
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // ยกเลิกปิดหน้า
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      "ยกเลิก",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveMenuChanges() {
    // Validate ข้อมูล
    if (_selectedCatId == null ||
        _nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      Fluttertoast.showToast(
          msg: "กรุณากรอกข้อมูลให้ครบถ้วน",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    final updatedName = _nameController.text.trim();
    final updatedDesc = _descController.text.trim();
    final updatedPrice = double.tryParse(_priceController.text.trim());

    if (updatedPrice == null || updatedPrice <= 0) {
      Fluttertoast.showToast(
          msg: "กรุณากรอกราคาที่ถูกต้อง",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    // TODO: เรียก API อัพเดตเมนูที่นี่
    UpdateMenu(widget.menu_id, _selectedCatId!, updatedName, updatedDesc,
        updatedPrice, _MenuInfo!.menu_image);
  }

  void LoadMenuInfo() async {
    try {
      log("Loading menu info for ID: ${widget.menu_id}");
      var menu_id = widget.menu_id;

      final res = await http.get(Uri.parse("$url/db/loadMenuInfo/$menu_id"));
      if (res.statusCode == 200) {
        final MenuInfoGetResponse data =
            MenuInfoGetResponse.fromJson(json.decode(res.body));
        setState(() {
          _MenuInfo = data;

          // ตั้งค่าข้อมูลหลังจากโหลดเสร็จแล้ว
          _selectedCatId = _MenuInfo!.cat_id;
          _nameController.text = _MenuInfo!.menu_name ?? '';
          _descController.text = _MenuInfo!.menu_des ?? '';
          _priceController.text = _MenuInfo!.menu_price?.toString() ?? '0';

          // อัพเดต dropdown หมวดหมู่
          final selectedCat = _restaurantCategories.firstWhere(
              (cat) => cat.cat_id == _selectedCatId,
              orElse: () =>
                  ResCatGetResponse(cat_id: 0, cat_name: 'ไม่ระบุ', res_id: 0));
          _categoryController.text = selectedCat.cat_name ?? 'ไม่ระบุ';
        });
        log("Menu info loaded successfully: ${_MenuInfo!.menu_name}");
      } else {
        log("Failed to load menu info: ${res.statusCode}");
        Fluttertoast.showToast(
          msg: "ไม่สามารถโหลดข้อมูลเมนูได้",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      log("LoadMenuInfo Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> UpdateMenu(int menuId, int catId, String name, String desc,
      double price, String imageUrl) async {
    try {
      final res = await http.put(
        Uri.parse("$url/db/edit_Menu/${menuId}"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cat_id": catId,
          "menu_name": name,
          "menu_des": desc,
          "menu_price": price,
          "menu_image": imageUrl,
        }),
      );

      if (res.statusCode == 200) {
        log("Menu updated successfully");
        Fluttertoast.showToast(
            msg: "บันทึกข้อมูลเรียบร้อย",
            backgroundColor: Colors.green,
            textColor: Colors.white);

        Navigator.of(context).pop(true);
      } else {
        log("Failed to update menu: ${res.statusCode}");
        throw Exception("Failed to update menu");
      }
    } catch (e) {
      log("UpdateMenuAPI Error: $e");
      throw e;
    }
  }

  Future<void> uploadMenuImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      try {
        setState(() {
          isLoading = true; // เริ่มโหลด
        });

        String fileName =
            'menu_${widget.menu_id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = FirebaseStorage.instance
            .ref()
            .child('BP_food_image')
            .child(fileName);

        await ref.putFile(file);
        String downloadURL = await ref.getDownloadURL();

        log('✅ อัปโหลดสำเร็จ: $downloadURL');
        setState(() {
          _MenuInfo!.menu_image = downloadURL;
          isLoading = false; // โหลดเสร็จ
        });

        Fluttertoast.showToast(
          msg: "อัปโหลดรูปภาพสำเร็จ",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        log('❌ เกิดข้อผิดพลาดในการอัปโหลด: $e');
        setState(() {
          isLoading = false; // โหลดเสร็จแม้ error
        });
        Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดในการอัปโหลดรูปภาพ",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}
