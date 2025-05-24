import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkifyapp/features/auth/domain/entities/AppUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String initialAvatarUrl;
  final String? heroTag;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    required this.initialAvatarUrl,
    this.heroTag,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late Future<AppUser?> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = _fetchUserDetails();
  }

  Future<AppUser?> _fetchUserDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      final userData = doc.data()!;
      return AppUser.fromJson(userData);
    } catch (e) {
      print('Error fetching user details: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Info'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<AppUser?>(
        future: _userFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data;
          if (user == null) {
            // Fallback to using the initial data passed to this page
            return _buildUserInfoWithFallback();
          }

          return _buildUserInfo(user);
        },
      ),
    );
  }

  Widget _buildUserInfoWithFallback() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          widget.heroTag != null
              ? Hero(
                  tag: widget.heroTag!,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: widget.initialAvatarUrl.isNotEmpty
                        ? CachedNetworkImageProvider(widget.initialAvatarUrl)
                        : null,
                    child: widget.initialAvatarUrl.isEmpty
                        ? Text(
                            widget.userName.isNotEmpty
                                ? widget.userName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(fontSize: 40, color: Colors.black54),
                          )
                        : null,
                  ),
                )
              : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: widget.initialAvatarUrl.isNotEmpty
                      ? CachedNetworkImageProvider(widget.initialAvatarUrl)
                      : null,
                  child: widget.initialAvatarUrl.isEmpty
                      ? Text(
                          widget.userName.isNotEmpty
                              ? widget.userName[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.black54),
                        )
                      : null,
                ),
          const SizedBox(height: 16),
          
          // Name
          GestureDetector(
            onTap: () => _navigateToUserProfile(),
            child: Text(
              widget.userName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Status - Unknown
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Status unknown',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          const Text(
            'No additional information available',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfo(AppUser user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile Picture
          widget.heroTag != null
              ? Hero(
                  tag: widget.heroTag!,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: user.profilePictureUrl.isNotEmpty
                        ? CachedNetworkImageProvider(user.profilePictureUrl)
                        : null,
                    child: user.profilePictureUrl.isEmpty
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 40, color: Colors.black54),
                          )
                        : null,
                  ),
                )
              : CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: user.profilePictureUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user.profilePictureUrl)
                      : null,
                  child: user.profilePictureUrl.isEmpty
                      ? Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 40, color: Colors.black54),
                        )
                      : null,
                ),
          const SizedBox(height: 16),
          
          // Name
          GestureDetector(
            onTap: () => _navigateToUserProfile(),
            child: Text(
              user.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          
          // Online Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: user.isOnline ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                user.isOnline 
                    ? 'Online'
                    : user.lastSeen != null 
                        ? 'Last seen ${timeago.format(user.lastSeen!)}'
                        : 'Offline',
                style: TextStyle(
                  fontSize: 16,
                  color: user.isOnline ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Contact Information Section
          _buildInfoSection(
            title: 'Contact Information',
            items: [
              if (user.email.isNotEmpty)
                _buildInfoItem(
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: user.email,
                ),
              if (user.phoneNumber.isNotEmpty)
                _buildInfoItem(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: user.phoneNumber,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        ...items,
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Colors.black54),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfilePage(userId: widget.userId),
      ),
    );
  }
} 