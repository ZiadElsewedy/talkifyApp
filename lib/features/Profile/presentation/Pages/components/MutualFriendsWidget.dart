import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MutualFriendsWidget extends StatelessWidget {
  final List<ProfileUser> mutualFriends;
  final bool isLoading;
  final VoidCallback? onSeeAll;

  const MutualFriendsWidget({
    Key? key,
    required this.mutualFriends,
    this.isLoading = false,
    this.onSeeAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    if (isLoading) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDarkMode ? Colors.white : Colors.black,
            ),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (mutualFriends.isEmpty) {
      return const SizedBox.shrink(); // Don't show anything if no mutual friends
    }

    return Container(
      margin: EdgeInsets.only(top: 10, bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${mutualFriends.length} Mutual Connection${mutualFriends.length > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                if (onSeeAll != null && mutualFriends.length > 3)
                  TextButton(
                    onPressed: onSeeAll,
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: isDarkMode ? Colors.blue[300] : Colors.blue[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mutualFriends.length > 5 ? 5 : mutualFriends.length,
              padding: EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final friend = mutualFriends[index];
                
                return _buildMutualFriendItem(
                  context, 
                  friend,
                  textColor: textColor,
                  subTextColor: subTextColor,
                );
              },
            ),
          ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMutualFriendItem(
    BuildContext context, 
    ProfileUser friend, {
    required Color textColor,
    required Color subTextColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(userId: friend.id),
          ),
        );
      },
      child: Container(
        width: 80,
        margin: EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Hero(
              tag: 'avatar_mutual_${friend.id}',
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: CachedNetworkImage(
                    imageUrl: friend.profilePictureUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: Icon(Icons.person, color: Colors.grey[600]),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
            Text(
              friend.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 