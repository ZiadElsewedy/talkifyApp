import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Profile/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';

class ProfilePicFunction extends StatelessWidget {
  final ProfileStates state;
  final String? profilePictureUrl;

  const ProfilePicFunction({
    Key? key,
    required this.state,
    this.profilePictureUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (state is ProfileLoadedState) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: profilePictureUrl?.isNotEmpty == true
              ? Image.network(
                  profilePictureUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: WhiteCircleIndicator(
                          size: 45.0,
                          color: Colors.black,
                          backgroundColor: Colors.black.withOpacity(0.1),
                          progress: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                      ),
                    );
                  },
                )
              : Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 50,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                  ),
                ),
        ),
      );
    } else if (state is ProfileLoadingState) {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: WhiteCircleIndicator(
            size: 45.0,
            color: Colors.black,
            backgroundColor: Colors.black.withOpacity(0.1),
          ),
        ),
      );
    } else {
      return Container(
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          Icons.person,
          size: 50,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      );
    }
  }
} 