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
import 'package:fl_chart/fl_chart.dart';

class RiderIncomeSummaryPage extends StatefulWidget {
  const RiderIncomeSummaryPage({super.key});

  @override
  State<RiderIncomeSummaryPage> createState() => _RiderIncomeSummaryPageState();
}

class _RiderIncomeSummaryPageState extends State<RiderIncomeSummaryPage> {
  // --- state data ---
  String url = '';
  bool isLoading = true;
  List<CusOrderGetResponse> ordersList = [];
  List<CusOrderGetResponse> filteredOrders = [];
  double totalIncome = 0.0;

  // filter: 0 = สัปดาห์, 1 = เดือน, 2 = ปี
  int selectedFilterIndex = 0;

  // ข้อมูลสำหรับกราฟ
  Map<String, double> chartData = {};

  final DateFormat _dateFmt = DateFormat('dd/MM/yyyy เวลา HH:mm น.');
  final NumberFormat _currencyFmt =
      NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  @override
  void initState() {
    super.initState();
    _pageInit();
  }

  Future<void> _pageInit() async {
    try {
      final cfg = await Configuration.getConfig();
      url = cfg['apiEndpoint'] ?? '';
    } catch (e) {
      log('Cannot load config: $e');
    }

    await LoadAllOrder(context);
    _applyFilter();
  }

  Future<void> LoadAllOrder(BuildContext context) async {
    setState(() {
      isLoading = true;
    });

    try {
      int rid_id = context.read<ShareData>().user_info_send.uid;
      final res_RidInfo =
          await http.get(Uri.parse("$url/db/loadRidHisOrder/$rid_id"));

      if (res_RidInfo.statusCode == 200) {
        final List<CusOrderGetResponse> list =
            (json.decode(res_RidInfo.body) as List)
                .map((e) => CusOrderGetResponse.fromJson(e))
                .toList();

        ordersList.clear();
        ordersList = list;
      } else {
        log('LoadAllOrder: non-200 -> ${res_RidInfo.statusCode}');
      }
    } catch (e) {
      log('เกิดข้อผิดพลาดในการโหลดคำสั่งซื้อ: $e');
      Fluttertoast.showToast(msg: 'ไม่สามารถโหลดคำสั่งซื้อได้');
    }

    setState(() {
      isLoading = false;
    });
  }

  void _applyFilter() {
    DateTime now = DateTime.now().toUtc();
    DateTime start;

    if (selectedFilterIndex == 0) {
      // รายสัปดาห์ -> ย้อนหลัง 7 วัน
      start =
          DateTime(now.year, now.month, now.day).subtract(Duration(days: 6));
    } else if (selectedFilterIndex == 1) {
      // รายเดือน -> เริ่มต้นเดือนนี้
      start = DateTime(now.year, now.month, 1);
    } else {
      // รายปี -> เริ่มต้นปีนี้
      start = DateTime(now.year, 1, 1);
    }

    final List<CusOrderGetResponse> result = ordersList.where((o) {
      // เปลี่ยนจาก ordResIncome เป็น ordRidIncome สำหรับไรเดอร์
      if (o.ordRidIncome == null) return false;
      DateTime dt = o.ordDate.toUtc();
      return !dt.isBefore(start) && !dt.isAfter(now);
    }).toList();

    double sum = 0.0;
    for (var o in result) {
      sum += (o.ordRidIncome ?? 0.0);
    }

    // คำนวณข้อมูลกราฟ
    _calculateChartData(result);

    setState(() {
      filteredOrders = result;
      totalIncome = sum;
    });
  }

  void _calculateChartData(List<CusOrderGetResponse> orders) {
    Map<String, double> data = {};

    if (selectedFilterIndex == 0) {
      // รายสัปดาห์ - แสดงวันที่และชื่อวัน
      DateTime now = DateTime.now().toUtc();
      for (int i = 6; i >= 0; i--) {
        DateTime day =
            DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        String dayName = _getThaiDayName(day.weekday);
        String label = '${day.day}\n$dayName';
        data[label] = 0.0;
      }

      for (var order in orders) {
        DateTime dt = order.ordDate.toUtc();
        DateTime day = DateTime(dt.year, dt.month, dt.day);
        String dayName = _getThaiDayName(day.weekday);
        String label = '${day.day}\n$dayName';
        data[label] = (data[label] ?? 0.0) + (order.ordRidIncome ?? 0.0);
      }
    } else if (selectedFilterIndex == 1) {
      // รายเดือน - แสดงชื่อเดือนภาษาไทย
      DateTime now = DateTime.now().toUtc();
      for (int i = 11; i >= 0; i--) {
        DateTime month = DateTime(now.year, now.month - i, 1);
        String label = _getThaiMonthName(month.month);
        data[label] = 0.0;
      }

      for (var order in orders) {
        DateTime dt = order.ordDate.toUtc();
        String label = _getThaiMonthName(dt.month);
        data[label] = (data[label] ?? 0.0) + (order.ordRidIncome ?? 0.0);
      }
    } else {
      // รายปี - แสดงเลขปี
      DateTime now = DateTime.now().toUtc();
      for (int i = 4; i >= 0; i--) {
        int year = now.year - i;
        String label = '${year + 543}'; // แปลงเป็น พ.ศ.
        data[label] = 0.0;
      }

      for (var order in orders) {
        DateTime dt = order.ordDate.toLocal();
        String label = '${dt.year + 543}';
        data[label] = (data[label] ?? 0.0) + (order.ordRidIncome ?? 0.0);
      }
    }

    chartData = data;
  }

  String _getThaiDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'จ.';
      case 2:
        return 'อ.';
      case 3:
        return 'พ.';
      case 4:
        return 'พฤ.';
      case 5:
        return 'ศ.';
      case 6:
        return 'ส.';
      case 7:
        return 'อา.';
      default:
        return '';
    }
  }

  String _getThaiMonthName(int month) {
    switch (month) {
      case 1:
        return 'ม.ค.';
      case 2:
        return 'ก.พ.';
      case 3:
        return 'มี.ค.';
      case 4:
        return 'เม.ย.';
      case 5:
        return 'พ.ค.';
      case 6:
        return 'มิ.ย.';
      case 7:
        return 'ก.ค.';
      case 8:
        return 'ส.ค.';
      case 9:
        return 'ก.ย.';
      case 10:
        return 'ต.ค.';
      case 11:
        return 'พ.ย.';
      case 12:
        return 'ธ.ค.';
      default:
        return '';
    }
  }

  String _fmtCurrency(double value) {
    try {
      return _currencyFmt.format(value);
    } catch (e) {
      return '฿ ${value.toStringAsFixed(2)}';
    }
  }

  String _fmtDate(DateTime dt) {
    try {
      return _dateFmt.format(dt.toUtc());
    } catch (e) {
      return dt.toString();
    }
  }

  Future<void> _onRefresh() async {
    await LoadAllOrder(context);
    _applyFilter();
  }

  Widget _buildChart() {
    if (chartData.isEmpty) {
      return Container(
        height: 200,
        child: Center(
          child: Text('ไม่มีข้อมูลสำหรับแสดงกราฟ',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    List<String> labels = chartData.keys.toList();
    double maxY = chartData.values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 1000; // ป้องกันการหารด้วย 0

    return Container(
      height: 250,
      padding: EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _fmtCurrency(rod.toY),
                  TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return Text('');
                },
                reservedSize: 42,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 50,
                getTitlesWidget: (value, meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          barGroups: labels.asMap().entries.map((entry) {
            int index = entry.key;
            String label = entry.value;
            double value = chartData[label] ?? 0.0;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: value,
                  gradient: LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: selectedFilterIndex == 0 ? 20 : 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filterLabels = ['รายสัปดาห์', 'รายเดือน', 'รายปี'];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text('สรุปรายได้ไรเดอร์',
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
                    // --- Filter Toggle ---
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
                                          Color(0xFF4CAF50),
                                          Color(0xFF8BC34A)
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
                                          color: Colors.green.withOpacity(0.2),
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

                    // --- Total income card ---
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF4CAF50).withOpacity(0.18),
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
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18),

                    // --- กราฟแท่ง ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('กราฟรายได้',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          _buildChart(),
                        ],
                      ),
                    ),

                    SizedBox(height: 18),

                    // --- List title ---
                    Text('รายการออเดอร์',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),

                    // --- Order list ---
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          final ordIncome = order.ordRidIncome ?? 0.0;

                          return GestureDetector(
                            onTap: () {
                              // สามารถเพิ่ม navigation ไปหน้ารายละเอียดของไรเดอร์ได้
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
                                              'ค่าส่ง: ${order.ordDevPrice} บาท',
                                              style: TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.grey[800])),
                                        ],
                                      ),
                                    ),
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
                                                Colors.green.withOpacity(0.08),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: Colors.green
                                                    .withOpacity(0.16)),
                                          ),
                                          child: Text(
                                            _statusLabel(order.ordStatus),
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green.shade700),
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
