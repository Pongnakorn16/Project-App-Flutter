import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/pages/login/login.dart';

class RiderVerificationPage extends StatefulWidget {
  const RiderVerificationPage({super.key});

  @override
  State<RiderVerificationPage> createState() => _RiderVerificationPageState();
}

class _RiderVerificationPageState extends State<RiderVerificationPage> {
  File? vehicleImg;
  File? drivLicenseImg;
  bool uploading = false;

  final picker = ImagePicker();
  String url = '';

  // เลือกรูปจาก Camera หรือ Gallery
  Future<void> pickImage(bool isVehicle) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('ถ่ายรูป'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('เลือกจาก Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final pickedFile =
          await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800);

      if (pickedFile != null) {
        setState(() {
          if (isVehicle) {
            vehicleImg = File(pickedFile.path);
          } else {
            drivLicenseImg = File(pickedFile.path);
          }
        });
      }
    }
  }

  // อัปโหลดไป Firebase Storage
  Future<String?> uploadImage(File file, String filename) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('BP_Rider_Vertification_image/$filename');
      await ref.putFile(file);
      final downloadURL = await ref.getDownloadURL();
      return downloadURL;
    } catch (e) {
      print("Upload error: $e");
      return null;
    }
  }

  // อัปโหลดรูปทั้งสองและส่งไป backend
  Future<void> submitImages(int rid) async {
    if (vehicleImg == null || drivLicenseImg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("กรุณาเลือกรูปให้ครบทั้งสองช่อง")));
      return;
    }

    setState(() {
      uploading = true;
    });

    try {
      final vehicleUrl = await uploadImage(vehicleImg!,
          "vehicle_${rid}_${DateTime.now().millisecondsSinceEpoch}");
      final licenseUrl = await uploadImage(drivLicenseImg!,
          "license_${rid}_${DateTime.now().millisecondsSinceEpoch}");

      if (vehicleUrl != null && licenseUrl != null) {
        final body = jsonEncode({
          "rid": rid,
          "rid_vehicle_image": vehicleUrl,
          "rid_driv_license_image": licenseUrl,
        });

        Configuration.getConfig().then((value) async {
          url = value['apiEndpoint'];
        });

        final response = await http.post(
          Uri.parse("$url/db/updateRiderImg"),
          headers: {"Content-Type": "application/json"},
          body: body,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text("อัปโหลดสำเร็จ")));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("อัปโหลดไป backend ไม่สำเร็จ: ${response.body}")));
        }
      }
    } catch (e) {
      print("Error: $e");
    }

    setState(() {
      uploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final int rid = 1; // ตัวอย่าง ใช้ uid จาก ShareData ของคุณจริงๆ

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันตัวตนไรเดอร์'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Vehicle image
            GestureDetector(
              onTap: () => pickImage(true),
              child: Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[300],
                child: vehicleImg != null
                    ? Image.file(vehicleImg!, fit: BoxFit.cover)
                    : const Center(child: Text("เลือกรูป Vehicle")),
              ),
            ),

            const SizedBox(height: 20),
            // Driver license image
            GestureDetector(
              onTap: () => pickImage(false),
              child: Container(
                width: double.infinity,
                height: 150,
                color: Colors.grey[300],
                child: drivLicenseImg != null
                    ? Image.file(drivLicenseImg!, fit: BoxFit.cover)
                    : const Center(child: Text("เลือกรูป Driver License")),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: uploading ? null : () => submitImages(rid),
              child: uploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("ยืนยันและอัปโหลด"),
            ),
          ],
        ),
      ),
    );
  }
}
