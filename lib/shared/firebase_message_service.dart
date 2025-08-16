import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class OrderNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void listenOrderChanges(BuildContext context, String targetOrderId,
      void Function(int newStep) onStepChanged) {
    _firestore.collection('BP_Order_detail').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        final orderId = change.doc.id;

        // เช็ค order_id ว่าตรงกับที่เราต้องการหรือไม่
        if (orderId != targetOrderId) continue;

        int orderStep = 0;

        if (change.type == DocumentChangeType.modified) {
          final data = change.doc.data();
          if (data != null && data.containsKey("Order_status")) {
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

            // อัปเดต UI
            onStepChanged(orderStep);

            // แสดง Flushbar
            Flushbar(
              title: statusTitle,
              // message: "Order $orderId ถูกอัปเดต",
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
