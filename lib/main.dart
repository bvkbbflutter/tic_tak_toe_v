import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tic_tac_toe_v/firebase_options.dart';
import 'package:tic_tac_toe_v/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize the firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform
  );

  // finally run the app
  runApp(const MyApp());
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade300,
        colorScheme: ColorScheme.light(
          primary: Colors.grey.shade300,
          inversePrimary: Colors.grey.shade100,
          secondary: Colors.grey.shade600
        )
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.grey.shade800,
        colorScheme: ColorScheme.dark(
          primary: Colors.grey.shade800,
          inversePrimary: Colors.grey.shade700,
          secondary: Colors.grey.shade900
        )
      ),
      home: HomePage(),
      themeMode: ThemeMode.system,
    );
  }
}