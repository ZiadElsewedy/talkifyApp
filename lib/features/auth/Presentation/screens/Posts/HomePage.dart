import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mydrawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        centerTitle: true,
        
        
      ),
      drawer: MyDrawer()
    );
  }
}

