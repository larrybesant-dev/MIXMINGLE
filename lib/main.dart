import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // firebase_options.dart is a placeholder
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MixVy',
      home: Scaffold(
        appBar: AppBar(title: const Text('MixVy Home')),
        body: const Center(child: Text('Welcome to MixVy!')),
      ),
    );
  }
}
