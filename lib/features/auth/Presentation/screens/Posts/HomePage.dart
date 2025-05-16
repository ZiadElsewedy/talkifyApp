import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/pages/upload_post_page.dart' show UploadPostPage;
import 'package:talkifyapp/features/auth/Presentation/screens/components/Mydrawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Page'),
        actions: [
        // upload new post button
        IconButton(
          onPressed: () => Navigator.push(
            context,
             MaterialPageRoute(
              builder: (context) => const UploadPostPage())),
           icon: const Icon(Icons.add))
        ],
      ),
      drawer: MyDrawer()
    );
  }
}

