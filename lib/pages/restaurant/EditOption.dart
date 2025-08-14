import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';

class EditOptionPage extends StatefulWidget {
  final int op_cat_id;
  const EditOptionPage({super.key, required this.op_cat_id});

  @override
  State<EditOptionPage> createState() => _HomePageState();
}

class _HomePageState extends State<EditOptionPage> {
  String url = '';
  OptionGetResponse? _menuOption;

  List<Map<String, dynamic>> _optionCategories = [];
  Map<int, TextEditingController> _catControllers = {};
  List<Map<String, dynamic>> _options = [];
  Map<int, List<Map<String, dynamic>>> groupedOptions = {};
  int _originalOptionsLength = 0;
  bool _hasAddedOption = false;

  // เก็บค่าเดิมไว้แยก
  Map<int, String> _originalCategoryNames = {};
  Map<int, String> _originalOptionNames = {};
  Map<int, int> _originalOptionPrices = {};

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      loadOption(); // เรียกฟังก์ชัน async หลังได้ url
    });
  }

  void _groupOptionsByCategory() {
    groupedOptions.clear();
    for (var opt in _options) {
      final catId = opt["op_cat_id"];
      // กรองเฉพาะ op_cat_id ที่ตรงกับ widget.op_cat_id
      if (catId == widget.op_cat_id) {
        if (!groupedOptions.containsKey(catId)) {
          groupedOptions[catId] = [];
        }
        groupedOptions[catId]!.add(opt);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("แก้ไขตัวเลือกเพิ่มเติม")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ไม่มีหมวดหมู่เลย
    if (_optionCategories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("แก้ไขตัวเลือกเพิ่มเติม")),
        body: const Center(child: Text("ไม่มีหมวดหมู่ตัวเลือกเพิ่มเติม")),
      );
    }

    final cat = _optionCategories.first;
    final catId = cat["op_cat_id"];
    final catController = _catControllers[catId]!;
    final optionsList = groupedOptions[catId] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text("แก้ไขตัวเลือกเพิ่มเติม"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ชื่อหมวดหมู่
            TextFormField(
              controller: catController,
              decoration: const InputDecoration(
                labelText: 'ชื่อหมวดหมู่',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ถ้ามี option ให้แสดง list, ถ้าไม่มีให้ขึ้นข้อความ
            if (optionsList.isEmpty)
              const Text(
                "ยังไม่มีตัวเลือกในหมวดหมู่นี้",
                style: TextStyle(color: Colors.grey),
              )
            else
              ...optionsList.map((opt) {
                final nameController =
                    opt["controller_name"] as TextEditingController;
                final priceController =
                    opt["controller_price"] as TextEditingController;
                return Dismissible(
                  key: Key("option_${opt["op_id"]}"),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await _showDeleteConfirmDialog(opt);
                  },
                  onDismissed: (direction) {
                    _deleteOption(opt);
                  },
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.delete, color: Colors.white, size: 28),
                        SizedBox(width: 8),
                        Text('ลบ',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  child: Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'ชื่อตัวเลือก',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ราคา',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text("เพิ่มตัวเลือก"),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveOptions,
                    child: const Text("บันทึก"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
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

  Future<bool?> _showDeleteConfirmDialog(Map<String, dynamic> option) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณต้องการลบตัวเลือก "${option["op_name"]}" หรือไม่?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('ลบ'),
            ),
          ],
        );
      },
    );
  }

  void _deleteOption(Map<String, dynamic> option) async {
    try {
      final res = await http.delete(
        Uri.parse("$url/db/delete_option/${option["op_id"]}"),
        headers: {"Content-Type": "application/json"},
      );

      if (res.statusCode == 200) {
        setState(() {
          _options.removeWhere((opt) => opt["op_id"] == option["op_id"]);
          _groupOptionsByCategory();
        });

        Fluttertoast.showToast(
          msg: "ลบตัวเลือกเรียบร้อย",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: "ไม่สามารถลบตัวเลือกได้",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        // รีโหลดข้อมูลใหม่หากลบไม่สำเร็จ
        loadOption();
      }
    } catch (e) {
      log("Error deleting option: $e");
      Fluttertoast.showToast(
        msg: "เกิดข้อผิดพลาด",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      // รีโหลดข้อมูลใหม่หากเกิดข้อผิดพลาด
      loadOption();
    }
  }

  void _addOption() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("เพิ่มตัวเลือก"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "ชื่อตัวเลือก",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "ราคา",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("ยกเลิก"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final price = int.tryParse(priceController.text.trim()) ?? 0;

              if (name.isEmpty) {
                Fluttertoast.showToast(
                    msg: "กรุณากรอกชื่อ",
                    backgroundColor: Colors.orange,
                    textColor: Colors.white);
                return;
              }

              // เช็คชื่อซ้ำกับตัวเลือกที่มีอยู่
              bool isDuplicate = _options.any((opt) =>
                  opt["op_name"].toString().trim().toLowerCase() ==
                  name.toLowerCase());

              if (isDuplicate) {
                Fluttertoast.showToast(
                    msg: "ชื่อตัวเลือกซ้ำ กรุณาใช้ชื่ออื่น",
                    backgroundColor: Colors.red,
                    textColor: Colors.white);
                return;
              }

              // สร้าง Option ใหม่
              final newOption = {
                "op_name": name,
                "op_price": price,
                "op_cat_id": widget.op_cat_id,
              };

              // ส่งไป server ก่อน
              await _Add_more_option(newOption);
              _hasAddedOption = true; // ✅ บอกว่ามีการเพิ่ม option ใหม่แล้ว
              loadOption();
              Navigator.of(context).pop();

              // จากนั้นอัปเดต UI
              setState(() {});
            },
            child: const Text("บันทึก"),
          ),
        ],
      ),
    );
  }

  Future<void> _Add_more_option(Map newOption) async {
    final res = await http.post(
      Uri.parse("$url/db/add_more_option"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(newOption), // ✅ แปลงเป็น JSON
    );

    if (res.statusCode == 200) {
      Fluttertoast.showToast(
        msg: "เพิ่มตัวเลือกเรียบร้อย",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
    } else {
      Fluttertoast.showToast(
        msg: "ไม่สามารถเพิ่มตัวเลือกได้",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _saveOptions() async {
    bool hasChanged = false;

    // เช็คการเปลี่ยนแปลงของหมวดหมู่
    for (final cat in _optionCategories) {
      final controller = _catControllers[cat["op_cat_id"]];
      if (controller != null) {
        final currentText = controller.text.trim();
        final originalText = _originalCategoryNames[cat["op_cat_id"]] ?? "";
        if (currentText != originalText) {
          hasChanged = true;
          cat["op_cat_name"] = currentText;
          // ไม่ต้อง break
        }
      }
    }

// เช็คการเปลี่ยนแปลงของตัวเลือก
    for (final opt in _options) {
      final nameController = opt["controller_name"] as TextEditingController;
      final priceController = opt["controller_price"] as TextEditingController;
      final currentName = nameController.text.trim();
      final currentPrice = int.tryParse(priceController.text.trim()) ?? 0;
      final originalName = _originalOptionNames[opt["op_id"]] ?? "";
      final originalPrice = _originalOptionPrices[opt["op_id"]] ?? 0;

      if (currentName != originalName || currentPrice != originalPrice) {
        hasChanged = true;
        opt["op_name"] = currentName;
        opt["op_price"] = currentPrice;
        // ไม่ต้อง break
      }
    }

    // เช็คว่ามีการเพิ่ม option ใหม่หรือไม่
    if (!hasChanged &&
        (_options.length > _originalOptionsLength || _hasAddedOption)) {
      hasChanged = true;
    }

    // ถ้าไม่มีการเปลี่ยนแปลงใดๆ
    if (!hasChanged) {
      Fluttertoast.showToast(
          msg: "คุณยังไม่ได้แก้ไขค่าใด",
          backgroundColor: Colors.orange,
          textColor: Colors.white);
      return;
    }

    // เช็คชื่อซ้ำในตัวเลือกที่แก้ไข (เฉพาะตัวที่เปลี่ยนแปลง)
    List<String> optionNames = [];
    for (final opt in _options) {
      final nameController = opt["controller_name"] as TextEditingController;
      final currentName = nameController.text.trim().toLowerCase();

      if (optionNames.contains(currentName)) {
        Fluttertoast.showToast(
            msg: "พบชื่อตัวเลือกซ้ำ กรุณาแก้ไขให้ไม่ซ้ำกัน",
            backgroundColor: Colors.red,
            textColor: Colors.white);
        return;
      }
      optionNames.add(currentName);
    }

    try {
      final res = await http.put(
        Uri.parse("$url/db/edit_Option"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "categories": _optionCategories
              .map((cat) => {
                    "op_cat_id": cat["op_cat_id"],
                    "op_cat_name": cat["op_cat_name"],
                  })
              .toList(),
          "options": _options
              .map((opt) => {
                    "option_id": opt["op_id"],
                    "option_name": opt["op_name"],
                    "option_price": opt["op_price"],
                    "op_cat_id": opt["op_cat_id"]
                  })
              .toList()
        }),
      );

      if (res.statusCode == 200) {
        Fluttertoast.showToast(
            msg: "บันทึกเรียบร้อย",
            backgroundColor: Colors.green,
            textColor: Colors.white);
        Navigator.of(context).pop(true);
      } else {
        Fluttertoast.showToast(
            msg: "ไม่สามารถบันทึกข้อมูลได้",
            backgroundColor: Colors.red,
            textColor: Colors.white);
      }
    } catch (e) {
      log("Error saving options: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  Future<void> loadOption() async {
    setState(() => _isLoading = true);
    final op_cat_id = widget.op_cat_id;
    final option =
        await http.get(Uri.parse("$url/db/loadOptionInfo/$op_cat_id"));

    if (option.statusCode == 200) {
      final OptionGetResponse data =
          OptionGetResponse.fromJson(json.decode(option.body));
      setState(() {
        _menuOption = data;

        // แปลง categories และ options หลังโหลด
        _optionCategories = _menuOption!.categories
                ?.where((cat) => cat.opCatId == widget.op_cat_id)
                .map((cat) => {
                      "op_cat_id": cat.opCatId,
                      "op_cat_name": cat.opCatName,
                      "res_id": cat.resId
                    })
                .toList() ??
            [];

        _catControllers.clear();
        _originalCategoryNames.clear(); // ✅ เคลียร์ก่อน

        for (var cat in _optionCategories) {
          _catControllers[cat["op_cat_id"]] =
              TextEditingController(text: cat["op_cat_name"]);

          // ✅ เก็บค่าเดิมไว้
          _originalCategoryNames[cat["op_cat_id"]] = cat["op_cat_name"];
        }

        _options = _menuOption!.options
                ?.where((opt) => opt.opCatId == widget.op_cat_id)
                .map((opt) {
              final nameController = TextEditingController(text: opt.opName);
              final priceController =
                  TextEditingController(text: opt.opPrice.toString());

              // ✅ เก็บค่าเดิมไว้
              _originalOptionNames[opt.opId!] = opt.opName ?? "";
              _originalOptionPrices[opt.opId!] = opt.opPrice ?? 0;

              return {
                "op_id": opt.opId,
                "op_name": opt.opName,
                "op_price": opt.opPrice,
                "op_cat_id": opt.opCatId,
                "controller_name": nameController,
                "controller_price": priceController,
              };
            }).toList() ??
            [];

        _groupOptionsByCategory();
        _originalOptionsLength = _options.length;

        _isLoading = false; // โหลดเสร็จ
      });
    } else {
      setState(() => _isLoading = false); // โหลดเสร็จแม้ error
      Fluttertoast.showToast(
        msg: "โหลดข้อมูลไม่สำเร็จ",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }
}
