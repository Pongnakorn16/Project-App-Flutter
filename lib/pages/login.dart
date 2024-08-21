import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          const Text(
            'Hello World!!!',
            style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 30),
            child: TextField(
              decoration: InputDecoration(
                  border: OutlineInputBorder(borderSide: BorderSide(width: 1))),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ElevatedButton(
                      onPressed: () {}, child: const Text('Elvated Button')),
                  FilledButton(
                      onPressed: () {}, child: const Text('Filled Button')),
                  OutlinedButton(
                      onPressed: () {}, child: const Text('Outline Button')),
                  TextButton(
                      onPressed: () {}, child: const Text('Text Button')),
                  IconButton(
                      onPressed: () {}, icon: const Icon(Icons.file_download)),
                  Image.asset('assets/images/l-intro-1700173897.jpg'),
                  Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/c/c3/The_Rock_2023.jpg')
                ],
              ),
            ),
          ),
        ],
      ),

      //  SizedBox(
      //   width: MediaQuery.of(context).size.width,
      //   child: Container(
      //     color: Colors.amber,
      //     child: Column(
      //       mainAxisAlignment: MainAxisAlignment.spaceAround,
      //       children: [
      //         Row(
      //           children: [
      //             SizedBox(
      //               width: 100,
      //               height: 100,
      //               child: Container(
      //                 color: Colors.blue,
      //               ),
      //             ),
      //           ],
      //         ),
      //         Row(
      //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //           children: [
      //             SizedBox(
      //                 width: 100,
      //                 height: 100,
      //                 child: Container(
      //                   color: Colors.purple,
      //                 )),
      //             Row(
      //               children: [
      //                 Padding(
      //                   padding: const EdgeInsets.symmetric(horizontal: 20),
      //                   child: SizedBox(
      //                       width: 100,
      //                       height: 100,
      //                       child: Container(
      //                         color: Colors.red,
      //                       )),
      //                 ),
      //                 SizedBox(
      //                     width: 100,
      //                     height: 100,
      //                     child: Container(
      //                       color: Colors.green,
      //                     )),
      //               ],
      //             ),
      //           ],
      //         ),
      //       ],
      //     ),
      //   ),
      // ));
    );
  }
}
