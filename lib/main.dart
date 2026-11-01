import 'package:flutter/material.dart';
import 'features/login/presentation/page/login_page.dart';

void main() => runApp(const InvoFlowApp());

class InvoFlowApp extends StatelessWidget {
  const InvoFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: LoginPage())),
    );
  }
}
