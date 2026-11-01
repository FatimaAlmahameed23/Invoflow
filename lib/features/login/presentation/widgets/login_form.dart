import 'package:flutter/material.dart';
import 'package:invoflow/core/widgets/app_textfield.dart';
import 'package:invoflow/core/widgets/app_button.dart';
import 'package:invoflow/features/invoice/page/invoice_page.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

bool isPasswordVisible = false;

class _LoginFormState extends State<LoginForm> {
  @override
  Widget build(BuildContext context) {
    @override
    void togglePasswordVisibility() {
      setState(() {
        isPasswordVisible = !isPasswordVisible;
      });
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          AppTextfield(hintText: 'Email', leftIcon: Icon(Icons.email)),
          SizedBox(height: 16),
          AppTextfield(
            hintText: 'Password',
            leftIcon: Icon(Icons.lock),
            rightIcon: Icon(Icons.visibility),
            obscureText: isPasswordVisible ? false : true,
            onChangedRightIcon: () {
              togglePasswordVisibility();
            },
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InvoicePage()),
                );
              },
              text: 'Login',
            ),
          ),
        ],
      ),
    );
  }
}
