import 'package:flutter/material.dart';

class AppTextfield extends StatelessWidget {
  String hintText;
  Icon? leftIcon;
  Icon? rightIcon;
  Function()? onChangedRightIcon;
  bool obscureText;

  AppTextfield({
    super.key,
    required this.hintText,
    this.leftIcon,
    this.rightIcon,
    this.onChangedRightIcon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
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
