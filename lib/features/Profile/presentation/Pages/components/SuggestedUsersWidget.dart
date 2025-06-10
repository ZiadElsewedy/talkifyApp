import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Profile/domain/entites/ProfileUser.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/ProfilePage.dart';
import 'package:talkifyapp/features/Profile/presentation/Pages/components/FollowButtom.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SuggestedUsersWidget extends StatefulWidget {
  final List<ProfileUser> suggestedUsers;
  final String currentUserId;
  final bool isLoading;
  final Function(String userId, bool isFollowing) onFollowToggle;
  final VoidCallback onRefresh;

  const SuggestedUsersWidget({
    Key? key,
    required this.suggestedUsers,
    required this.currentUserId,
    this.isLoading = false,
    required this.onFollowToggle,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<SuggestedUsersWidget> createState() => _SuggestedUsersWidgetState();
}

class _SuggestedUsersWidgetState extends State<SuggestedUsersWidget> {
  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDarkMode ? Colors.grey[200]! : Colors.black87;
    final Color subTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    final Color cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color dividerColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;

    if (widget.isLoading) {
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
                  'Suggested for You',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: subTextColor),
                  onPressed: widget.onRefresh,
                  tooltip: 'Refresh suggestions',
                ),
              ],
            ),
          ),
          if (widget.suggestedUsers.isEmpty)
            // Show a message when there are no suggestions
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: subTextColor,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No suggestions found',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try following more people to get suggestions',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: subTextColor,
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: widget.onRefresh,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: Text('Refresh'),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              height: 250,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.suggestedUsers.length,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final user = widget.suggestedUsers[index];
                  return _buildSuggestedUserCard(
                    context, 
                    user,
                    textColor: textColor,
                    subTextColor: subTextColor,
                    cardColor: cardColor,
                    dividerColor: dividerColor,
                  );
                },
              ),
            ),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSuggestedUserCard(
    BuildContext context, 
    ProfileUser user, {
    required Color textColor,
    required Color subTextColor,
    required Color cardColor,
    required Color dividerColor,
  }) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 150,
      margin: EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 1),
      ),
      child: Column(
        children: [
          // Profile picture
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(userId: user.id),
              ),
            ),
            child: Container(
              width: 150,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
                child: CachedNetworkImage(
                  imageUrl: user.profilePictureUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDarkMode ? Colors.white70 : Colors.black45,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.person, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
          
          // User info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  user.HintDescription.isNotEmpty 
                      ? user.HintDescription 
                      : '@${user.name.toLowerCase().replaceAll(' ', '_')}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: subTextColor,
                  ),
                ),
                SizedBox(height: 12),
                
                // Follow button
                SizedBox(
                  width: double.infinity,
                  child: FollowButton(
                    key: ValueKey('suggestedfollow_${user.id}'),
                    currentUserId: widget.currentUserId,
                    otherUserId: user.id,
                    isFollowing: false, // Suggestions are always users not yet followed
                    isCompact: true,
                    onFollow: (isFollowing) async {
                      widget.onFollowToggle(user.id, isFollowing);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 