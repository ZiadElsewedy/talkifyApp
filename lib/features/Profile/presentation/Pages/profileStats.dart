// this page we will show the stats of the user
// like the number of followers, the number of following, the number of posts
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';

class ProfileStats extends StatelessWidget {
  const ProfileStats({
    super.key, 
    required this.profileUser, 
    required this.followCount, 
    required this.followingCount, 
    required this.postCount,
    this.onTapFollowers,
    this.onTapFollowing,
    this.onTapPosts,
  });
  
  final ProfileUser profileUser;
  final int followCount;
  final int followingCount;
  final int postCount;
  final VoidCallback? onTapFollowers;
  final VoidCallback? onTapFollowing;
  final VoidCallback? onTapPosts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            context,
            count: followCount,
            label: 'Followers',
            onTap: onTapFollowers,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            context,
            count: followingCount,
            label: 'Following',
            onTap: onTapFollowing,
          ),
          _buildVerticalDivider(),
          _buildStatItem(
            context,
            count: postCount,
            label: 'Posts',
            onTap: onTapPosts,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 24,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required int count,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                shadows: const [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 2,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
