# Chat Module Architecture

## Folder Structure
```
lib/features/Chat/
│
├── Data/
│   └── firebase_chat_repo.dart     # Implementation of the ChatRepo interface using Firebase
│
├── domain/
│   ├── entite/
│   │   ├── message.dart            # Message data model
│   │   └── chat_room.dart          # Chat room data model
│   └── repo/
│       └── chat_repo.dart          # Abstract interface defining chat operations
│
├── persentation/
│   ├── Cubits/
│   │   ├── chat_cubit.dart         # State management for chat features
│   │   └── chat_states.dart        # Chat states definitions
│   └── Pages/
│       └── components/             # Reusable UI components for chat screens
│
└── Utils/                          # Helper utilities for chat functionality
```

## Architecture Flow Diagram
```
                                    ┌────────────────────┐
                                    │    UI Screens      │
                                    │  (Presentation)    │
                                    └─────────┬──────────┘
                                              │
                                              ▼
┌──────────────────────┐           ┌────────────────────┐
│                      │           │    Chat Cubit      │
│     Chat States      │◄──────────┤  (State Manager)   │
│                      │           │                    │
└──────────────────────┘           └─────────┬──────────┘
                                              │
                                              ▼
                                  ┌────────────────────────┐
                                  │      Chat Repo         │
                                  │  (Domain Interface)    │
                                  └────────────┬───────────┘
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │ Firebase Chat Repo     │
                                  │ (Data Implementation)  │
                                  └────────────┬───────────┘
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │    Firebase Services   │
                                  │ (Firestore & Storage)  │
                                  └────────────────────────┘
```

## Current Chat Deletion Behavior

### Issue Identified:
The current implementation has a problem where when a user deletes a chat and then navigates to the other user's profile to start a new chat, the old chat history reappears.

**Root cause of the issue:**
1. When a user "deletes" a one-on-one chat, the app doesn't actually delete the chat data from Firestore
2. Instead, it marks the chat as "hidden" for that user by setting an entry in the `leftParticipants` map
3. When the user tries to chat with the same person again through their profile, the `findOrCreateChatRoom` function finds the existing chat room and returns it with all its history

### Current implementation:
```
In chat_repo.dart (interface):
- hideChatForUser({required String chatRoomId, required String userId})

In firebase_chat_repo.dart (implementation):
- When hideChatForUser is called, it adds the userId to leftParticipants map
- The chat is filtered out from getUserChatRooms stream based on leftParticipants

In chat_cubit.dart:
- findOrCreateChatRoom finds any existing chat room between users
- This ignores whether the chat was previously "deleted" (hidden)
```

## Solution Approach

To fix this issue, we need to modify the following:

1. **Change the behavior of `findOrCreateChatRoom` to respect deleted chats:**
   - When looking for an existing chat room, check if the current user has "deleted" it (in leftParticipants)
   - If the user has deleted it, don't return the existing chat room; create a new one instead

2. **Create a new method to handle deleted chat messages:**
   - When a user deletes a chat, add an option to delete the actual message history for that user
   - Messages will need a new field to track which users have deleted them
   - Show only messages that aren't deleted by the current user

3. **Enhance the chat deletion UI:**
   - Give users the option to "Delete for me" with or without history
   - In one-on-one chats, provide options for:
     - "Delete chat" (hide from chat list but keep history)
     - "Delete chat and messages" (hide chat and delete message history for this user)

## Implementation Steps

1. **Update the `ChatRoom` entity:**
   - Add a `deletedMessagesForUsers` field to track users who deleted message history

2. **Update the `firebase_chat_repo.dart`:**
   - Modify `findChatRoomBetweenUsers` to check `leftParticipants` map
   - Enhance `hideChatForUser` to optionally delete message history
   - Update `getChatMessages` to filter out messages deleted by the user

3. **Update the `chat_cubit.dart`:**
   - Modify `findOrCreateChatRoom` to respect deleted status
   - Add new method to handle message history deletion

4. **Update the UI components:**
   - Enhance chat deletion dialog to provide both options

## Data Structures Changes

1. **ChatRoom model:**
   ```dart
   class ChatRoom {
     // Existing fields...
     final Map<String, bool> leftParticipants; // Users who "deleted" the chat
     final Map<String, DateTime> messageHistoryDeletedAt; // When users deleted message history
   }
   ```

2. **Message model:**
   ```dart
   class Message {
     // Existing fields...
     final List<String> deletedForUsers; // Users who deleted this message
   }
   ```

## Deletion Flow Changes

1. **Delete Chat (Hide):**
   - Add user to `leftParticipants` map in ChatRoom
   - Don't display in chat list for this user
   - History remains if chat is reopened

2. **Delete Chat with History:**
   - Add user to `leftParticipants` map
   - Add user to `messageHistoryDeletedAt` map with current timestamp
   - Don't display in chat list for this user
   - When chat is reopened, only show messages after deletion timestamp

By implementing these changes, when a user deletes a chat and then reopens it from the other user's profile, they will start with a clean chat history. 