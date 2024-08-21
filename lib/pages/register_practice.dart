import 'dart:developer';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/customers_regis_post_req.dart';
import 'package:mobile_miniproject_app/pages/login.dart';
import 'package:mobile_miniproject_app/pages/login_practice.dart';
import 'package:mobile_miniproject_app/pages/showtrip_practice.dart';

class RegisterPracticePage extends StatefulWidget {
  const RegisterPracticePage({super.key});

  @override
  State<RegisterPracticePage> createState() => _RegisterPracticeState();
}

class _RegisterPracticeState extends State<RegisterPracticePage> {
  String txt = '';
  TextEditingController nameCtl = TextEditingController();
  TextEditingController phoneCtl = TextEditingController();
  TextEditingController emailCtl = TextEditingController();
  TextEditingController passCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  String url = '';

  @override
  void initState() {
    super.initState();
    //อ่านค่า config
    Configuration.getConfig().then((value) {
      url = value['apiEndpoint'];
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงทะเบียนสมาชิกใหม่'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text(
            'ชื่อ-นามสกุล',
            style: TextStyle(
              color: Color.fromARGB(255, 15, 15, 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16.0),
            child: TextField(
              controller: nameCtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
              ),
            ),
          ),
          const Text(
            'หมายเลขโทรศัพท์',
            style: TextStyle(
              color: Color.fromARGB(255, 15, 15, 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16.0),
            child: TextField(
              controller: phoneCtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
              ),
            ),
          ),
          const Text(
            'อีเมล',
            style: TextStyle(
              color: Color.fromARGB(255, 15, 15, 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16.0),
            child: TextField(
              controller: emailCtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
              ),
            ),
          ),
          const Text(
            'รหัสผ่าน',
            style: TextStyle(
              color: Color.fromARGB(255, 15, 15, 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16.0),
            child: TextField(
              obscureText: true,
              controller: passCtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
              ),
            ),
          ),
          const Text(
            'ยืนยันรหัสผ่าน',
            style: TextStyle(
              color: Color.fromARGB(255, 15, 15, 15),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 16.0),
            child: TextField(
              obscureText: true,
              controller: conPassCtl,
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderSide: BorderSide(width: 1)),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: FilledButton(
                  onPressed: register,
                  child: Text('สมัครสมาชิก'),
                ),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: alr_have,
                child: const Text(
                  'หากมีบัญชีอยู่แล้ว?',
                  style: TextStyle(color: Color.fromARGB(255, 3, 3, 3)),
                ),
              ),
              TextButton(
                onPressed: login,
                child: const Text(
                  'เข้าสู่ระบบ',
                  style: TextStyle(color: Color.fromARGB(255, 90, 6, 139)),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 80.0),
            child: Text(
              txt,
              style: TextStyle(color: Color.fromARGB(255, 223, 7, 7)),
            ),
          ),
        ]),
      ),
    );
  }

  void register() async {
    if (nameCtl.text.isEmpty ||
        phoneCtl.text.isEmpty ||
        emailCtl.text.isEmpty ||
        passCtl.text.isEmpty ||
        conPassCtl.text.isEmpty ||
        passCtl.text != conPassCtl.text) {
      log('Fields cannot be empty');
      return;
    } else {}

    var model = CustomersRegisterPostRequest(
        fullname: nameCtl.text,
        phone: phoneCtl.text,
        email: emailCtl.text,
        password: passCtl.text,
        confirmPass: conPassCtl.text,
        image:
            'http://202.28.34.197:8888/contents/4a00cead-afb3-45db-a37a-c8bebe08fe0d.png');
    try {
      var Value = await http.post(Uri.parse("$url/customers"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          //jsonEncode() = Convert object to Json String
          // body: jsonEncode(data))
          body: customersRegisterPostRequestToJson(model));
      // var cust = customersLoginPostResponseFromJson(Value.body);
      log('Registration is successful');
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage_practice(),
          ));
    } catch (err) {
      log(err.toString());
      setState(() {
        txt = "Registration is failed";
      });
    }
  }

  void alr_have() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage_practice(),
        ));
  }

  void login() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage_practice(),
        ));
  }
}

//TEST mini project flutter connect to Node.js

// import 'dart:convert';
// import 'dart:developer';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:mobile_miniproject_app/config/config.dart';
// import 'package:mobile_miniproject_app/models/response/testGetREs.dart';

// class UserInfoPage extends StatefulWidget {
//   const UserInfoPage({Key? key}) : super(key: key);

//   @override
//   State<UserInfoPage> createState() => _UserInfoPageState();
// }

// class _UserInfoPageState extends State<UserInfoPage> {
//   String url = '';
//   List<TestGetRes> userDataList = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     Configuration.getConfig().then((value) {
//       url = value['apiEndpoint'];
//       fetchUserData();
//     });
//   }

//   Future<void> fetchUserData() async {
//     try {
//       var response = await http.get(Uri.parse('$url/db/userxx'));
//       if (response.statusCode == 200) {
//         setState(() {
//           userDataList = testGetResFromJson(response.body);
//           isLoading = false;
//         });
//       } else {
//         throw Exception('Failed to load user data');
//       }
//     } catch (e) {
//       log('Error fetching user data: $e');
//       setState(() {
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('ข้อมูลผู้ใช้'),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : ListView.builder(
//               itemCount: userDataList.length,
//               itemBuilder: (context, index) {
//                 final user = userDataList[index];
//                 return Card(
//                   margin: const EdgeInsets.all(8.0),
//                   child: Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text('UID: ${user.uid}'),
//                         Text('Email: ${user.email}'),
//                         Text('Username: ${user.username}'),
//                         Text('Type: ${user.type.toString().split('.').last}'),
//                         Text('Bio: ${user.bio ?? "N/A"}'),
//                         Text('User Image: ${user.userImage ?? "N/A"}'),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//     );
//   }
// }
