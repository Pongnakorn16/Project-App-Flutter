import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/response/CusInfoGetRes.dart';
import 'package:mobile_miniproject_app/models/response/CusOrderGetRes.dart';
import 'package:mobile_miniproject_app/models/response/OptionGetRes.dart';
import 'package:mobile_miniproject_app/models/response/ResInfoGetRes.dart';
import 'package:mobile_miniproject_app/pages/customer/Order.dart';
import 'package:mobile_miniproject_app/pages/restaurant/ResOrder.dart';
import 'package:mobile_miniproject_app/shared/firebase_message_service.dart';
import 'package:mobile_miniproject_app/shared/share_data.dart';
import 'package:provider/provider.dart';

class ResIncomeSummaryPage extends StatefulWidget {
  const ResIncomeSummaryPage({super.key});

  @override
  State<ResIncomeSummaryPage> createState() => _ResIncomeSummaryPageState();
}

class _ResIncomeSummaryPageState extends State<ResIncomeSummaryPage> {
  // --- state data ---
  String url = '';
  bool isLoading = true;
  List<CusOrderGetResponse> ordersList = []; // ทั้งหมดที่โหลดมา
  List<CusOrderGetResponse> filteredOrders = []; // หลังกรองตามช่วงเวลา
  double totalIncome = 0.0;

  // filter: 0 = สัปดาห์, 1 = เดือน, 2 = ปี
  int selectedFilterIndex = 0;

  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy เวลา HH:mm น.');
  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  @override
  void initState() {
    super.initState();
    _pageInit();
  }

  Future<void> _pageInit() async {
    // โหลด config และข้อมูลคำสั่งซื้อ แล้วกรองเริ่มต้น
    try {
      final cfg = await Configuration.getConfig();
      url = cfg['apiEndpoint'] ?? '';
    } catch (e) {
      log('Cannot load config: $e');
    }

    await LoadAllOrder(context);
    _applyFilter(); // filter หลังโหลด
  }

  // --- ฟังก์ชัน: โหลดคำสั่งซื้อจาก backend (ใช้ของเดิมคุณ) ---
  Future<void> LoadAllOrder(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      int res_id = context.read<ShareData>().user_info_send.uid;
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/loadResOrder/$res_id"));

      if (res_ResInfo.statusCode == 200) {
        final List<CusOrderGetResponse> list =
            (json.decode(res_ResInfo.body) as List)
                .map((e) => CusOrderGetResponse.fromJson(e))
                .toList();

        ordersList.clear();
        ordersList = list;
      } else {
        log('LoadAllOrder: non-200 -> ${res_ResInfo.statusCode}');
      }
    } catch (e) {
      log('เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถโหลดคำสั่งซื้อได้');
    }

    setState(() {
      isLoading = false;
    });
  }

  // --- ฟังก์ชัน: กรองคำสั่งซื้อตามช่วงเวลา และคำนวณยอดรวม (ตามข้อ B) ---
  void _applyFilter() {
    DateTime now = DateTime.now();
    DateTime start;

    if (selectedFilterIndex == 0) {
      // รายสัปดาห์ -> ย้อนหลัง 7 วัน (รวมวันนี้)
      start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6)); // 7 วันรวมวันนี้
    } else if (selectedFilterIndex == 1) {
      // รายเดือน -> เริ่มต้นเดือนนี้
      start = DateTime(now.year, now.month, 1);
    } else {
      // รายปี -> เริ่มต้นปีนี้
      start = DateTime(now.year, 1, 1);
    }

    final List<CusOrderGetResponse> result = ordersList.where((o) {
      // ถ้า ordResIncome เป็น null ให้ถือว่าไม่มีค่า -> ไม่รวม
      if (o.ordResIncome == null) return false;
      // ตรวจสอบวันที่ (ใช้ local time)
      DateTime dt = o.ordDate.toLocal();
      return !dt.isBefore(start) && !dt.isAfter(now);
    }).toList();

    double sum = 0.0;
    for (var o in result) {
      sum += (o.ordResIncome ?? 0.0);
    }

    setState(() {
      filteredOrders = result;
      totalIncome = sum;
    });
  }

  // --- helper format ---
  String _fmtCurrency(double value) {
    try {
      return _currencyFmt.format(value);
    } catch (e) {
      return '฿ ${value.toStringAsFixed(2)}';
    }
  }

  String _fmtDate(DateTime dt) {
    try {
      return _dateFmt.format(dt.toLocal());
    } catch (e) {
      return dt.toString();
    }
  }

  // --- pull-to-refresh handler ---
  Future<void> _onRefresh() async {
    await LoadAllOrder(context);
    _applyFilter();
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final List<String> filterLabels = ['รายสัปดาห์', 'รายเดือน', 'รายปี'];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text('สรุปรายได้ร้าน',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _onRefresh,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Filter Toggle (สไตล์สวย) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ช่วงเวลา',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        ToggleButtons(
                          isSelected: [
                            selectedFilterIndex == 0,
                            selectedFilterIndex == 1,
                            selectedFilterIndex == 2
                          ],
                          borderRadius: BorderRadius.circular(12),
                          borderWidth: 0,
                          selectedBorderColor: Colors.transparent,
                          fillColor: Colors.transparent,
                          // สีให้ดูเป็น gradient ด้านใน card แทน
                          onPressed: (idx) {
                            setState(() {
                              selectedFilterIndex = idx;
                              _applyFilter();
                            });
                          },
                          children: filterLabels.map((label) {
                            final idx = filterLabels.indexOf(label);
                            final bool sel = idx == selectedFilterIndex;
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                gradient: sel
                                    ? LinearGradient(
                                        colors: [
                                          Color(0xFF8E43E7),
                                          Color(0xFFFF6FB5)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                color: sel ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                          color: Colors.purple.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: sel ? Colors.white : Colors.black87,
                                  fontWeight:
                                      sel ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // --- Total income card (ม่วง-ชมพู gradient) ---
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8E43E7), Color(0xFFFF6FB5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF8E43E7).withOpacity(0.18),
                            blurRadius: 12,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ยอดรวมรายได้',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmtCurrency(totalIncome),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${filteredOrders.length} รายการ',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                  SizedBox(height: 6),
                                  GestureDetector(
                                    onTap: () {
                                      // สามารถขยายฟังก์ชัน เช่น export CSV ได้
                                      Fluttertoast.showToast(
                                          msg:
                                              'ดาวน์โหลด/ส่งออกยังไม่เปิดใช้งานครับ');
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.download,
                                              size: 16, color: Colors.white),
                                          SizedBox(width: 6),
                                          Text('ส่งออก',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18),

                    // --- List title ---
                    Text('รายการออเดอร์',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),

                    // --- ถ้าไม่มีรายการแสดงข้อความ ---
                    if (filteredOrders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long,
                                size: 36, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('ไม่พบออเดอร์ในช่วงเวลาที่เลือก',
                                style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      )
                    else
                      // --- แสดงรายการ ---
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final ordIncome = order.ordResIncome ?? 0.0;

                          return GestureDetector(
                            onTap: () {
                              // ไปยังหน้ารายละเอียด order (ถ้าต้องการ)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ResOrderPage(
                                    mergedMenus: order.orlOrderDetail,
                                    deliveryFee: order.ordDevPrice,
                                    order_id: order.ordId,
                                    order_status: order.ordStatus,
                                    previousPage: 'ResIncomeSummaryPage',
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left: order info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('หมายเลขออเดอร์: ${order.ordId}',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          SizedBox(height: 6),
                                          Text(_fmtDate(order.ordDate),
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 12)),
                                          SizedBox(height: 6),
                                          Text(
                                              'รวมรายการ: ${order.totalOrderPrice} บาท',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[800])),
                                        ],
                                      ),
                                    ),

                                    // Right: income
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(_fmtCurrency(ordIncome),
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                        SizedBox(height: 6),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 6),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.pink.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.pink
                                                    .withOpacity(0.16)),
                                          ),
                                          child: Text(
                                            _statusLabel(order.ordStatus),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.pink.shade700),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  String _statusLabel(int? ordStatus) {
    switch (ordStatus ?? -1) {
      case 0:
        return 'รอร้านรับ';
      case 1:
        return 'ร้านรับแล้ว';
      case 2:
        return 'กำลังจัดส่ง';
      case 3:
        return 'ส่งถึงแล้ว';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }
}
