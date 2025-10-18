import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusAddressGetRes.dart';
import 'package:mobile_miniproject_app/models/response/MenuInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResCatGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/CustomerProfile.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TopupPage extends StatefulWidget {
  const TopupPage({
    super.key,
  });

  @override
  State<TopupPage> createState() => _HomePageState();
}

class _HomePageState extends State<TopupPage> {
  final TextEditingController _amountController = TextEditingController();
  String? _qrData;

  int _selectedIndex = 1;
  late PageController _pageController;
  String url = '';
  bool isFavorite = false;
  bool isLoading = true;
  String? _address; // เก็บที่อยู่ที่ได้
  List<ResCatGetResponse> _restaurantCategories = [];
  List<MenuInfoGetResponse> _restaurantMenu = [];
  Map<int, int> _selectedMenuCounts = {};
  String? _selectedCustomerAddress;
  List<MenuInfoGetResponse> get selectedMenus {
    return _restaurantMenu
        .where((menu) => _selectedMenuCounts.containsKey(menu.menu_id))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
      LoadCusAdd();
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final cus_id = context.read<ShareData>().user_info_send.uid;
        OrderNotificationService().listenOrderChanges(context, cus_id,
            (orderId, newStep) {
          if (!mounted) return;
        });
      });
    });
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เติมเงิน D-wallet"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildTopupForm(),
            ),
    );
  }

  Widget _buildTopupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "D-Wallet ปัจจุบันของคุณคือ : ${NumberFormat('#,###').format(context.read<ShareData>().user_info_send.balance)}",
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Text(
          "กรอกจำนวนเงินที่ต้องการเติม",
          style: TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _amountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: "จำนวนเงิน (บาท)",
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () {
            final phone = "0878012368"; // เบอร์พร้อมเพย์
            final input = _amountController.text;
            final amount = double.tryParse(input);

            if (amount == null || amount <= 0) {
              Fluttertoast.showToast(
                msg: "กรุณากรอกจำนวนเงินให้ถูกต้อง",
                backgroundColor: Colors.red,
                textColor: Colors.white,
              );
              return;
            }

            setState(() {
              _qrData = generatePromptPayQR(phone, amount);
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple, // สีพื้นหลัง
            foregroundColor: Colors.white, // สีตัวหนังสือ
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // มุมโค้ง
            ),
          ),
          child: const Text("สร้าง QR Code"),
        ),
        const SizedBox(height: 20),
        if (_qrData != null) ...[
          const Text(
            "สแกน QR เพื่อเติมเงิน",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          QrImageView(
            data: _qrData!,
            version: QrVersions.auto,
            size: 250.0,
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Fluttertoast.showToast(msg: "ทำการเติมเงินเรียบร้อยแล้ว");
              final InputValue = int.parse(_amountController.text);
              TopUp(InputValue);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green, // สีพื้นหลังปุ่ม
              foregroundColor: Colors.white, // สีตัวอักษร
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            child: const Text("ยืนยันการโอนเงิน"),
          )
        ],
      ],
    );
  }

// เพิ่ม
  String _selectedPayment = "COD";

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) return;
    setState(() => _selectedIndex = index);
    if (index == 4) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                ProfilePage(onClose: () {}, selectedIndex: 1)),
      );
    } else {
      _pageController.animateToPage(
        index > 2 ? index - 1 : index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String generatePromptPayQR(String phoneNumber, double? amount) {
    String formatPhoneNumber(String number) {
      if (number.startsWith("0")) {
        return "0066${number.substring(1)}";
      } else if (number.startsWith("+66")) {
        return "0066${number.substring(3)}";
      }
      return number;
    }

    final target = formatPhoneNumber(phoneNumber);

    final buffer = StringBuffer();
    buffer.write("000201"); // Payload Format Indicator
    buffer.write("010212"); // Point of Initiation Method (Dynamic QR)

    // Merchant Account Information (ID 29)
    final merchantInfo = StringBuffer();
    merchantInfo.write("0016A000000677010111"); // Application ID (PromptPay)
    merchantInfo.write("01${target.length.toString().padLeft(2, '0')}$target");

    buffer.write(
        "29${merchantInfo.length.toString().padLeft(2, '0')}${merchantInfo.toString()}");

    buffer.write("5802TH"); // Country Code
    buffer.write("5303764"); // Currency Code (THB)

    if (amount != null && amount > 0) {
      final amountStr = amount.toStringAsFixed(2);
      buffer
          .write("54${amountStr.length.toString().padLeft(2, '0')}$amountStr");
    }

    buffer.write("6304"); // CRC Placeholder

    final crc = _calculateCRC(buffer.toString());
    buffer.write(crc);

    return buffer.toString();
  }

  String _calculateCRC(String input) {
    int crc = 0xFFFF;
    for (int i = 0; i < input.length; i++) {
      crc ^= input.codeUnitAt(i) << 8;
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = ((crc << 1) ^ 0x1021) & 0xFFFF;
        } else {
          crc = (crc << 1) & 0xFFFF;
        }
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  void LoadCusAdd() async {
    int userId = context.read<ShareData>().user_info_send.uid;

    final cus_balance =
        await http.get(Uri.parse("$url/db/loadCusbalance/$userId"));
    print('Status code: ${cus_balance.statusCode}');
    print('Response body: ${cus_balance.body}');

    if (cus_balance.statusCode == 200) {
      final data = jsonDecode(cus_balance.body);
      final int balance = data['balance'] ?? 0;
      context.read<ShareData>().user_info_send.balance = balance;
    } else {
      Fluttertoast.showToast(msg: "โหลดยอดเงินไม่สำเร็จ");
    }
    try {
      context.read<ShareData>().customer_addresses = [];
      final res_Add = await http.get(Uri.parse("$url/db/loadCusAdd/$userId"));
      if (res_Add.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(res_Add.body);
        final List<CusAddressGetResponse> res_addList =
            jsonResponse.map((e) => CusAddressGetResponse.fromJson(e)).toList();
        if (res_addList.isNotEmpty) {
          context.read<ShareData>().customer_addresses = res_addList;
        }
      }
    } catch (e) {
      log("LoadCusHome Error: $e");
      Fluttertoast.showToast(
          msg: "เกิดข้อผิดพลาด โปรดลองใหม่",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    } finally {
      setState(() {
        isLoading = false; // ✅ หลังโหลดเสร็จ
      });
    }
  }

  TopUp(int InputValue) async {
    int cus_id = context.read<ShareData>().user_info_send.uid;

    setState(() {
      isLoading = true;
    });

    try {
      final res_Add = await http.put(
        Uri.parse("$url/db/TopUpCus_balance"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "InputValue": InputValue,
          "cus_id": cus_id,
        }),
      );

      if (res_Add.statusCode == 200) {
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
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
}
