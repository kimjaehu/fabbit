import 'package:fabbit/pages/home.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fabbit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.cyan[400],
        accentColor: Colors.red[300],
      ),
      home: Home(),
    );
  }
}
