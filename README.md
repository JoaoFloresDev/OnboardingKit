# OnboardingKit

Shared GambitStudio onboarding scaffold. Single-screen hero pattern — proven converting layout (self-contained GambitStudio standard).

## Install

In your app's `Package.swift` or via Xcode SPM:

```swift
.package(path: "/Users/joaoflores/Documents/GambitStudio/_GambitStudio/packages/OnboardingKit")
```

Or relative, if the app lives under `Apps/recovery/ios/<App>/`:

```swift
.package(path: "../../../../_GambitStudio/packages/OnboardingKit")
```

Add `OnboardingKit` as dependency to your target.

## Usage

```swift
import OnboardingKit
import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        if hasSeenOnboarding {
            MainTabView()
        } else {
            OnboardingScaffold(
                gradient: [
                    Color(red: 0.38, green: 0.30, blue: 0.88),
                    Color(red: 0.28, green: 0.20, blue: 0.72),
                    Color(red: 0.18, green: 0.12, blue: 0.52)
                ],
                iconSymbol: "shield.fill",
                title: String(localized: "onboarding.title"),
                subtitle: String(localized: "onboarding.subtitle"),
                features: [
                    .init(symbol: "eye.slash.fill",
                          title: String(localized: "onboarding.feature1.title"),
                          description: String(localized: "onboarding.feature1.description")),
                    .init(symbol: "location.fill",
                          title: String(localized: "onboarding.feature2.title"),
                          description: String(localized: "onboarding.feature2.description")),
                    .init(symbol: "clock.fill",
                          title: String(localized: "onboarding.feature3.title"),
                          description: String(localized: "onboarding.feature3.description"))
                ],
                buttonText: String(localized: "onboarding.button.continue"),
                buttonTextColor: AppColors.primary,
                onContinue: { hasSeenOnboarding = true }
            )
        }
    }
}
```

## Required Localizable.xcstrings keys

Add these to your app's `Localizable.xcstrings` in PT-BR, EN-US, ES-ES (and any other locales):

- `onboarding.title`
- `onboarding.subtitle`
- `onboarding.feature1.title` / `.description`
- `onboarding.feature2.title` / `.description`
- `onboarding.feature3.title` / `.description`
- `onboarding.button.continue`

## Parameters

| Parameter | Type | Purpose |
|-----------|------|---------|
| `gradient` | `[Color]` (min 2) | Hero gradient — use 3 stops da paleta de marca do app |
| `iconSymbol` | `String` | SF Symbol central que representa o app (`shield.fill`, `drop.fill`, `creditcard.fill`...) |
| `title` | `String` | Headline principal (use `String(localized:)`) |
| `subtitle` | `String` | Subtítulo abaixo do título |
| `features` | `[OnboardingFeatureItem]` (max 4) | Lista de features (icon + title + description) |
| `buttonText` | `String` | Texto do botão "Continue" |
| `buttonTextColor` | `Color` | Cor do texto do botão (botão tem bg branco; use a primary color do app) |
| `onContinue` | `() -> Void` | Callback quando user toca em Continue (use pra `hasSeenOnboarding = true`) |
