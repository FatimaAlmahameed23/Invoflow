import 'package:flutter/material.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool? backButton;

  const AppAppBar({super.key, required this.title, this.backButton = true});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: backButton == true && Navigator.of(context).canPop()
          ? BackButton(onPressed: () => Navigator.of(context).maybePop())
          : null,
      title: Text(title),
      foregroundColor: Colors.white,
      backgroundColor: const Color(0xFF92257E),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
