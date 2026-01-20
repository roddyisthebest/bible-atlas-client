# BibleAtlas

BibleAtlas is an iOS application that helps users explore biblical places on an interactive map with historical and geographical context.

The app focuses on performance, testability, and maintainable architecture, built as a production-ready iOS project.

---

## Features

- Interactive map displaying biblical locations and regions
- Place search with debounced keyword handling
- Detailed place information with verses and descriptions
- Bottom sheet–based navigation optimized for map interaction
- Offline-safe UI state handling and error recovery
- Share place information via system share sheet

---

## Technical Highlights

### Architecture
- Clean Architecture + MVVM
- Dependency Injection for loose coupling
- Coordinator-style navigation abstraction (Navigator)

### UI / State Management
- UIKit-based UI
- RxSwift / RxCocoa for reactive state binding
- Deterministic screen state management
- Bottom sheet detent locking and restoration logic

### Performance Optimization
- Identified and eliminated UI interaction delays
- Reduced screen transition latency by restructuring navigation flow
- Optimized heavy map rendering paths

### Testing
- Unit tests for ViewModels and core business logic
- Smoke tests for critical user flows
- High test coverage enabled by architecture-driven design

### CI / CD
- GitHub Actions for pull request validation
- Fastlane-based smoke testing pipeline
- Automated TestFlight distribution

---

## Tech Stack

- **Language**: Swift
- **UI**: UIKit
- **Reactive**: RxSwift, RxCocoa
- **Architecture**: Clean Architecture, MVVM
- **Testing**: XCTest, RxTest
- **CI/CD**: GitHub Actions, Fastlane
- **Dependency Management**: CocoaPods

---

## Project Focus

This project emphasizes:

- Writing testable and maintainable iOS code
- Designing UI flows that scale with feature growth
- Solving real performance and state management problems in map-based applications

---

## Screenshots

### Home / Map
<p float="left">
  <img src="https://github.com/user-attachments/assets/db7849b9-b72a-42df-b4ad-b280d310069a" width="45%" />
</p>

### Place Detail
<p float="left">
  <img src="https://github.com/user-attachments/assets/e47e58e7-bdfa-403b-8c3b-f089482fd49e" width="45%" />
  <img src="https://github.com/user-attachments/assets/8edec1bb-343e-4eea-a347-cbc4474b0cbf" width="45%" />
</p>

### Search Flow
<p align="left">
  <img src="https://github.com/user-attachments/assets/3de0a346-d3ad-4139-8b4b-72e362295b71" width="45%" />
  <img src="https://github.com/user-attachments/assets/b2549b1e-2877-4ef8-a2e1-5c77b5b13588" width="45%" />
</p>

---

## Author

iOS Developer  
Former Frontend Developer (2+ years experience)
