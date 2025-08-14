import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';

class AddOptionPage extends StatefulWidget {
  const AddOptionPage({super.key});

  @override
  State<AddOptionPage> createState() => _AddOptionPageState();
}

class _AddOptionPageState extends State<AddOptionPage> {
  String url = '';
  final _catNameController = TextEditingController();
  final List<Map<String, dynamic>> _options = [];

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
    });
  }

  void _addOptionField() {
    _options.add({
      "nameController": TextEditingController(),
      "priceController": TextEditingController(),
    });
    setState(() {});
  }

  void _removeOptionField(int index) {
    _options.removeAt(index);
    setState(() {});
  }

  Future<void> _saveData() async {
    final categoryName = _catNameController.text.trim();

    if (categoryName.isEmpty) {
      Fluttertoast.showToast(
          msg: "กรุณากรอกชื่อหมวดหมู่",
          backgroundColor: Colors.orange,
          textColor: Colors.white);
      return;
    }

    if (_options.isEmpty) {
      Fluttertoast.showToast(
          msg: "กรุณาเพิ่มอย่างน้อย 1 ตัวเลือก",
          backgroundColor: Colors.orange,
          textColor: Colors.white);
      return;
    }

    // ตรวจสอบข้อมูลตัวเลือก
    List<Map<String, dynamic>> optionsData = [];
    for (var opt in _options) {
      final name = opt["nameController"].text.trim();
      final price = int.tryParse(opt["priceController"].text.trim()) ?? 0;

      if (name.isEmpty) {
        Fluttertoast.showToast(
            msg: "กรุณากรอกชื่อตัวเลือกให้ครบ",
            backgroundColor: Colors.orange,
            textColor: Colors.white);
        return;
      }

      optionsData.add({
        "op_name": name,
        "op_price": price,
      });
    }

    // ส่งข้อมูลไป API
    try {
      final res = await http.post(
        Uri.parse("$url/db/add_option_category"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"op_cat_name": categoryName, "options": optionsData}),
      );

      if (res.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "บันทึกเรียบร้อย",
            backgroundColor: Colors.green,
            textColor: Colors.white);
        Navigator.of(context).pop(true);
      } else {
        Fluttertoast.showToast(
            msg: "บันทึกไม่สำเร็จ",
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    } catch (e) {
      log("Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มตัวเลือกเพิ่มเติม"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ช่องกรอกชื่อหมวดหมู่
            TextFormField(
              controller: _catNameController,
              decoration: const InputDecoration(
                labelText: "ชื่อหมวดหมู่",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ตัวเลือก
            ..._options.asMap().entries.map((entry) {
              int index = entry.key;
              var opt = entry.value;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: opt["nameController"],
                        decoration: const InputDecoration(
                          labelText: "ชื่อตัวเลือก",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: opt["priceController"],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "ราคา",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeOptionField(index),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // ปุ่มเพิ่มตัวเลือก
            ElevatedButton.icon(
              onPressed: _addOptionField,
              icon: const Icon(Icons.add),
              label: const Text("เพิ่มตัวเลือก"),
            ),

            const SizedBox(height: 20),

            // ปุ่มบันทึก
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveData,
                child: const Text("บันทึก"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
