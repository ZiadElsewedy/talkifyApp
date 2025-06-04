import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Notifcations/presentation/services/in_app_notification_service.dart';

/// A demonstration widget for showing how to use the in-app notification
class NotificationDemoScreen extends StatelessWidget {
  const NotificationDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Demos'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                InAppNotificationService.show(
                  context: context,
                  title: 'New Like',
                  message: '❤️ Ziad liked your post',
                  type: NotificationType.like,
                  userId: 'demoUserId',
                  postId: 'demoPostId',
                  userAvatar: 'https://ui-avatars.com/api/?name=Ziad&background=random',
                );
              },
              child: const Text('Show Like Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                InAppNotificationService.show(
                  context: context,
                  title: 'New Comment',
                  message: '💬 Ziad commented on your post',
                  type: NotificationType.comment,
                  userId: 'demoUserId',
                  postId: 'demoPostId',
                  userAvatar: 'https://ui-avatars.com/api/?name=Ziad&background=random',
                );
              },
              child: const Text('Show Comment Notification'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                InAppNotificationService.show(
                  context: context,
                  title: 'New Follower',
                  message: '👤 Ziad started following you',
                  type: NotificationType.follow,
                  userId: 'demoUserId',
                  userAvatar: 'https://ui-avatars.com/api/?name=Ziad&background=random',
                );
              },
              child: const Text('Show Follow Notification'),
            ),
          ],
        ),
      ),
    );
  }
} 