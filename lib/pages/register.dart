import 'dart:developer';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:mobile_miniproject_app/config/config.dart';
import 'package:mobile_miniproject_app/models/request/customers_regis_post_req.dart';
import 'package:mobile_miniproject_app/pages/Login.dart';
import 'package:mobile_miniproject_app/pages/Home.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  String txt = '';
  TextEditingController emailCtl = TextEditingController();
  TextEditingController usernameCtl = TextEditingController();
  TextEditingController passwordCtl = TextEditingController();
  TextEditingController conPassCtl = TextEditingController();
  TextEditingController walletCtl = TextEditingController();
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(
              child: SizedBox(
                width: 300,
                height: 100,
                child: Image.network(
                  'https://cdn-icons-png.freepik.com/256/16939/16939342.png?semt=ais_hybrid',
                  // กำหนดการจัดตำแหน่งของรูปภาพ
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 16.0, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 79, 78, 78),
                    ),
                  ),
                ],
              ),
            ),
            const Text(
              'Email',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                controller: emailCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Username',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                controller: usernameCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Password',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                obscureText: true,
                controller: passwordCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Confirm Password',
              style: TextStyle(
                color: Color.fromARGB(255, 15, 15, 15),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                obscureText: true,
                controller: conPassCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            const Text(
              'Wallet',
              style: TextStyle(
                color: Color.fromARGB(255, 84, 82, 82),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 16.0),
              child: TextField(
                controller: walletCtl,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color.fromARGB(255, 228, 225, 225),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                      borderSide: BorderSide(width: 1)),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 320,
                  height: 50,
                  child: FilledButton(
                    onPressed: register,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(
                          Color.fromARGB(255, 69, 162, 254)),
                      foregroundColor: WidgetStateProperty.all(Colors.white),
                    ),
                    child: const Text(
                      'Create Account',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w400),
                    ),
                  ),
                )
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 15.0, bottom: 5.0),
              child: Divider(
                color: Colors.grey,
                thickness: 1,
                indent: 10,
                endIndent: 10,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have Account?'),
                TextButton(
                  onPressed: login,
                  style: ButtonStyle(
                    foregroundColor: WidgetStateProperty.all(
                        const Color.fromARGB(255, 69, 162, 254)),
                  ),
                  child: const Text(
                    'Sign in',
                    style: TextStyle(fontWeight: FontWeight.w400),
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
      ),
    );
  }

  void register() async {
    if (emailCtl.text.isEmpty ||
        usernameCtl.text.isEmpty ||
        passwordCtl.text.isEmpty ||
        conPassCtl.text.isEmpty ||
        walletCtl.text.isEmpty ||
        passwordCtl.text != conPassCtl.text) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'แจ้งเตือน',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          content: Text(
            'ข้อมูลไม่ถูกต้องโปรดตรวจสอบความถูกต้อง แล้วลองอีกครั้ง',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0), // Padding ภายนอก
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'ปิด',
                      style: TextStyle(fontSize: 19),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      padding: WidgetStateProperty.all<EdgeInsets>(
                        EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 5), // Padding ภายใน
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      return;
    }

    var model = CustomersRegisterPostRequest(
        email: emailCtl.text,
        username: usernameCtl.text,
        password: passwordCtl.text,
        wallet: int.tryParse(walletCtl.text) ?? 0,
        image:
            'http://202.28.34.197:8888/contents/4a00cead-afb3-45db-a37a-c8bebe08fe0d.png');
    try {
      var Value = await http.post(Uri.parse("$url/db/register/user"),
          headers: {"Content-Type": "application/json; charset=utf-8"},
          body: customersRegisterPostRequestToJson(model));
      log('Registration is successful');
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ));
    } catch (err) {
      log(err.toString());
      setState(() {
        txt = "Registration is failed";
      });
    }
  }

  void login() {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
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
