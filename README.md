# OnboardingKit

Shared GambitStudio onboarding — self-contained standard.

**Padrão atual = multi-step + paywall (`OnboardingFeaturePager`).** O host orquestra o fluxo:
`OnboardingFeaturePager` (2-3 features paginadas, gradiente colorido por step, dots, Continue)
→ step de dados opcional (peso/altura, etc.) → step de permissão opcional (HealthKit, notificações)
→ `PaywallScaffold` (PaywallKit) → marcar `hasSeenOnboarding = true`.

`onContinue` do pager dispara ao terminar/pular as features; o host avança os demais estágios.

```swift
import OnboardingKit

OnboardingFeaturePager(
    steps: [
        .init(id: 0, icon: "figure.walk.circle.fill",
              gradientTop: Color(red: 0.23, green: 0.51, blue: 0.96),
              gradientBottom: Color(red: 0.12, green: 0.11, blue: 0.29),
              title: String(localized: "onboarding.step1.title"),
              subtitle: String(localized: "onboarding.step1.subtitle")),
        .init(id: 1, icon: "chart.bar.xaxis",
              gradientTop: Color(red: 0.06, green: 0.72, blue: 0.51),
              gradientBottom: Color(red: 0.02, green: 0.31, blue: 0.23),
              title: String(localized: "onboarding.step2.title"),
              subtitle: String(localized: "onboarding.step2.subtitle"))
    ],
    nextText: String(localized: "action.next"),
    continueText: String(localized: "onboarding.continue"),
    skipText: String(localized: "onboarding.skip"),
    onContinue: { stage = .personalInfo }
)
```

> `OnboardingScaffold` (single-screen hero) continua disponível como legado/alternativa, mas o padrão GambitStudio é o multi-step acima.

---

## Legado: `OnboardingScaffold` (single-screen hero)

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

---

## Alternativa cinematográfica: `CinematicOnboardingScaffold`

Onboarding bold/animado de N steps com frame hero (header/footer), progress dots por step, transições fade+scale e carrossel de depoimentos. Asset-free por padrão (SF Symbols + gradientes da paleta), aceita imagens hero opcionais.

Adaptado de [CinematicOnboardingView-SwiftUI](https://github.com/adamlyttleapps/CinematicOnboardingView-SwiftUI) (Adam Lyttle, MIT) — generalizado pra N steps, API pública e zero assets obrigatórios.

```swift
import OnboardingKit

CinematicOnboardingScaffold(
    isPresented: $showOnboarding,
    accentColor: AppColors.primary,
    continueText: String(localized: "onboarding.continue"),
    steps: [
        CinematicOnboardingStep(
            title: String(localized: "onboarding.step1.title"),
            subtitle: String(localized: "onboarding.step1.subtitle"),
            progressSymbol: "sparkles",
            proofSymbol: "magnifyingglass",
            proofText: String(localized: "onboarding.step1.proof"),
            media: {
                CinematicTestimonialCarousel(
                    testimonials: [
                        .init(id: 1, title: "Such a good app"),
                        .init(id: 2, title: "Love it", description: "Saves me time every day")
                    ],
                    accentColor: AppColors.primary
                )
            }
        ),
        CinematicOnboardingStep(
            title: String(localized: "onboarding.step2.title"),
            subtitle: String(localized: "onboarding.step2.subtitle"),
            progressSymbol: "wand.and.stars",
            proofSymbol: "photo.fill",
            proofText: String(localized: "onboarding.step2.proof"),
            media: { CinematicSymbolHero(symbol: "wand.and.stars", accentColor: AppColors.primary) }
        )
    ],
    onFinish: { hasSeenOnboarding = true }
)
```

Componentes públicos auxiliares (usar como `media` de um step):
- `CinematicTestimonialCarousel(testimonials:accentColor:)` — depoimentos rotativos animados (laurel + estrelas, sem assets).
- `CinematicSymbolHero(symbol:accentColor:)` — SF Symbol com glow pulsante + anel de sparkles girando.

Parâmetros opcionais do scaffold: `headerImageName` / `footerImageName` (PNGs hero no Assets do app; se nil usa gradiente da `accentColor`), `preferredScheme` (default `.dark`).
