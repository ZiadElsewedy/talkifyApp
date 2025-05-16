import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/auth/Presentation/screens/Posts/domain/Entite/Posts.dart';

class PostTile extends StatelessWidget {
   PostTile({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(post.UserName),
            subtitle: Text(post.Text),
          ),
          if (post.imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: post.imageUrl,
              placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
              fit: BoxFit.cover,
            ),
          Text(post.timestamp.toLocal().toString()),
        ],
      ),
    );
  }
}