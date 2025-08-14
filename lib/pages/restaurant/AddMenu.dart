import 'dart:convert';
import 'dart:io';
import 'dart:developer';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';

class AddMenuPage extends StatefulWidget {
  final List<ResCatGetResponse> restaurantCategories;
  const AddMenuPage({super.key, required this.restaurantCategories});

  @override
  State<AddMenuPage> createState() => _HomePageState();
}

class _HomePageState extends State<AddMenuPage> {
  String url = '';

  List<ResCatGetResponse> _restaurantCategories = [];

  int? _selectedCatId;
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _menuImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _restaurantCategories = widget.restaurantCategories;
    Configuration.getConfig().then((value) async {
      url = value['apiEndpoint'];

      // โหลดหมวดหมู่ร้านอาหาร (ปรับตาม API จริงของคุณ)
    });
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มเมนูอาหาร"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // รูปเมนู (ปุ่ม +)
          GestureDetector(
            onTap: () => uploadMenuImage(),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey),
              ),
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _menuImageUrl == null
                      ? const Center(
                          child: Icon(
                          Icons.add,
                          size: 60,
                          color: Colors.black45,
                        ))
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _menuImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 200,
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 16),

          // Dropdown หมวดหมู่
          TextField(
            controller: _categoryController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'หมวดหมู่เมนู',
              hintText: 'เลือกหมวดหมู่เมนู',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.arrow_drop_down),
                onPressed: () {
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
              hintText: 'กรอกชื่อเมนู',
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
              hintText: 'กรอกรายละเอียดเมนู (ถ้ามี)',
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
              hintText: 'กรอกราคาเมนู',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 16),
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
                  onPressed: InsertMenu,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    "เพิ่มเมนู",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
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
          )
        ]),
      ),
    );
  }

  void InsertMenu() async {
    if (_selectedCatId == null ||
        _nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty) {
      Fluttertoast.showToast(
          msg: "กรุณากรอกข้อมูลให้ครบถ้วน",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    final price = double.tryParse(_priceController.text.trim());

    if (price == null || price <= 0) {
      Fluttertoast.showToast(
          msg: "กรุณากรอกราคาที่ถูกต้อง",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    if (_menuImageUrl == null) {
      Fluttertoast.showToast(
          msg: "กรุณาอัปโหลดรูปภาพเมนู",
          backgroundColor: Colors.red,
          textColor: Colors.white);
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final res = await http.post(
        Uri.parse("$url/db/add_menu"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "cat_id": _selectedCatId,
          "menu_name": name,
          "menu_des": desc,
          "menu_price": price,
          "menu_image": _menuImageUrl,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (res.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "เพิ่มเมนูเรียบร้อย",
            backgroundColor: Colors.green,
            textColor: Colors.white);
        Navigator.of(context).pop(true);
      } else {
        Fluttertoast.showToast(
            msg: "เพิ่มเมนูล้มเหลว รหัส ${res.statusCode}",
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาดในการเพิ่มเมนู",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> uploadMenuImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        isLoading = true;
      });
      File file = File(pickedFile.path);

      try {
        String fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = FirebaseStorage.instance
            .ref()
            .child('BP_food_image')
            .child(fileName);

        await ref.putFile(file);
        String downloadURL = await ref.getDownloadURL();

        setState(() {
          _menuImageUrl = downloadURL;
          isLoading = false;
        });

        Fluttertoast.showToast(
          msg: "อัปโหลดรูปภาพสำเร็จ",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } catch (e) {
        setState(() {
          isLoading = false;
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
