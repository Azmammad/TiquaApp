# Tiqua

Tiqua is a location-based social media app for iOS built with SwiftUI and Firebase. Users can share travel moments, discover new places through an interactive map, and connect with other travelers.

## Features

- **Authentication** — Email registration & login with email verification, password reset
- **Create Posts** — Share photos with captions, location tagging (city & country), and geo-coordinates
- **Home Feed** — Discover posts from the community with a carousel-style layout
- **Interactive Map** — Explore posts on a map view pinned to their real-world locations
- **User Profiles** — Customizable profiles with bio, profile photo, and post grid
- **Follow System** — Follow/unfollow users, view followers and following lists
- **Post Interactions** — Like, comment, and save posts
- **Activity Feed** — Real-time notifications for likes, comments, and follows
- **Saved Posts** — Bookmark posts to revisit later
- **User Search** — Find and discover other users
- **Dark Mode** — Full dark mode support with user preference persistence
- **Onboarding** — Welcome flow for first-time users

## Tech Stack

| Layer | Technology |
|-------|-----------|
| UI Framework | SwiftUI |
| Backend | Firebase (Auth, Firestore, Storage) |
| Architecture | MVVM |
| Minimum Target | iOS 17+ |
| Language | Swift |
| Package Manager | Swift Package Manager |

## Dependencies

- Firebase 12.9.0 (Auth, Firestore, Storage)
- AppCheck 11.2.0
- GoogleAdsOnDeviceConversion 3.2.0
- GoogleAppMeasurement 12.8.0

## Project Structure

```
Tiqua/
├── App/
│   ├── ContentView.swift
│   └── TiquaApp.swift
├── Components/
│   ├── CustomTextField.swift
│   └── PrimaryButton.swift
├── Core/
│   ├── Errors/
│   │   └── AuthError.swift
│   ├── Models/
│   │   ├── ActivityItem.swift
│   │   ├── Comment.swift
│   │   ├── Feedback.swift
│   │   ├── Post.swift
│   │   └── User.swift
│   ├── Navigation/
│   │   ├── AppRoute.swift
│   │   └── AppRouter.swift
│   └── Preferences/
│       └── AppPreferences.swift
├── Screens/
│   ├── Activity/
│   ├── Auth/
│   ├── Create/
│   ├── Home/
│   ├── MainTab/
│   ├── Map/
│   ├── Onboarding/
│   ├── PostDetail/
│   ├── Profile/
│   ├── Saved/
│   └── Settings/
├── Services/
│   ├── Protocols/
│   │   ├── AuthServiceProtocol.swift
│   │   ├── PostInteractionServiceProtocol.swift
│   │   ├── PostServiceProtocol.swift
│   │   ├── ProfileServiceProtocol.swift
│   │   └── UserSearchServiceProtocol.swift
│   ├── FirebaseActivityService.swift
│   ├── FirebaseAuthService.swift
│   ├── FirebasePostInteractionService.swift
│   ├── FirebasePostService.swift
│   ├── FirebaseUserSearchService.swift
│   ├── LocationManager.swift
│   └── ProfileService.swift
├── SupportingFiles/
│   └── GoogleService-Info.plist
├── Utilities/
│   └── AuthValidation.swift
└── Assets/
```

## Architecture

Tiqua follows the **MVVM (Model-View-ViewModel)** pattern with a protocol-oriented service layer:

- **Models** — Data structures (`User`, `Post`, `Comment`, `ActivityItem`, `Feedback`)
- **Views** — SwiftUI views for each screen
- **ViewModels** — Business logic and state management per screen
- **Services** — Firebase-backed services conforming to protocols for testability
- **Navigation** — Centralized routing via `AppRouter` and `AppRoute`

## Getting Started

### Prerequisites

- Xcode 16+
- iOS 17+ deployment target
- Firebase project with Auth, Firestore, and Storage enabled
- `GoogleService-Info.plist` in the project

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Azmammad/TiquaApp.git
   ```
2. Open `Tiqua.xcodeproj` in Xcode
3. Resolve Swift Package dependencies (Xcode will do this automatically)
4. Add your own `GoogleService-Info.plist` from Firebase Console
5. Build and run on a simulator or device

## License

This project is proprietary. All rights reserved.

## Author

**Əzi Cəbrayılov** — [@Azmammad](https://github.com/Azmammad)
