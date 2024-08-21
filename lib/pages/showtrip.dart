import 'package:flutter/material.dart';

class ShowtripPage extends StatefulWidget {
  const ShowtripPage({super.key});

  @override
  State<ShowtripPage> createState() => _ShowtripPageState();
}

class _ShowtripPageState extends State<ShowtripPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการทริป'),
      ),
      body: Container(),
    );
  }
}
