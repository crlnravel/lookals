# Lookals Guide

This guide summarizes the current project structure and the responsibility of each folder in the Lookals app.

## App Overview

Lookals is a SwiftUI app that shows a login screen, then displays lookalike match results. Match data flows through a layered architecture:

1. `ContentView` shows `LoginView` first.
2. Tapping `Get Started` or `Sign In` switches to `HomeView`.
3. `HomeView` owns a `HomeViewModel`.
4. `HomeViewModel` asks a `LookalMatchRepository` for matches.
5. `DefaultLookalMatchRepository` reads cached matches from SwiftData, or refreshes from a matching service.
6. Matching services return local mock data or remote API results.
7. SwiftData persists matches through `LookalMatchRecord`.

The app currently starts with `AppDependencies.preview`, so it uses mock match data and an in-memory SwiftData store by default.

## Config

`Config/Signing.xcconfig` stores shared signing configuration.

- `LOOKALS_DEVELOPMENT_TEAM` is intentionally blank for local configuration.
- `LOOKALS_BUNDLE_IDENTIFIER` is set to `appledev.Lookals`.
- `Signing.local.xcconfig` can be included as a local override without changing shared settings.

## Dependencies

`Lookals/Dependencies` contains dependency composition for the app.

- `AppDependencies` is the app-level dependency container.
- It currently exposes `lookalMatchRepository`.
- `preview` and `mock(matches:)` build a mock service plus an in-memory SwiftData store.
- `live(baseURL:)` builds a `URLSessionAPIClient`, remote matching service, persistent SwiftData store, and repository.
- `makeModelContainer(isStoredInMemoryOnly:)` creates the SwiftData `ModelContainer` for `LookalMatchRecord`.

## Models

`Lookals/Models` contains app domain models.

- `LookalMatch` represents one match result.
- Fields: `id`, `name`, `resemblanceScore`, and `category`.
- It conforms to `Codable`, `Identifiable`, `Equatable`, and `Sendable`.
- `sampleMatches` provides preview and mock data.

## Networking

`Lookals/Networking` contains generic API transport primitives.

- `APIClient` defines a generic async `send(_:)` function for typed API endpoints.
- `APIEndpoint<Response>` describes a request path, HTTP method, query items, headers, and optional body.
- `HTTPMethod` defines supported methods: `GET`, `POST`, `PUT`, and `DELETE`.
- `APIError` defines common network errors: invalid URL, invalid response, server status failure, and decoding failure.
- `URLSessionAPIClient` builds `URLRequest` values from endpoints, performs requests with `URLSession`, validates `2xx` responses, and decodes JSON.
- `MockAPIClient` returns configured `[LookalMatch]` data for tests or previews that need an `APIClient` implementation.

## Persistence

`Lookals/Persistence` contains SwiftData storage for match results.

- `LookalMatchStoring` defines async storage operations: fetch, save, and remove all matches.
- `LookalMatchRecord` is the SwiftData `@Model` persistence representation of `LookalMatch`.
- `LookalMatchRecord` can be initialized from a domain `LookalMatch` and converted back through `lookalMatch`.
- `SwiftDataLookalMatchStore` is a `@ModelActor` that implements `LookalMatchStoring`.
- Fetching sorts matches by `resemblanceScore` descending.
- Saving replaces all existing records with the new match list.

## Repositories

`Lookals/Repositories` coordinates between services and persistence.

- `LookalMatchRepository` defines `fetchMatches(refresh:)`.
- `DefaultLookalMatchRepository` first reads cached matches from `LookalMatchStoring`.
- If `refresh` is false and cached matches exist, cached data is returned.
- If refresh is requested or the cache is empty, it fetches from `LookalMatchingServicing`, saves the result, and returns fresh matches.

## Services

`Lookals/Services` contains match-fetching use cases.

- `LookalMatchingServicing` defines `fetchMatches()`.
- `MockLookalMatchingService` returns configured local matches, defaulting to `LookalMatch.sampleMatches`.
- `RemoteLookalMatchingService` uses an `APIClient` to request `APIEndpoint<[LookalMatch]>(path: "matches")`.

## ViewModels

`Lookals/ViewModels` contains UI state and presentation logic.

- `HomeViewModel` is `@MainActor` and `@Observable`.
- It stores `matches` and a `LoadingState` of `idle`, `loading`, `loaded`, or `failed(String)`.
- `topMatch` derives the match with the highest `resemblanceScore`.
- `loadMatches(refresh:)` prevents duplicate loading, asks the repository for data, and updates state for success or failure.

## Views

`Lookals/Views` contains reusable SwiftUI screens and visual components.

- `LoginView` is the initial screen. It displays a full-screen rotating image background, a `Get Started` button, and a `Sign In` action.
- `LoginView` respects `accessibilityReduceMotion` when rotating images.
- `LoginBackgroundView` renders the background image stack and dark gradient overlay.
- `HomeView` displays matches in a `NavigationStack` and `List`.
- `HomeView` shows a top-match section, a full matches section, a loading overlay, and pull-to-refresh.

## Root App Files

`Lookals/ContentView.swift` and `Lookals/LookalsApp.swift` define app entry and top-level navigation.

- `LookalsApp` is the `@main` entry point.
- It currently creates `AppDependencies.preview` and injects it into `ContentView`.
- `ContentView` toggles between `LoginView` and `HomeView` using `isShowingHome`.
- Both login actions currently call the same `showHome()` method.

## Assets

`Lookals/Assets.xcassets` stores visual assets used by the app.

- `LoginView` expects assets named `Login Image 1` and `Login Image 2`.
- Standard asset catalog contents such as app icons, colors, and images live here.

## Products

`Products/Lookals.app` is the built app product shown by Xcode. It is generated by the build system and is not source code.

## Current Data Modes

- Preview/mock mode: `AppDependencies.preview` or `AppDependencies.mock(matches:)` uses `MockLookalMatchingService` and in-memory SwiftData.
- Live mode: `AppDependencies.live(baseURL:)` uses `URLSessionAPIClient`, `RemoteLookalMatchingService`, and persistent SwiftData.
- The running app currently uses preview/mock mode because `LookalsApp` initializes `AppDependencies.preview`.
