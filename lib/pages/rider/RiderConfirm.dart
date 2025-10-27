import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';
import 'package:mobile_miniproject_app/pages/rider/RiderHome.dart';
import 'package:provider/provider.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:http/http.dart' as http;

class RiderConfirmPage extends StatefulWidget {
  final int ord_id;
  const RiderConfirmPage({super.key, required this.ord_id});

  @override
  State<RiderConfirmPage> createState() => _RiderConfirmPageState();
}

class _RiderConfirmPageState extends State<RiderConfirmPage> {
  File? _imageFile;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  String url = '';
  List<CusOrderGetResponse> orders_info = []; // เก็บ order

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) async {
      url = value['apiEndpoint'];
      await get_RidOrder();
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
      _showConfirmDialog();
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ยืนยันรูปภาพ'),
        content: Image.file(_imageFile!, fit: BoxFit.cover),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ถ่ายใหม่'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _uploadToFirebase();
            },
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadToFirebase() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      final fileName = 'confirm_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('BP_Confirm_order_image/$fileName');

      await ref.putFile(_imageFile!);
      final downloadUrl = await ref.getDownloadURL();

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isUploading = false;
      });

      Fluttertoast.showToast(msg: "อัปโหลดรูปสำเร็จ!");
    } catch (e) {
      setState(() => _isUploading = false);
      Fluttertoast.showToast(msg: "อัปโหลดไม่สำเร็จ: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ยืนยันการจัดส่ง")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isUploading)
                const CircularProgressIndicator()
              else if (_uploadedImageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_uploadedImageUrl!, height: 250),
                )
              else if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(_imageFile!, height: 250),
                )
              else
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          SizedBox(height: 10),
                          Text("+ เพิ่มรูปภาพ",
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _uploadedImageUrl == null
                    ? null // ถ้ายังไม่มีรูป ปุ่มจะกดไม่ได้
                    : () async {
                        try {
                          await _confirmDelivery();
                          await cal_RidShareRate(widget.ord_id,
                              orders_info.first.totalOrderPrice.toDouble());
                          await cal_AdminShareRate(widget.ord_id,
                              orders_info.first.totalOrderPrice.toDouble());

                          if (!mounted) return; // ป้องกัน widget ถูก unmounted

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RiderHomePage(),
                            ),
                          );
                        } catch (e) {
                          print("Error: $e");
                        }
                      },
                icon: const Icon(Icons.check_circle),
                label: const Text("จัดส่งสำเร็จ"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> get_RidOrder() async {
    double share_rate = 0;

    final order_info =
        await http.get(Uri.parse("$url/db/loadOrderById/${widget.ord_id}"));
    final List<CusOrderGetResponse> list =
        (json.decode(order_info.body) as List)
            .map((e) => CusOrderGetResponse.fromJson(e))
            .toList();

    if (order_info.statusCode == 200) {
      orders_info = list;
    }
  }

  Future<void> _confirmDelivery() async {
    try {
      await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .update({
        'Confirm_Order_image': _uploadedImageUrl,
        'Order_status': 3,
      });

      final newStatus = 3;
      final changeStatus = await http.put(
        Uri.parse("$url/db/ChangeOrderStatus/${widget.ord_id}/$newStatus"),
      );

      if (changeStatus.statusCode == 200) {
        Fluttertoast.showToast(msg: "อัปเดตสถานะจัดส่งสำเร็จ!");
      } else {
        print('MySQL update failed: ${changeStatus.body}');
        Fluttertoast.showToast(msg: 'อัปเดตสถานะใน MySQL ล้มเหลว');
      }
    } catch (e) {
      print('อัปเดตสถานะล้มเหลว: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถอัปเดตสถานะได้: $e');
    }
  }

  Future<void> cal_RidShareRate(int order_id, double totalPrice) async {
    double share_rate = 0;
    double rid_income = 0;
    int rid_id = context.read<ShareData>().user_info_send.uid;

    try {
      final rid_share = await http.get(Uri.parse("$url/db/loadRidShare"));
      print('Status code: ${rid_share.statusCode}');
      print('Response body: ${rid_share.body}');

      if (rid_share.statusCode == 200) {
        final data = jsonDecode(rid_share.body);
        share_rate = (data['share_rate'] ?? 0).toDouble();
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
      }

      rid_income = totalPrice * (share_rate / 100);

      final update_rid_income = await http.put(
        Uri.parse("$url/db/updateRidIncome"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ord_id": order_id,
          "rid_id": rid_id,
          "rid_income": rid_income,
        }),
      );

      if (update_rid_income.statusCode == 200) {
        log("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC");
      } else {
        throw Exception("Server error: ${update_rid_income.statusCode}");
      }
    } catch (e) {
      log("update_cus_balance Error: $e");
      throw e;
    }
  }

  Future<void> cal_AdminShareRate(int order_id, double totalPrice) async {
    double share_rate = 0;
    int admin_id = 0;
    double adm_income = 0;
    int rid_id = context.read<ShareData>().user_info_send.uid;

    try {
      if (url.isEmpty) {
        final config = await Configuration.getConfig();
        url = config['apiEndpoint'];
      }

      // โหลด share rate
      final adm_share = await http.get(Uri.parse("$url/db/loadAdmShare"));
      if (adm_share.statusCode == 200) {
        final data = jsonDecode(adm_share.body);
        share_rate = (data['share_rate'] ?? 0).toDouble();
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
        return;
      }

      // โหลด admin id
      final admID = await http.get(Uri.parse("$url/db/loadAdmId"));
      if (admID.statusCode == 200) {
        final data = jsonDecode(admID.body);
        admin_id = data['admin_id'] ?? 0;
      } else {
        Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
        return;
      }

      adm_income = totalPrice * (share_rate / 100);

      log(order_id.toString() + "ORDER_ID");
      log(admin_id.toString() + "ADMIN_ID");
      log(adm_income.toString() + "AD_INCOME");

      // อัปเดต server
      final updateResponse = await http.put(
        Uri.parse("$url/db/updateAdmIncome"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "ord_id": order_id,
          "ad_id": admin_id,
          "ad_income": adm_income.toDouble(),
        }),
      );

      print("PUT status: ${updateResponse.statusCode}");
      print("PUT body: ${updateResponse.body}");

      if (updateResponse.statusCode != 200) {
        throw Exception("Server error: ${updateResponse.statusCode}");
      }
    } catch (e) {
      log("cal_AdminShareRate Error: $e");
    }
  }
}
