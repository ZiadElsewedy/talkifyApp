# Communities Feature

## Overview

The Communities feature allows users to join interest-based communities (e.g., Cars, Fitness, Gaming) to chat, post, and engage with like-minded people.

## Key Features

- Community browsing and discovery
- Community creation with customizable settings
- Real-time community chat
- Member management with roles (member, moderator, admin)
- Pinned messages for important information

## Architecture

The feature follows Clean Architecture principles with:

1. **Data Layer**
   - Models (CommunityModel, CommunityMessageModel, CommunityMemberModel)
   - Repository Implementation (CommunityRepositoryImpl)

2. **Domain Layer**
   - Entities (Community, CommunityMessage, CommunityMember)
   - Repository Interfaces (CommunityRepository)

3. **Presentation Layer**
   - Cubits (CommunityCubit, CommunityMemberCubit, CommunityMessageCubit)
   - States (CommunityState, CommunityMemberState, CommunityMessageState)
   - Screens and UI Components

## Design

The Communities feature uses a black and white design following the app's theme system:

- Consistent with the app's design language
- Responsive to system dark/light mode
- High contrast for accessibility
- Minimal UI with focus on content

## Integration

The Communities feature is accessible from the app's main drawer, making it easy to discover and use.

## Firebase Integration

Communities data is stored in Firebase Firestore with the following collections:

- `communities`: Stores community information
  - `members`: Subcollection for community members
  - `messages`: Subcollection for community chat messages

## Future Enhancements

- Voice chat channels
- Live events in communities
- Scheduled events with notifications
- Sub-channels for specific topics
- Community leaderboards and badges
- Media galleries for communities 