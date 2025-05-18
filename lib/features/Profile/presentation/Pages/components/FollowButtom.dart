// this is a button that allows the user to follow or unfollow another user
import 'package:flutter/material.dart';
class FollowButton extends StatelessWidget {
  final String currentUserId;
  final String otherUserId;
  final bool isFollowing;
  final void Function(bool) onFollow;

  const FollowButton({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.isFollowing,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => onFollow(!isFollowing),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFollowing ? Colors.white : Colors.black,
        foregroundColor: isFollowing ? Colors.black : Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isFollowing ? Colors.grey.shade300 : Colors.transparent,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        minimumSize: const Size(120, 40),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFollowing ? Icons.check : Icons.add,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isFollowing ? 'Following' : 'Follow',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
