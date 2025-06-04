# Talkify App

Talkify is a social media app that incorporates chat functionality, user profiles, posts, and a comprehensive news section.

## Features

### News Section
- **Global News**: Access news from around the world
- **Egyptian News Sources**: Browse and read news from popular Egyptian publishers
- **Breaking News**: Stay updated with the most recent news
- **Categorized News**: Browse news by categories including:
  - Business
  - Sports
  - Technology
  - Culture
  - Health
  - Politics

### Chat Features
- Real-time messaging
- Profile viewing
- Media sharing

### Social Media Features
- Create and share posts
- Follow other users
- View user profiles
- Like and comment on posts

### Account Management
- Edit profile information
- Change profile picture
- Account deletion

## Egyptian News Sources
The app now includes a dedicated tab for Egyptian news sources powered by the NewsData.io API. Users can:
- Browse available Egyptian news publishers
- Select specific publishers to view their articles
- Stay updated with local Egyptian news
- Access content in both Arabic and English

## Theme Support
- Light mode
- Dark mode with proper theming across all screens

## Getting Started

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Launch the app with `flutter run`

## API Integration
- News data is fetched from:
  - NewsAPI.org
  - NewsData.io (for Egyptian news sources)

## Dependencies
- Flutter Bloc for state management
- Cached Network Image for efficient image loading
- Firebase for backend services
- Lottie for animations
