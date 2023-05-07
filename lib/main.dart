import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:notemanagement_app/screens/add_note_screen.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:notemanagement_app/screens/signin_screen.dart';

const apiKey = 'AIzaSyAfqKVWfrzABLrOH4SJufT_NrDupigw3ic';
const projectId = 'notemanagement-d15e1';
Future<void> main() async {
  if (kIsWeb) {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: const FirebaseOptions(
      apiKey: "AIzaSyAfqKVWfrzABLrOH4SJufT_NrDupigw3ic",
      projectId: "notemanagement-d15e1",
      storageBucket: "notemanagement-d15e1.appspot.com",
      messagingSenderId: "176133832236",
      appId: "1:176133832236:web:3c4112a0cb4d0970e8db89",
    ));
  } else if (Platform.isAndroid) {
    // NOT running on the web! Y.
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/addNote': (context) => const AddNoteScreen(),
      },
      title: 'Notes management',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const SignInScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
