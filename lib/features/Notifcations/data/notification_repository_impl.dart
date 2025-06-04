import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Notifcations/Domain/Entite/Notification.dart';
import 'package:talkifyapp/features/Notifcations/Domain/repo/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Future<List<Notification>> getNotifications(String userId) async {
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();
          
      return notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        return Notification.fromJson({
          ...data,
          'id': doc.id,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get notifications: $e');
    }
  }

  @override
  Future<void> createNotification(Notification notification) async {
    try {
      await _firestore.collection('notifications').add(notification.toJson());
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }
  
  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  @override
  Future<int> getUnreadNotificationCount(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .count()
          .get();
          
      return querySnapshot.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get unread notification count: $e');
    }
  }

  @override
  Stream<List<Notification>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return Notification.fromJson({
              ...data,
              'id': doc.id,
            });
          }).toList();
        });
  }
} 