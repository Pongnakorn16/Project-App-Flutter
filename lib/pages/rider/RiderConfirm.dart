import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_miniproject_app/config/config.dart';
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

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
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

  Future<void> _confirmDelivery() async {
    // if (_uploadedImageUrl == null) {
    //   Fluttertoast.showToast(msg: "กรุณาถ่ายรูปก่อนยืนยันจัดส่ง");
    //   return;
    // }

    try {
      await FirebaseFirestore.instance
          .collection('BP_Order_detail')
          .doc('order${widget.ord_id}')
          .update({
        'Confirm_Order_image': _uploadedImageUrl,
        'order_status': '3',
      });

      final newStatus = 3;
      final changeStatus = await http.put(
        Uri.parse("$url/db/ChangeOrderStatus/${widget.ord_id}/$newStatus"),
      );

      if (changeStatus.statusCode == 200) {
        Fluttertoast.showToast(msg: "อัปเดตสถานะจัดส่งสำเร็จ!");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RiderHomePage(),
          ),
        );
      } else {
        print('MySQL update failed: ${changeStatus.body}');
        Fluttertoast.showToast(msg: 'อัปเดตสถานะใน MySQL ล้มเหลว');
      }
    } catch (e) {
      print('อัปเดตสถานะล้มเหลว: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถอัปเดตสถานะได้: $e');
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
                onPressed: _confirmDelivery,
                icon: const Icon(Icons.check_circle),
                label: const Text("จัดส่งสำเร็จ"),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
