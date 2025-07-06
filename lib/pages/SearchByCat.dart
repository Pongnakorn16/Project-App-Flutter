// file: search_result_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/response/ResInfoGetRes.dart';
import '../models/response/ResTypeGetRes.dart';
import '../shared/share_data.dart';

class SearchByCatPage extends StatelessWidget {
  final int typeId;

  const SearchByCatPage({super.key, required this.typeId});

  @override
  Widget build(BuildContext context) {
    final allCategories = context.read<ShareData>().restaurant_type;
    final allRestaurants = context.watch<ShareData>().restaurant_near;

    // หา category ที่ตรงกับ typeId (มั่นใจว่าต้องเจอ)
    final selectedType =
        allCategories.firstWhere((cat) => cat.type_id == typeId);

    // ชื่อหมวดหมู่ที่เลือก
    final typeName = selectedType.type_name.toLowerCase();

    // กรองร้านที่มี type_id ตรง หรือ ชื่อร้านมีคำในชื่อหมวดหมู่
    final filtered = allRestaurants.where((r) {
      final resName = r.res_name.toLowerCase();
      final matchByTypeId = r.res_type_id == typeId;
      final matchByName = resName.contains(typeName);
      return matchByTypeId || matchByName;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('ร้านในหมวดหมู่: ${selectedType.type_name}'),
      ),
      body: filtered.isEmpty
          ? const Center(child: Text("ไม่พบร้านที่ตรงกับหมวดหมู่"))
          : ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final res = filtered[index];
                return ListTile(
                  leading: Image.network(res.res_image, width: 50, height: 50),
                  title: Text(res.res_name),
                  subtitle: Text("ID: ${res.res_id}"),
                  onTap: () {
                    print("เลือก ${res.res_name}");
                  },
                );
              },
            ),
    );
  }
}
