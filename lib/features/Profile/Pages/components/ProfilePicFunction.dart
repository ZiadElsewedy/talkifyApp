import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:talkifyapp/features/Profile/Pages/components/WhiteCircleIndicator.dart';
import 'package:talkifyapp/features/Profile/presentation/Cubits/Profile_states.dart';

class ProfilePicFunction extends StatelessWidget {
  final ProfileStates state;
  final String? profilePictureUrl;
  final PlatformFile? pickedFile;
  final Uint8List? webImage;
  final double size;
  final bool showBorder;
  final Color borderColor;
  final double borderWidth;

  const ProfilePicFunction({
    Key? key,
    required this.state,
    this.profilePictureUrl,
    this.pickedFile,
    this.webImage,
    this.size = 150.0,
    this.showBorder = false,
    this.borderColor = Colors.white,
    this.borderWidth = 1.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget buildProfileContainer({required Widget child}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: showBorder ? Border.all(
            color: borderColor,
            width: borderWidth,
          ) : null,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      );
    }

    Widget buildImage() {
      // Show picked image if available
      if (pickedFile != null) {
        return Image.file(
          File(pickedFile!.path!),
          fit: BoxFit.cover,
        );
      }
      // Show web image if available
      if (webImage != null) {
        return Image.memory(
          webImage!,
          fit: BoxFit.cover,
        );
      }
      // Show network image if available
      if (profilePictureUrl?.isNotEmpty == true) {
        return Image.network(
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
                child: PercentCircleIndicator(
                  size: size * 0.3,
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
                size: size * 0.4,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            );
          },
        );
      }
      // Show default icon if no image is available
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.person,
          size: size * 0.4,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      );
    }

    if (state is ProfileLoadedState) {
      return buildProfileContainer(
        child: ClipOval(
          child: buildImage(),
        ),
      );
    } else if (state is ProfileLoadingState) {
      return buildProfileContainer(
        child: Center(
          child: PercentCircleIndicator(
            size: size * 0.3,
            color: Colors.black,
            backgroundColor: Colors.black.withOpacity(0.1),
          ),
        ),
      );
    } else {
      return buildProfileContainer(
        child: Icon(
          Icons.person,
          size: size * 0.4,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      );
    }
  }
} 