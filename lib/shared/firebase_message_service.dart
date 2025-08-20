import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class OrderNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenOrderChanges(BuildContext context, int cusId,
      void Function(String orderId, int newStep) onStepChanged) {
    _firestore.collection('BP_Order_detail').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final data = change.doc.data();
        if (data == null) continue;

        // เช็ค cus_id ก่อน
        if (data["cus_id"] != cusId) continue;

        final orderId = change.doc.id;
        int orderStep = 0;

        if (change.type == DocumentChangeType.modified) {
          if (data.containsKey("Order_status")) {
            orderStep = data["Order_status"];

            // กำหนดข้อความ title ตามค่า Order_status
            String statusTitle;
            switch (orderStep) {
              case 1:
                statusTitle = "กำลังเตรียมอาหาร";
                break;
              case 2:
                statusTitle = "กำลังส่ง";
                break;
              case 3:
                statusTitle = "จัดส่งสำเร็จแล้ว";
                break;
              default:
                statusTitle = "Order Updated";
            }

            // อัปเดต UI พร้อมส่ง orderId
            onStepChanged(orderId, orderStep);

            // แสดง Flushbar
            Flushbar(
              title: statusTitle,
              message: "กรุณารอสักครู่",
              duration: Duration(seconds: 3),
              flushbarPosition: FlushbarPosition.TOP,
              margin: EdgeInsets.all(8),
              borderRadius: BorderRadius.circular(8),
              backgroundColor: Colors.deepPurple,
            ).show(context);
          }
        }
      }
    });
  }
}
