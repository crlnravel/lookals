# Lookals Agent Guide

This codebase should bias strongly toward reusable SwiftUI components instead of one-off view code.

## Core Rule

When adding or changing UI, prefer an existing shared component first. If the same visual or interaction pattern appears more than once, extract it into `Lookals/Components` rather than duplicating it in a screen.

## Buttons

- Use `PrimaryButton` for primary call-to-action buttons.
- Do not recreate the app's main CTA styling inline with raw `Button`, custom capsules, or repeated padding/background chains unless there is a clear product requirement that `PrimaryButton` cannot satisfy.
- If a new primary button variant is needed, extend `PrimaryButton` carefully instead of creating a separate competing style.

Reference:

- `Lookals/Components/PrimaryButton.swift`
- `Lookals/Views/IntroView.swift`
- `Lookals/Views/LoginView.swift`
- `Lookals/Components/QuizQuestContent.swift`

## Toolbars

- Treat toolbar actions as reusable UI patterns, not screen-specific throwaway code.
- Follow the pattern used in `Lookals/Views/IntroView.swift` for navigation-toolbar actions.
- If another screen needs the same leading/back toolbar button, extract that button into a reusable component in `Lookals/Components` instead of copying the inline `ToolbarItem` implementation.
- Reuse the same iconography, padding, glass effect, accessibility treatment, and placement unless the screen has a real reason to differ.

## Implementation Expectations

- Before writing a new button or toolbar UI, search the codebase for an existing component or pattern to reuse.
- Prefer small composable views in `Lookals/Components` over repeated styling embedded in `Lookals/Views`.
- Keep screens in `Lookals/Views` focused on composition and screen flow, not repeated control styling.
- Preserve accessibility labels and interaction behavior when extracting shared components.

## Example Source of Truth

Use `Lookals/Views/IntroView.swift` as the current reference for:

- a shared primary CTA (`PrimaryButton`)
- a toolbar-based leading navigation action
- the expected level of polish for reusable interaction elements
