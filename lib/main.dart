import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gramyshare/screens/home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // TestWidgetsFlutterBinding.ensureInitialized();
  Firestore.instance
      .settings(persistenceEnabled: true, sslEnabled: true,)
      .then((_) => print('success'), onError: (_){
        print(_);
      });
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.pink[200],
        // accentColor: Colors.black87,
      ),
      home: Home(),
    );
  }
}
