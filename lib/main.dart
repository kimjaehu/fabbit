import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fabbit/pages/home.dart';
import 'package:flutter/material.dart';

void main() {
  Firestore.instance.settings(timestampsInSnapshotsEnabled: true).then(
    (_) {
      // print("Timestamps enabled in snapshots\n");
    }, onError: (_) {
      // print("Error enabling timestamps in snapshots\n");
    }
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fabbit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.blueGrey[900],
        accentColor: Colors.cyanAccent[700],
      ),
      home: Home(),
    );
  }
}
