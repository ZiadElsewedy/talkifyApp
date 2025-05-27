# Auth Module Architecture

## Folder Structure
```
lib/features/auth/
│
├── data/
│   └── FireBase_Auth_repo.dart      # Implementation of the AuthRepo interface using Firebase
│
├── domain/
│   ├── entities/
│   │   └── AppUser.dart             # User data model
│   └── repo/
│       └── authrepo.dart            # Abstract interface defining auth operations
│
└── Presentation/
    ├── Cubits/
    │   ├── auth_cubit.dart          # State management for auth features
    │   └── AuthStates.dart          # Auth states definitions
    └── screens/
        ├── components/              # Reusable UI components for auth screens
        ├── Auth_screens/            # Authentication screens (login, register, etc.)
        └── About/                   # About screens related to authentication
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
│                      │           │    Auth Cubit      │
│     Auth States      │◄──────────┤  (State Manager)   │
│                      │           │                    │
└──────────────────────┘           └─────────┬──────────┘
                                              │
                                              ▼
                                  ┌────────────────────────┐
                                  │      Auth Repo         │
                                  │  (Domain Interface)    │
                                  └────────────┬───────────┘
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │ Firebase Auth Repo     │
                                  │ (Data Implementation)  │
                                  └────────────┬───────────┘
                                               │
                                               ▼
                                  ┌────────────────────────┐
                                  │    Firebase Services   │
                                  │ (Auth & Firestore DB)  │
                                  └────────────────────────┘
```

## Clean Architecture Layers

### 1. Domain Layer
Contains business logic and interfaces:
- **Entities**: Core business models like `AppUser`
- **Repository Interfaces**: Defines the contract for data operations (`authrepo.dart`)

### 2. Data Layer
Implements the repository interfaces:
- **FireBase_Auth_repo.dart**: Concrete implementation of the AuthRepo interface
- Handles Firebase Authentication and Firestore database operations

### 3. Presentation Layer
Manages UI and state:
- **Cubits**: State management using BLoC pattern
  - `auth_cubit.dart`: Handles auth logic and emits states
  - `AuthStates.dart`: Defines possible auth states
- **Screens**: UI components that interact with the Cubit

## Authentication Flow

1. **User Registration Process**:
   - User inputs registration details in the UI
   - Auth Cubit calls registerWithEmailPassword on the AuthRepo
   - Firebase Auth Repo creates a user in Firebase Auth
   - User data is saved to Firestore
   - Verification email is sent to the user

2. **User Login Process**:
   - User inputs login credentials
   - Auth Cubit calls loginWithEmailPassword on the AuthRepo
   - Firebase Auth Repo authenticates with Firebase
   - If successful, user data is retrieved from Firestore
   - Auth Cubit emits Authenticated or UnverifiedState

3. **Email Verification**:
   - User clicks verification link in email
   - App checks verification status using checkEmailVerification
   - If verified, user status is updated in Firestore
   - Auth Cubit emits EmailVerifiedState and Authenticated

4. **Session Management**:
   - App calls checkAuth on startup
   - Auth Cubit retrieves current user from Firebase
   - Online status is updated in Firestore
   - Appropriate auth state is emitted based on user status

5. **Logout Process**:
   - User triggers logout
   - Auth Cubit calls logout on the AuthRepo
   - Firebase Auth Repo updates online status and signs out
   - Auth Cubit emits UnAuthenticated state 