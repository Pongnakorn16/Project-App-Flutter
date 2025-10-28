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

class ResIncomeSummaryPage extends StatefulWidget {
  const ResIncomeSummaryPage({super.key});

  @override
  State<ResIncomeSummaryPage> createState() => _ResIncomeSummaryPageState();
}

class _ResIncomeSummaryPageState extends State<ResIncomeSummaryPage> {
  String url = '';
  bool isLoading = true;
  List<CusOrderGetResponse> ordersList = [];
  List<CusOrderGetResponse> filteredOrders = [];
  double totalIncome = 0.0;
  int selectedMonth = DateTime.now().month; // สำหรับรายวัน
  int selectedYearForDay = DateTime.now().year; // สำหรับรายวัน
  int selectedYearForMonth = DateTime.now().year; // สำหรับรายเดือน

  int selectedFilterIndex = 0; // 0=วัน, 1=เดือน, 2=ปี
  Map<String, double> chartData = {};
  int selectedYear = DateTime.now().toUtc().year;
  List<int> availableYears = [];

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
      int res_id = context.read<ShareData>().user_info_send.uid;
      final res_ResInfo =
          await http.get(Uri.parse("$url/db/loadResOrder/$res_id"));

      if (res_ResInfo.statusCode == 200) {
        final List<CusOrderGetResponse> list =
            (json.decode(res_ResInfo.body) as List)
                .map((e) => CusOrderGetResponse.fromJson(e))
                .toList();

        ordersList = list;
        _generateAvailableYears();
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

  void _generateAvailableYears() {
    Set<int> years = {};
    for (var order in ordersList) {
      if (order.ordResIncome != null && (order.ordStatus ?? -1) >= 2) {
        years.add(order.ordDate.year);
      }
    }
    availableYears = years.toList()..sort((a, b) => b.compareTo(a));
    if (availableYears.isNotEmpty && !availableYears.contains(selectedYear)) {
      selectedYear = availableYears.first;
    }
  }

  void _applyFilter() {
    List<CusOrderGetResponse> result = ordersList.where((o) {
      if (o.ordResIncome == null || (o.ordStatus ?? -1) < 2) return false;

      if (selectedFilterIndex == 0) {
        // รายวัน: กรองตามเดือนและปี
        return o.ordDate.year == selectedYearForDay &&
            o.ordDate.month == selectedMonth;
      } else if (selectedFilterIndex == 1) {
        // รายเดือน: กรองตามปี
        return o.ordDate.year == selectedYearForMonth;
      }
      return true; // รายปี
    }).toList();

    totalIncome = result.fold(0.0, (sum, o) => sum + (o.ordResIncome ?? 0.0));
    _calculateChartData(result);

    setState(() {
      filteredOrders = result;
    });
  }

  Widget _buildFilterDropdowns() {
    final dropdownTextStyle = TextStyle(color: Colors.white);
    final dropdownBgColor = Color.fromARGB(255, 19, 19, 19);

    if (selectedFilterIndex == 0) {
      // รายวัน
      return Row(
        children: [
          DropdownButton<int>(
            value: selectedMonth,
            items: List.generate(12, (index) {
              int month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(_getThaiMonthName(month), style: dropdownTextStyle),
              );
            }),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedMonth = val;
                  _applyFilter();
                });
              }
            },
            dropdownColor: dropdownBgColor,
            underline: SizedBox(),
            iconEnabledColor: Colors.white,
          ),
          SizedBox(width: 12),
          DropdownButton<int>(
            value: selectedYearForDay,
            items: availableYears.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text('${year + 543}', style: dropdownTextStyle),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedYearForDay = val;
                  _applyFilter();
                });
              }
            },
            dropdownColor: dropdownBgColor,
            underline: SizedBox(),
            iconEnabledColor: Colors.white,
          ),
        ],
      );
    } else if (selectedFilterIndex == 1) {
      // รายเดือน
      return Row(
        children: [
          DropdownButton<int>(
            value: selectedYearForMonth,
            items: availableYears.map((year) {
              return DropdownMenuItem(
                value: year,
                child: Text('${year + 543}', style: dropdownTextStyle),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  selectedYearForMonth = val;
                  _applyFilter();
                });
              }
            },
            dropdownColor: dropdownBgColor,
            underline: SizedBox(),
            iconEnabledColor: Colors.white,
          ),
        ],
      );
    } else {
      return SizedBox(); // รายปีไม่ต้องเลือกอะไร
    }
  }

  void _calculateChartData(List<CusOrderGetResponse> orders) {
    Map<String, double> data = {};

    if (selectedFilterIndex == 0) {
      // รายวัน
      List<DateTime> allDays = orders
          .map((e) => DateTime(e.ordDate.year, e.ordDate.month, e.ordDate.day))
          .toSet()
          .toList();
      allDays.sort();

      for (var day in allDays) {
        String label = DateFormat('dd/MM/yyyy').format(day);
        data[label] = 0.0;
      }

      for (var order in orders) {
        DateTime day = DateTime(
            order.ordDate.year, order.ordDate.month, order.ordDate.day);
        String label = DateFormat('dd/MM/yyyy').format(day);
        data[label] = (data[label] ?? 0.0) + (order.ordResIncome ?? 0.0);
      }
    } else if (selectedFilterIndex == 1) {
      // รายเดือน
      Map<String, double> temp = {};
      for (var order in orders) {
        String key = '${order.ordDate.month}-${order.ordDate.year}';
        temp[key] = (temp[key] ?? 0.0) + (order.ordResIncome ?? 0.0);
      }

      var sortedKeys = temp.keys.toList()
        ..sort((a, b) {
          final partsA = a.split('-').map(int.parse).toList();
          final partsB = b.split('-').map(int.parse).toList();
          int yearComp = partsA[1].compareTo(partsB[1]);
          if (yearComp != 0) return yearComp;
          return partsA[0].compareTo(partsB[0]);
        });

      for (var key in sortedKeys) {
        final parts = key.split('-').map(int.parse).toList();
        final month = parts[0];
        final year = parts[1];
        String label = '${_getThaiMonthName(month)} ${year + 543}';
        data[label] = temp[key]!;
      }
    } else {
      // รายปี
      Set<int> years = orders.map((e) => e.ordDate.year).toSet();
      List<int> sortedYears = years.toList()..sort();
      for (var year in sortedYears) {
        String label = '${year + 543}';
        data[label] = orders
            .where((o) => o.ordDate.year == year)
            .fold(0.0, (sum, o) => sum + (o.ordResIncome ?? 0.0));
      }
    }

    chartData = data;
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
      return _dateFmt.format(dt);
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
    if (maxY == 0) maxY = 500;

    // interval กราฟซ้ายขวา
    double interval = (maxY / 5).ceilToDouble();
    maxY = interval * 6; // ให้มี space บนสุด

    // กำหนดความกว้างทั้งหมดของกราฟตามจำนวนแท่ง (ลดจาก 50 เป็น 35)
    double chartWidth = labels.length * 35.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        width: chartWidth < MediaQuery.of(context).size.width
            ? MediaQuery.of(context).size.width
            : chartWidth,
        height: 250,
        padding: EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            maxY: maxY,
            minY: 0,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Color(0xFF8E43E7),
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
                      String label = labels[index];

                      // แสดงสั้นตาม filter
                      if (selectedFilterIndex == 0) {
                        // รายวัน dd/MM
                        try {
                          DateTime dt = DateFormat('dd/MM/yyyy').parse(label);
                          label = DateFormat('dd/MM').format(dt);
                        } catch (_) {}
                      } else if (selectedFilterIndex == 1) {
                        // รายเดือน เช่น ม.ค.
                        try {
                          final parts = label.split(' ');
                          label = parts[0]; // แค่เดือน
                        } catch (_) {}
                      } else {
                        // รายปี
                        label = label;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          label,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return Text('');
                  },
                  reservedSize: 32,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    if (value == 0)
                      return Text('0', style: TextStyle(fontSize: 10));
                    if (value >= 1000) {
                      return Text(
                          '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}k',
                          style: TextStyle(fontSize: 10));
                    } else {
                      return Text('${value.toInt()}',
                          style: TextStyle(fontSize: 10));
                    }
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: interval,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                    color: Colors.grey.withOpacity(0.2), strokeWidth: 1);
              },
            ),
            barGroups: labels.asMap().entries.map((entry) {
              int index = entry.key;
              double value = chartData[entry.value] ?? 0.0;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    width: 20, // เพิ่มจาก 16 เป็น 20 เพื่อให้ชิดกันมากขึ้น
                    borderRadius: BorderRadius.circular(6),
                    gradient: LinearGradient(
                      colors: [Color(0xFF8E43E7), Color(0xFFFF6FB5)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> filterLabels = ['รายวัน', 'รายเดือน', 'รายปี'];

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
                    // Filter toggle
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
                                            Color(0xFF8E43E7),
                                            Color(0xFFFF6FB5)
                                          ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight)
                                    : null,
                                color: sel ? null : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color:
                                                Colors.purple.withOpacity(0.2),
                                            blurRadius: 8,
                                            offset: Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Text(label,
                                  style: TextStyle(
                                      color:
                                          sel ? Colors.white : Colors.black87,
                                      fontWeight: sel
                                          ? FontWeight.bold
                                          : FontWeight.w500)),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Total Income Card พร้อม dropdown
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Color(0xFF8E43E7), Color(0xFFFF6FB5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ยอดรวมรายได้',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              Spacer(),
                              Container(
                                width: 160,
                                child: _buildFilterDropdowns(),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmtCurrency(totalIncome),
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${filteredOrders.length} รายการ',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 18),

                    // Chart
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 4))
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

                    // Order List
                    Text('รายการออเดอร์',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8),

                    if (filteredOrders.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(18),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12)),
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
                          final ordIncome = order.ordResIncome ?? 0.0;

                          return GestureDetector(
                            child: Container(
                              margin: EdgeInsets.only(bottom: 12),
                              padding: EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.03),
                                        blurRadius: 8,
                                        offset: Offset(0, 4))
                                  ]),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Order #${order.ordId}',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      SizedBox(height: 4),
                                      Text('${_fmtDate(order.ordDate)}',
                                          style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 12)),
                                    ],
                                  ),
                                  Text(_fmtCurrency(ordIncome),
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
