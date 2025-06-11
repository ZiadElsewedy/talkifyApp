# Group Chat State Management Documentation

## Overview
This document describes how group chat states are managed in the Talkify app, including member management, admin privileges, and real-time synchronization.

## Key Features

### 1. **Leave Group Chat**
When a user leaves a group:
- User is removed from `participants` list
- User is removed from `participantNames` and `participantAvatars` maps
- User is removed from `unreadCount` map
- System message is sent: "{userName} left the group"
- If the leaving user is the only admin, the oldest remaining member becomes admin
- **Special Case**: If only 2 members remain and one leaves, the group is automatically deleted

### 2. **Delete Group for Everyone**
Only the group creator (first admin) can delete a group:
- System message is sent: "This group has been deleted by the admin"
- All messages and media files are deleted
- Chat room document is removed from Firestore
- All members see the group disappear from their chat list in real-time

### 3. **Real-time Updates**
All group state changes are synchronized in real-time:
- Uses Firestore's real-time listeners via `getUserChatRooms` stream
- When any member leaves or the group is deleted, all members receive updates instantly
- UI automatically reflects changes without manual refresh

### 4. **Admin Management**
- First participant (creator) is automatically admin
- Admins can edit group name and settings
- When the last admin leaves, the oldest remaining member becomes admin
- Multiple admins are supported

### 5. **Group States in UI**

#### ChatRoomTile Options:
- **Regular Members**: Can leave group, delete for themselves
- **Admins**: Can edit group, leave group, delete for themselves
- **Creator**: Can edit group, delete for everyone, leave group

#### State Flow:
1. `DeletingChatRoom` - Shows loading indicator
2. `GroupChatLeft` - Removes chat from list for leaving user
3. `ChatRoomDeleted` - Removes chat from all members when deleted

## Implementation Details

### Repository Methods:
- `leaveGroupChat()` - Handles member leaving
- `deleteChatRoom()` - Handles group deletion
- `addGroupChatAdmin()` - Adds admin privileges
- `removeGroupChatAdmin()` - Removes admin privileges

### Cubit States:
- `GroupChatLeft` - Emitted when user leaves group
- `ChatRoomDeleted` - Emitted when group is deleted
- `DeletingChatRoom` - Loading state during operations
- `ChatError` - Error handling state

### Edge Cases Handled:
1. Last member leaving - Group is automatically deleted
2. Non-existent chat room - Graceful error handling
3. User not in group - Validation prevents operations
4. Network failures - Proper error messages shown
5. Community chats - Special handling to prevent deletion

## Best Practices:
1. Always check if user is admin/creator before showing delete options
2. Use system messages to notify all members of important changes
3. Handle loading states to prevent UI glitches
4. Validate group membership before operations
5. Ensure real-time updates work for all members 