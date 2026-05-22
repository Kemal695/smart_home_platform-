import 'package:flutter/material.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
        child: Image.asset(
        'assets/branding/login_logo.png',
        height: 50,
      ),
    );
  }
}
