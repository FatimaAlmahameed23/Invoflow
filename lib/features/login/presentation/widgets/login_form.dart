import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoflow/core/widgets/app_textfield.dart';
import 'package:invoflow/core/widgets/app_button.dart';
import 'package:invoflow/features/invoice/presentation/page/invoice_page.dart';
import 'package:invoflow/features/login/presentation/cubit/auth_cubit.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isPasswordVisible = false;

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const InvoicePage()),
          );
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              AppTextfield(
                controller: emailController,
                hintText: 'Email',
                leftIcon: const Icon(Icons.email),
              ),
              const SizedBox(height: 16),
              AppTextfield(
                controller: passwordController,
                hintText: 'Password',
                leftIcon: const Icon(Icons.lock),
                rightIcon: Icon(
                  isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                obscureText: !isPasswordVisible,
                onChangedRightIcon: togglePasswordVisibility,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : AppButton(
                        onPressed: () {
                          FocusScope.of(context).unfocus();

                          context.read<AuthCubit>().login(
                            email: emailController.text,
                            password: passwordController.text,
                          );
                        },
                        text: 'Login',
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
