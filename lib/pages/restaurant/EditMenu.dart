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
import 'package:mobile_miniproject_app/models/response/OpCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OpCatLinkGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/pages/restaurant/EditOption.dart';
import 'package:mobile_miniproject_app/pages/restaurant/Option.dart';
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
  OptionGetResponse? _Menu_Option;
  MenuInfoGetResponse? _MenuInfo;
  List<OpCatGetResponse> _AllopCat_res = [];

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
              onPressed: () async {
                // แสดง loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) =>
                      const Center(child: CircularProgressIndicator()),
                );

                await LoadMenuInfo();

                // ปิด loading
                Navigator.of(context).pop();

                if (_Menu_Option == null || _Menu_Option!.categories == null) {
                  POP_UPOptionCat();
                  return;
                }

                POP_UPOptionCat();
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

  void POP_UPOptionCat() {
    showDialog(
      context: context,
      builder: (context) {
        final hasCategories = _Menu_Option != null &&
            _Menu_Option!.categories != null &&
            _Menu_Option!.categories!.isNotEmpty;

        return AlertDialog(
          title: const Text("รายการหมวดหมู่ตัวเลือกเพิ่มเติมของเมนูนี้"),
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
                    if (!hasCategories)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "เมนูนี้ยังไม่ได้เลือกหมวดหมู่เพิ่มเติม",
                          style: TextStyle(color: Colors.orange),
                        ),
                      ),
                    if (hasCategories)
                      ..._Menu_Option!.categories!.map((opt) {
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
                                        await LoadMenuInfo();
                                        Navigator.of(context).pop();
                                        POP_UPOptionCat();
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
                                                await DeleteOptionCat(
                                                    opt.opCatId);
                                                await LoadMenuInfo();

                                                Navigator.of(context)
                                                    .pop(); // ปิด confirm
                                                Navigator.of(context)
                                                    .pop(); // ปิด popup list
                                                POP_UPOptionCat(); // refresh

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
                        await loadAllCat();
                        POP_UPallOpcat();
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

  void POP_UPallOpcat() {
    final availableCategories = (_AllopCat_res ?? [])
        .where((allCat) =>
            _Menu_Option?.categories == null ||
            !_Menu_Option!.categories
                .any((menuCat) => menuCat.opCatId == allCat.opCatId))
        .toList();

    if (availableCategories.isEmpty) {
      Fluttertoast.showToast(
        msg: "ไม่มีหมวดหมู่เพิ่มเติมให้เลือก",
        backgroundColor: Colors.orange,
        textColor: Colors.white,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("รายการหมวดหมู่ตัวเลือกเพิ่มเติมของร้าน"),
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
                    ...availableCategories.map((opt) {
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          title: Text(opt.opCatName ?? ''),
                          onTap: () async {
                            await Add_op_cat(opt.opCatId);
                            await LoadMenuInfo();

                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            POP_UPOptionCat();

                            Fluttertoast.showToast(
                              msg: 'เพิ่มหมวดหมู่ในเมนูแล้ว',
                              backgroundColor: Colors.green,
                              textColor: Colors.white,
                            );
                          },
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    // ปุ่มเพิ่มเมนู
                    ElevatedButton.icon(
                      onPressed: () {
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

  Future<void> Add_op_cat(int op_cat_id) async {
    final menu_id = widget.menu_id;
    try {
      final opcat_add_to_menu = await http.post(
        Uri.parse("$url/db/add_op_cat_to_menu"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"opCat_id": op_cat_id, "menu_id": menu_id}),
      );

      if (opcat_add_to_menu.statusCode == 200) {
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

  Future<void> DeleteOptionCat(int opCat_id) async {
    final menu_id = widget.menu_id;
    try {
      final opcat_del_from_menu = await http.delete(
        Uri.parse("$url/db/delete_opcat_from_menu"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"opCat_id": opCat_id, "menu_id": menu_id}),
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

  Future<void> LoadMenuInfo() async {
    try {
      log("Loading menu info for ID: ${widget.menu_id}");
      final res_id = context.read<ShareData>().user_info_send.uid;
      final menu_id = widget.menu_id;

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
      final men_option =
          await http.get(Uri.parse("$url/db/loadOption/$menu_id"));

      if (res.statusCode == 200) {
        log(men_option.body + "XDSADSADASDADS");
        final OptionGetResponse data =
            OptionGetResponse.fromJson(json.decode(men_option.body));
        setState(() {
          _Menu_Option = data;
        });
      }
    } catch (e) {
      log("LoadMenuInfo Error: $e");
      Fluttertoast.showToast(
          msg: "เมนูนี้ยังไม่ได้เพิ่มตัวเลือกเพิ่มเติม",
          backgroundColor: Colors.amber,
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

  Future<void> loadAllCat() async {
    final res_id = context.read<ShareData>().user_info_send.uid;
    final all_opcat = await http.get(Uri.parse("$url/db/loadAllOpCat/$res_id"));

    if (all_opcat.statusCode == 200) {
      log(all_opcat.body + "XDSADSADASDADS");

      final List<OpCatGetResponse> data = (json.decode(all_opcat.body) as List)
          .map((x) => OpCatGetResponse.fromJson(x))
          .toList();

      setState(() {
        _AllopCat_res = data;
      });
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
