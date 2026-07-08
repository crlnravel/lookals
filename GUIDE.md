# Lookals Guide

This guide explains the purpose of each main folder in the Lookals project. Many files are currently scaffolding or placeholders, so this focuses on folder responsibilities rather than documenting every file.

## App Structure

Lookals is organized as a small SwiftUI app with separate folders for app setup, UI, view state, data models, networking, persistence, services, and repository coordination.

The current app flow is simple:

1. The app launches into a login-style screen.
2. Login actions route into the home screen.
3. The home screen displays lookalike match data.
4. Match data currently comes from mock/sample dependencies by default.

## `Config`

Contains project configuration that should not live directly in Swift source files.

Currently this folder is used for signing-related build settings, including the bundle identifier and optional local signing overrides.

## `Lookals`

Contains the application source code and assets.

This is the main app module. It includes the SwiftUI entry point, root view, screens, state objects, data models, and supporting infrastructure.

## `Lookals/Dependencies`

Defines how app dependencies are assembled.

This folder is responsible for choosing which concrete implementations the app uses, such as mock dependencies for previews/development or live dependencies for real API and persistent storage usage.

## `Lookals/Models`

Contains domain data types used across the app.

These models represent the core data the app works with, independent of the UI, network layer, or persistence layer.

## `Lookals/Networking`

Contains generic API request infrastructure.

This folder is intended for HTTP client abstractions, endpoint descriptions, request methods, and network error handling. It should stay focused on transport-level concerns, not app-specific business logic.

## `Lookals/Persistence`

Contains local storage infrastructure.

This folder is responsible for saving, loading, and deleting app data on device. In this project, it is set up around SwiftData so match results can be cached locally.

## `Lookals/Repositories`

Coordinates data access for the rest of the app.

Repositories sit between view models and lower-level services/storage. They decide whether data should come from cache, local storage, or a service refresh, keeping that decision out of the UI.

## `Lookals/Services`

Contains app-specific data-fetching behavior.

Services represent use-case-level operations, such as fetching lookalike matches. They can be backed by mock data during development or by networking in a live app.

## `Lookals/ViewModels`

Contains UI state and presentation logic.

View models prepare data for SwiftUI views, track loading/error states, and call repositories. This keeps screens focused on layout and user interaction instead of data coordination.

## `Lookals/Views`

Contains SwiftUI screens and reusable visual components.

This folder owns the visible UI, including the login screen, background visuals, and home screen. Views should remain mostly declarative and delegate data loading or state decisions to view models.

## `Lookals/Assets.xcassets`

Contains app visual assets.

This includes image assets, colors, icons, and other resources used by SwiftUI views.

## `Products`

Contains build products shown by Xcode.

This is generated output, such as the built `.app`, and is not source code that should normally be edited directly.

## Current Implementation Notes

- The project currently uses mock/sample data by default.
- Several layers are already separated even where the implementation is still minimal.
- The folder structure is prepared for growth into a live app with networking, caching, and SwiftUI presentation kept separate.
