import 'package:flutter/material.dart';
import 'package:invoflow/core/widgets/app_app_bar.dart';

import '../widgets/login_form.dart';
import '../widgets/login_header.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppAppBar(title: 'Login', backButton: false),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 150),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [LoginHeader(), SizedBox(height: 80), LoginForm()],
            ),
          ),
        ),
      ),
    );
  }
}
