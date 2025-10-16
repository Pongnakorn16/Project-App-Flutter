import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

class OrderNotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  int _lastNotifiedStep = -1; // ✅ เก็บสถานะล่าสุด

  void listenOrderChanges(BuildContext context, int ordId,
      void Function(String orderId, int newStep) onStepChanged) {
    _firestore
        .collection('BP_Order_detail')
        .doc('order$ordId')
        .snapshots()
        .listen((snapshot) {
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final orderStep = data["Order_status"] ?? 0;

      // ✅ ป้องกันการแสดงซ้ำ
      if (orderStep == _lastNotifiedStep) {
        print('⏭️ สถานะเหมือนเดิม ไม่แสดง notification');
        return;
      }

      print('🔔 สถานะเปลี่ยน: $_lastNotifiedStep -> $orderStep');
      _lastNotifiedStep = orderStep;

      String statusTitle;
      String statusMessage;

      switch (orderStep) {
        // case 0:
        //   statusTitle = "รอร้านยืนยัน";
        //   statusMessage = "รอร้านยืนยันออเดอร์";
        //   break;
        // case 1:
        //   statusTitle = "กำลังเตรียมอาหาร";
        //   statusMessage = "ร้านกำลังเตรียมอาหารของคุณ";
        //   break;
        case 2:
          statusTitle = "กำลังส่ง";
          statusMessage = "ไรเดอร์กำลังเดินทางไปส่ง";
          break;
        case 3:
          statusTitle = "จัดส่งสำเร็จแล้ว";
          statusMessage = "อาหารมาถึงแล้ว";
          break;
        default:
          return;
      }

      // อัปเดต UI
      onStepChanged('order$ordId', orderStep);

      // แสดง Flushbar
      Flushbar(
        title: statusTitle,
        message: statusMessage,
        duration: Duration(seconds: 3),
        flushbarPosition: FlushbarPosition.TOP,
        margin: EdgeInsets.all(8),
        borderRadius: BorderRadius.circular(8),
        backgroundColor: Colors.deepPurple,
        // icon: Icon(
        //   orderStep == 3 ? Icons.check_circle : Icons.notifications,
        //   color: Colors.white,
        // ),
      ).show(context);
    });
  }
}
