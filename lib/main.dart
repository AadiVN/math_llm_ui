import 'dart:io';
import 'package:flutter/material.dart';
import 'package:math_llm_ui/conversation_page.dart';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = new MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatGpt Clone',
      theme: ThemeData(brightness: Brightness.dark),
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (context) {
          return ConversationPage();
        }

        // add dark and light theme.
        // chatMessages history
      },
    );
  }
}
