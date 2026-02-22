// test_screen.dart
import 'package:flutter/material.dart';

class TestScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Asset Test')),
      body: Center(
        child: Image.asset(
          'assets/images/animals/1.png',
          width: 200,
          height: 200,
        ),
      ),
    );
  }
}