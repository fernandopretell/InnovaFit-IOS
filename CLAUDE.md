# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Running Tests
```bash
./run_tests.sh
```
This runs the full test suite using xcodebuild with iPhone 15 simulator.

### Manual Testing Commands
```bash
# Clean and test with specific destination
xcodebuild clean test \
  -project InnovaFit.xcodeproj \
  -scheme InnovaFit \
  -destination "platform=iOS Simulator,name=iPhone 15"
```

## Project Architecture

### Core Structure
- **SwiftUI + Firebase**: Main UI framework with Firebase backend integration
- **MVVM Pattern**: ViewModels manage business logic, Views handle presentation
- **Repository Pattern**: Data access layer (UserRepository, MachineRepository, ExerciseLogRepository)
- **SwiftData**: Local persistence for ShowFeedback entities

### Key Components

#### Authentication Flow
- `AuthViewModel`: Central authentication state management with phone number + OTP flow
- States: `.splash` → `.login` → `.otp` → `.register` → `.home`
- Firebase Auth integration for phone verification

#### Navigation Structure
- `ContentView`: Root navigation based on authentication state
- `MainTabView`: Main tab interface after authentication
- `MachineScreenContent2`: Primary machine interaction screen

#### Universal Links Support
- Handles `https://link.innovafit.pe/?tag=<tag>` format
- `AppDelegate`: Universal link processing with tag extraction
- Tag resolution through Firestore to get gymId/machineId pairs
- Auto-navigation to machine screens via tags

#### Data Models
- `Machine`, `Gym`, `Muscle`, `Video`: Core fitness entities
- `ExerciseLog`: Workout session tracking with execution dates
- `UserProfile`: User data and gym associations
- `ShowFeedback`: Local feedback entities (SwiftData)

#### Key Features
- QR code scanning for machine access
- Video tutorials with segmented playback
- Muscle group tracking and progress visualization
- Exercise logging with time-relative display
- Social sharing with generated cards
- Background removal for selfie photos

### Dependencies
- Firebase (Auth, Firestore, Analytics, Crashlytics)
- SDWebImageSwiftUI: Async image loading
- SVGKit: SVG image support
- ViewInspector: UI testing utilities (test target)

### Build Requirements
- Xcode 15+
- Swift 5.9+
- iOS 17+
- iPhone 15 simulator (default test target)