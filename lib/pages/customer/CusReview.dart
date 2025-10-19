import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusReviewGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ReportTopicGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResTypeGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CusAllOrder.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CusReviewPage extends StatefulWidget {
  final int ord_id;

  const CusReviewPage({Key? key, required this.ord_id}) : super(key: key);
  @override
  State<CusReviewPage> createState() => _CusReviewPageState();
}

class _CusReviewPageState extends State<CusReviewPage> {
  int _selectedIndex = 1;
  late PageController _pageController;
  bool isLoading = false;
  String url = '';
  int _rating = 0;
  List<CusReviewGetRespone> CusReviewInfo = [];
  List<ReportTopicGetRespone> ReportTopic = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadConfigAndData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ เช็คก่อนว่ารีวิวครบหรือยัง
    if (CusReviewInfo.isNotEmpty &&
        CusReviewInfo.first.res_review_status == 1 &&
        CusReviewInfo.first.rid_review_status == 1) {
      // ✅ หน่วงเวลา 0.8 วิ แล้วกลับหน้าออเดอร์
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pop(context, true);
      });

      // ✅ แสดง Loading UI ชั่วคราวก่อนกลับ
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              Text(
                "คุณได้รีวิวครบถ้วนแล้ว",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green),
              ),
              const SizedBox(height: 10),
              Text("กำลังพากลับไปหน้าออเดอร์...",
                  style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    // ✅ ถ้ายังรีวิวไม่ครบ แสดงหน้าปกติ
    return Scaffold(
      appBar: AppBar(
        title: const Text("รีวิว"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ✅ รีวิวร้าน
                  if (CusReviewInfo.isNotEmpty &&
                      CusReviewInfo.first.res_review_status != 1) ...[
                    Text("รีวิวร้านอาหาร",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple)),
                    const SizedBox(height: 10),
                    buildReviewCard(
                      imageUrl: CusReviewInfo.first.resImage,
                      name: CusReviewInfo.first.resName,
                      title: "ร้านอาหาร",
                      resId: CusReviewInfo.first.resId,
                    ),
                    const SizedBox(height: 30),
                  ],

                  // ✅ รีวิวไรเดอร์
                  if (CusReviewInfo.isNotEmpty &&
                      CusReviewInfo.first.rid_review_status != 1) ...[
                    Text("รีวิวไรเดอร์",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple)),
                    const SizedBox(height: 10),
                    buildReviewCard(
                      imageUrl: CusReviewInfo.first.ridImage,
                      name: CusReviewInfo.first.ridName,
                      title: "ไรเดอร์",
                      ridId: CusReviewInfo.first.ridId,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  /// Widget Card ของแต่ละรีวิว
  Widget buildReviewCard({
    required String imageUrl,
    required String name,
    required String title,
    int? resId,
    int? ridId,
  }) {
    // ✅ เช็คสถานะการกด Report แล้วหรือยัง
    bool alreadyReported = false;
    if (title == "ร้านอาหาร") {
      alreadyReported = CusReviewInfo.first.res_report_status == 1;
    } else if (title == "ไรเดอร์") {
      alreadyReported = CusReviewInfo.first.rid_report_status == 1;
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // รูป
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),

            // ชื่อ
            Expanded(
              child: Text(
                name,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // ปุ่มรีวิว
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              onPressed: () => _showReviewDialog(title, resId, ridId),
            ),

            // ✅ ปุ่มรายงาน ซ่อนถ้าเคยรายงานแล้ว
            if (!alreadyReported)
              IconButton(
                icon: const Icon(Icons.report, color: Colors.redAccent),
                onPressed: () => _showReportDialog(title, resId, ridId),
              ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ProfilePage(onClose: () {}, selectedIndex: 1)),
      );
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // ✅ show dialog รีวิว (มีดาว + ข้อความ)
  void _showReviewDialog(String title, int? resId, int? ridId) {
    TextEditingController commentController = TextEditingController();
    int tempRating = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("รีวิว$title"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setDialogState(() => tempRating = index + 1);
                    },
                    child: Icon(
                      index < tempRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "พิมพ์ความคิดเห็นของคุณ...",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 115, 28, 168)),
              onPressed: () async {
                if (tempRating == 0) {
                  Fluttertoast.showToast(msg: "กรุณาให้คะแนนก่อน");
                  return;
                }

                // ✅ เรียก API ตามประเภท
                if (resId != null) {
                  print("กำลังรีวิวร้าน res_id = $resId");
                  await insertReview_res(
                    rating: tempRating,
                    review_des: commentController.text,
                    res_id: resId,
                    ord_id: widget.ord_id,
                  );
                  print("→ insertReview_res เสร็จ");
                  await update_res_rating(resId);
                  print("→ update_res_rating ทำงานแล้ว");
                } else if (ridId != null) {
                  print("กำลังรีวิวไรเดอร์ rid_id = $ridId");
                  await insertReview_rid(
                    rating: tempRating,
                    review_des: commentController.text,
                    rid_id: ridId,
                    ord_id: widget.ord_id,
                  );
                  print("→ insertReview_rid เสร็จ");
                  await update_rid_rating(ridId);
                  print("→ update_rid_rating ทำงานแล้ว");
                } else {
                  print("❌ resId และ ridId เป็น null ทั้งคู่");
                }

                Navigator.pop(context);

                // ✅ โหลดข้อมูลใหม่หลังรีวิวสำเร็จ
                await LoadCusReviewReport();
              },
              child: const Text(
                "ยืนยัน",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ show dialog รายงาน (มีแค่ข้อความ)
  void _showReportDialog(String title, int? resId, int? ridId) {
    TextEditingController reportController = TextEditingController();
    ReportTopicGetRespone? selectedTopic;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text("รายงาน$title"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<ReportTopicGetRespone>(
                    isExpanded: true,
                    value: selectedTopic,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: "เลือกหัวข้อรายงาน",
                    ),
                    items: ReportTopic.map((topic) {
                      return DropdownMenuItem<ReportTopicGetRespone>(
                        value: topic,
                        child: Text(
                          topic.reptTopic,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTopic = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reportController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "รายละเอียดเพิ่มเติม...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("ยกเลิก"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () async {
                if (selectedTopic == null) {
                  Fluttertoast.showToast(msg: "กรุณาเลือกหัวข้อรายงานก่อน");
                  return;
                }

                // ✅ เรียก API ตามประเภท
                if (resId != null) {
                  await insertReport_res(
                    rept_id: selectedTopic!.reptId,
                    report_des: reportController.text,
                    res_id: resId,
                    ord_id: widget.ord_id,
                  );
                  await LoadCusReviewReport();
                } else if (ridId != null) {
                  await insertReport_rid(
                    rept_id: selectedTopic!.reptId,
                    report_des: reportController.text,
                    rid_id: ridId,
                    ord_id: widget.ord_id,
                  );
                  await LoadCusReviewReport();
                }

                Navigator.pop(context);
              },
              child: const Text(
                "ยืนยัน",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadConfigAndData() async {
    setState(() {
      isLoading = true;
    });

    final config = await Configuration.getConfig();
    url = config['apiEndpoint'];

    await LoadCusReviewReport();
    await LoadReportTopic();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> LoadCusReviewReport() async {
    final response = await http
        .get(Uri.parse("$url/db/loadCusReviewReport/${widget.ord_id}"));
    log("Raw JSON from API: ${response.body}");

    if (response.statusCode == 200) {
      final List<CusReviewGetRespone> list =
          (json.decode(response.body) as List)
              .map((e) => CusReviewGetRespone.fromJson(e))
              .toList();

      if (!mounted) return;
      setState(() {
        CusReviewInfo = list;
      });
    } else {
      log("No Review INFO");
    }
  }

  Future<void> LoadReportTopic() async {
    final response = await http.get(Uri.parse("$url/db/loadReportTopic"));
    log("Raw JSON from API: ${response.body}");

    if (response.statusCode == 200) {
      final List<ReportTopicGetRespone> list =
          (json.decode(response.body) as List)
              .map((e) => ReportTopicGetRespone.fromJson(e))
              .toList();

      if (!mounted) return;
      setState(() {
        ReportTopic = list;
      });
    } else {
      log("No Report Topic INFO");
    }
  }

  // ✅ 1. ฟังก์ชัน insertReview_res (รีวิวร้านอาหาร)
  Future<void> insertReview_res({
    required int rating,
    required String review_des,
    required int res_id,
    required int ord_id,
  }) async {
    try {
      final cus_id = context.read<ShareData>().user_info_send.uid;

      final body = jsonEncode({
        "cus_id": cus_id,
        "rating": rating,
        "review_des": review_des,
        "res_id": res_id,
        "ord_id": ord_id,
      });

      final response = await http.post(
        Uri.parse("$url/db/insertReview_res"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      log("📤 ส่งรีวิวร้านอาหารไป: $body");
      log("📥 ตอบกลับจากเซิร์ฟเวอร์: ${response.body}");

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "ส่งรีวิวร้านอาหารสำเร็จ!");
      } else {
        Fluttertoast.showToast(
            msg: "ส่งรีวิวร้านอาหารไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      log("❌ เกิดข้อผิดพลาดขณะส่งรีวิวร้านอาหาร: $e");
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาดในการส่งข้อมูล");
    }
  }

  // ✅ 2. ฟังก์ชัน insertReview_rid (รีวิวไรเดอร์)
  Future<void> insertReview_rid({
    required int rating,
    required String review_des,
    required int rid_id,
    required int ord_id,
  }) async {
    try {
      final cus_id = context.read<ShareData>().user_info_send.uid;

      final body = jsonEncode({
        "cus_id": cus_id,
        "rating": rating,
        "review_des": review_des,
        "rid_id": rid_id,
        "ord_id": ord_id,
      });

      final response = await http.post(
        Uri.parse("$url/db/insertReview_rid"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      log("📤 ส่งรีวิวไรเดอร์ไป: $body");
      log("📥 ตอบกลับจากเซิร์ฟเวอร์: ${response.body}");

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "ส่งรีวิวไรเดอร์สำเร็จ!");
      } else {
        Fluttertoast.showToast(
            msg: "ส่งรีวิวไรเดอร์ไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      log("❌ เกิดข้อผิดพลาดขณะส่งรีวิวไรเดอร์: $e");
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาดในการส่งข้อมูล");
    }
  }

  // ✅ 3. ฟังก์ชัน insertReport_res (รายงานร้านอาหาร)
  Future<void> insertReport_res({
    required int rept_id,
    required String report_des,
    required int res_id,
    required int ord_id,
  }) async {
    try {
      final body = jsonEncode({
        "rept_id": rept_id,
        "report_des": report_des,
        "res_id": res_id,
        "ord_id": ord_id,
      });

      final response = await http.post(
        Uri.parse("$url/db/insertReport_res"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      log("📤 ส่งรายงานร้านอาหารไป: $body");
      log("📥 ตอบกลับจากเซิร์ฟเวอร์: ${response.body}");

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "ส่งรายงานร้านอาหารสำเร็จ");
      } else {
        String errorMsg =
            "ส่งรายงานร้านอาหารไม่สำเร็จ (${response.statusCode})";

        try {
          final data = jsonDecode(response.body);
          if (data["message"] != null) {
            errorMsg = "${data["message"]} (${response.statusCode})";
          }
        } catch (e) {
          // ถ้า body ไม่ใช่ JSON ก็ไม่ต้องทำอะไร
        }

        Fluttertoast.showToast(msg: errorMsg);
      }
    } catch (e) {
      log("❌ เกิดข้อผิดพลาดขณะส่งรายงานร้านอาหาร: $e");
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาดในการส่งข้อมูล");
    }
  }

  // ✅ 4. ฟังก์ชัน insertReport_rid (รายงานไรเดอร์)
  Future<void> insertReport_rid({
    required int rept_id,
    required String report_des,
    required int rid_id,
    required int ord_id,
  }) async {
    try {
      final cus_id = context.read<ShareData>().user_info_send.uid;

      final body = jsonEncode({
        "cus_id": cus_id,
        "rept_id": rept_id,
        "report_des": report_des,
        "rid_id": rid_id,
        "ord_id": ord_id,
      });

      final response = await http.post(
        Uri.parse("$url/db/insertReport_rid"),
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      log("📤 ส่งรายงานไรเดอร์ไป: $body");
      log("📥 ตอบกลับจากเซิร์ฟเวอร์: ${response.body}");

      if (response.statusCode == 200) {
        Fluttertoast.showToast(msg: "ส่งรายงานไรเดอร์สำเร็จ!");
      } else {
        Fluttertoast.showToast(
            msg: "ส่งรายงานไรเดอร์ไม่สำเร็จ (${response.statusCode})");
      }
    } catch (e) {
      log("❌ เกิดข้อผิดพลาดขณะส่งรายงานไรเดอร์: $e");
      Fluttertoast.showToast(msg: "เกิดข้อผิดพลาดในการส่งข้อมูล");
    }
  }

  Future<void> update_res_rating(int res_id) async {
    final res_rating =
        await http.get(Uri.parse("$url/db/updateResRating/$res_id"));
    print('Status code: ${res_rating.statusCode}');
    print('Response body: ${res_rating.body}');

    if (res_rating.statusCode == 200) {
      Fluttertoast.showToast(msg: "รีวิวร้านสำเร็จ");
    } else {
      Fluttertoast.showToast(msg: "รีวิวร้านไม่สำเร็จ");
    }
  }

  Future<void> update_rid_rating(int rid_id) async {
    final rid_rating =
        await http.get(Uri.parse("$url/db/updateRidRating/$rid_id"));
    print('Status code: ${rid_rating.statusCode}');
    print('Response body: ${rid_rating.body}');

    if (rid_rating.statusCode == 200) {
      Fluttertoast.showToast(msg: "รีวิวร้านสำเร็จ");
    } else {
      Fluttertoast.showToast(msg: "รีวิวร้านไม่สำเร็จ");
    }
  }
}
