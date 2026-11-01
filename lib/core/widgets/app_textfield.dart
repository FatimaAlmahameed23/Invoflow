import 'package:flutter/material.dart';

class AppTextfield extends StatelessWidget {
  final String hintText;
  final Icon? leftIcon;
  final Icon? rightIcon;
  final Function()? onChangedRightIcon;
  final bool obscureText;
  final TextEditingController? controller;

  const AppTextfield({
    super.key,
    required this.hintText,
    this.leftIcon,
    this.rightIcon,
    this.onChangedRightIcon,
    this.obscureText = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        labelText: hintText,
        prefixIcon: leftIcon,
        suffixIcon: rightIcon != null
            ? IconButton(icon: rightIcon!, onPressed: onChangedRightIcon)
            : null,
      ),
    );
  }
}
