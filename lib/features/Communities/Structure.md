# 🧩 Community Feature – Social Media App (Flutter)

## 📌 Overview

This module adds a **Community** system to the Chat section of the app. Users can join interest-based communities (e.g., Cars, Fitness, Gaming) to chat, post, and engage with like-minded people.

---

## 🧐 Core Concepts

* Communities are public or private chat groups categorized by topics.
* Each community contains:

  * Title, description, category
  * Members (with roles)
  * A chat interface
  * Moderation tools
* Users can browse, search, join, or create communities.

---

## 🛠️ User Features

| Feature          | Description                                 |
| ---------------- | ------------------------------------------- |
| Community List   | Shows trending, popular, or all communities |
| Create Community | User can create a new one via a form        |
| Community Chat   | Each community has a live chat group        |
| Role Permissions | Moderators can manage members, pin posts    |
| Join/Leave       | User can join or leave a community          |

---

## 🛍️ How It Works – User Flow

### 🔹 Discover

* App shows a list of public communities grouped by category (Cars, Fitness, etc.)

### 🔹 Create Community

1. User clicks "Create Community"
2. Form fields:

   * Name
   * Description
   * Category
   * Privacy (Public/Private)
   * Icon (optional)
3. On submit:

   * Sends a request to backend
   * Backend stores new community
   * User becomes the first member and moderator

### 🔹 Inside a Community

* Chat interface opens
* Messages shown in real-time (via Firebase or sockets)
* User can send messages, see members, view pinned posts

---

## 🧱 Folder Structure

```
lib/
└── features/
    └── community/
        ├── data/
        │   ├── models/
        │   ├── datasources/
        │   └── repositories/
        │
        ├── domain/
        │   ├── entities/
        │   ├── repositories/
        │   └── usecases/
        │
        └── presentation/
            ├── cubit/
            ├── screens/
            │   ├── community_home_page.dart
            │   ├── community_chat_page.dart
            │   ├── community_details_page.dart
            │   └── create_community_page.dart
            └── widgets/
```

---

## 🧑‍💻 API / Backend Integration

### Create a Community

```http
POST /communities/
{
  "name": "Car Enthusiasts",
  "description": "All about cars and tuning",
  "category": "Cars",
  "createdBy": "user_id_xyz",
  "isPrivate": false
}
```

### Join Community

```http
POST /communities/:id/join
```

### Send Message

```http
POST /communities/:id/chat
{
  "senderId": "...",
  "text": "What's your dream car?"
}
```

---

## 💬 Flutter Code Overview

### `CreateCommunityPage`

```dart
TextEditingController nameController = TextEditingController();
TextEditingController descController = TextEditingController();
String selectedCategory = 'Cars';

ElevatedButton(
  onPressed: () {
    final newCommunity = CommunityModel(
      id: '',
      name: nameController.text,
      description: descController.text,
      category: selectedCategory,
      iconUrl: '',
      memberCount: 1,
    );

    context.read<CommunityCubit>().createCommunity(newCommunity);
  },
  child: Text('Create Community'),
);
```

### `CommunityCubit`

```dart
Future<void> createCommunity(CommunityModel community) async {
  emit(CommunityCreating());

  try {
    await communityRepository.createCommunity(community);
    emit(CommunityCreatedSuccessfully());
  } catch (e) {
    emit(CommunityError(e.toString()));
  }
}
```

---

## 🔮 Future Enhancements

* Voice chat channels
* Live events inside communities
* add live event or event that will happen in specfic time 
* Sub-channels (e.g., #drifting in Cars)
* Leaderboard / badges
* Media galleries per community

---

## 📆 Notes

* Uses Cubit for state management
* Backend can be Firebase
* All communities are cached for performance
* Secure access control using role-based rules
