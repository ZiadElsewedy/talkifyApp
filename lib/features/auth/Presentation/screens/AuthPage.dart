import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/LoginPage.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/RegisterPage.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
// this page determines which page to show
bool showLogin = true;
void togglePages() {
  setState(() {
    showLogin = !showLogin;
  });
}

@override
Widget build(BuildContext context) {
  if (showLogin) {
    return LoginPage(togglePages: togglePages);
  } else {
    return Registerpage(togglePages: togglePages);
  }
}
}


