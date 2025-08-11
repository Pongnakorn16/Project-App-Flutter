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
  final List<MenuInfoGetResponse> restaurantMenu;
  const EditMenuPage({
    super.key,
    required this.restaurantMenu,
  });

  @override
  State<EditMenuPage> createState() => _HomePageState();
}

class _HomePageState extends State<EditMenuPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  String url = '';

  List<ResCatGetResponse> _restaurantCategories =
      []; // โหลดหมวดหมู่ไว้แสดง dropdown
  MenuInfoGetResponse? _editingMenu;

  int? _selectedCatId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // หาเมนูที่จะแก้ไขจาก list
    if (widget.restaurantMenu.isNotEmpty) {
      _editingMenu = widget.restaurantMenu.firstWhere(
        (m) => m.menu_id == widget.restaurantMenu.first.menu_id,
        orElse: () => widget.restaurantMenu[0],
      );
    } else {
      _editingMenu = null; // nullable
    }

    if (_editingMenu != null) {
      _selectedCatId = _editingMenu!.cat_id;
      _nameController.text = _editingMenu!.menu_name;
      _descController.text = _editingMenu!.menu_des ?? '';
      _priceController.text = _editingMenu!.menu_price.toString();
    }

    // TODO: โหลดหมวดหมู่จาก API หรือที่เก็บข้อมูลจริงของคุณ
    // ตัวอย่างใส่ข้อมูล dummy
    _restaurantCategories = [
      // ResCatGetResponse(cat_id: 1, cat_name: 'อาหารจานเดียว'),
      // ResCatGetResponse(cat_id: 2, cat_name: 'เครื่องดื่ม'),
      // ResCatGetResponse(cat_id: 3, cat_name: 'ของหวาน'),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_editingMenu == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('แก้ไขเมนู')),
        body: const Center(child: Text('ไม่พบข้อมูลเมนูที่จะแก้ไข')),
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
            // รูปเมนู
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _editingMenu!.menu_image,
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
            const SizedBox(height: 16),

            // Dropdown หมวดหมู่
            DropdownButtonFormField<int>(
              value: _selectedCatId,
              decoration: InputDecoration(
                labelText: 'เลือกหมวดหมู่',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _restaurantCategories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat.cat_id,
                  child: Text(cat.cat_name ?? 'ไม่ระบุ'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCatId = val;
                });
              },
            ),
            const SizedBox(height: 16),

            // ชื่อเมนู
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'ชื่อเมนู',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),

            // รายละเอียดเมนู
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: 'รายละเอียด',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // ราคา
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'ราคา',
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
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Validate & บันทึกข้อมูล
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
                      final updatedPrice =
                          double.tryParse(_priceController.text.trim()) ?? 0;

                      // TODO: เรียก API อัพเดตเมนูที่นี่

                      Fluttertoast.showToast(
                          msg: "บันทึกข้อมูลเรียบร้อย",
                          backgroundColor: Colors.green,
                          textColor: Colors.white);

                      Navigator.of(context).pop();
                    },
                    child: const Text("บันทึก"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // ยกเลิกปิดหน้า
                    },
                    child: const Text("ยกเลิก"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
