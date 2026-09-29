# OnboardingKit

Shared GambitStudio onboarding — self-contained standard.

**Padrão atual = multi-step + paywall (`OnboardingFeaturePager`).** O host orquestra o fluxo:
`OnboardingFeaturePager` (2-3 features paginadas, gradiente colorido por step, dots, Continue) — com `OnboardingProgressBar` por cima, use `.pageDotsHidden()` (dois indicadores de progresso com contagens diferentes viram ruído)
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

## Personalização: `OnboardingQuestionStep`

Pergunta de escolha única (2-5 opções, SF Symbol opcional) entre as features e o step de permissão. Pesquisa 2026-09 (achado 3, Adapty): 2-3 perguntas de personalização = +8,5% trial / +17% pagantes. O kit renderiza; o app é dono da resposta (binding, normalmente `@AppStorage`) e de TODAS as strings. O CTA só habilita depois de escolher; "pular" existe mas fica oculto por padrão (`skipText: nil`).

Tipos públicos: `OnboardingQuestion(id:title:subtitle:options:)`, `OnboardingQuestionOption(id:title:subtitle:symbol:)`, `OnboardingQuestionOptionList` (só as linhas, pra layouts próprios), `OnboardingQuestionOptionStyle` (`.onGradient` / `.accent(_:)`). Os `id` são chaves estáveis (`"goal"`, `"lose"`) — nunca o texto localizado. Accessibility ids: `onboarding.question.option.<id>`, `onboarding.question.continue`, `onboarding.question.skip`.

**1. Como stage avulso** (host orquestra, igual ao pager):

```swift
@AppStorage("onboarding.goal") private var goal: String?

OnboardingQuestionStep(
    question: OnboardingQuestion(
        id: "goal",
        title: String(localized: "onboarding.goal.title"),
        subtitle: String(localized: "onboarding.goal.subtitle"),
        options: [
            .init(id: "lose", title: String(localized: "onboarding.goal.lose"), symbol: "flame.fill"),
            .init(id: "keep", title: String(localized: "onboarding.goal.keep"), symbol: "heart.fill"),
            .init(id: "gain", title: String(localized: "onboarding.goal.gain"), symbol: "figure.run")
        ]
    ),
    selection: $goal,
    gradientTop: Color(red: 0.23, green: 0.51, blue: 0.96),
    gradientBottom: Color(red: 0.12, green: 0.11, blue: 0.29),
    continueText: String(localized: "onboarding.continue"),
    onSelect: { Analytics.log("onboarding_question_answered", ["question": "goal", "answer": $0.id]) },
    onContinue: { _ in stage = .permission }
)
```

**2. Como página do `OnboardingFeaturePager`** — step criado com `OnboardingFeatureStep(id:question:gradientTop:gradientBottom:)` e o pager com o overload `answers:` (dicionário `question.id → option.id`). Swipe pra frente numa pergunta sem resposta volta pra ela; `questionSkipText` (opcional) adiciona um "pular" por pergunta:

```swift
@State private var answers: [String: String] = [:]   // persistir no onContinue (ex.: @AppStorage por pergunta)

OnboardingFeaturePager(
    steps: [
        .init(id: 0, icon: "figure.walk.circle.fill", gradientTop: ..., gradientBottom: ..., title: ..., subtitle: ...),
        .init(id: 1, question: goalQuestion, gradientTop: ..., gradientBottom: ...),
        .init(id: 2, question: frequencyQuestion, gradientTop: ..., gradientBottom: ...)
    ],
    answers: $answers,
    nextText: String(localized: "action.next"),
    continueText: String(localized: "onboarding.continue"),
    onStepShown: { Analytics.log("onboarding_step_viewed", ["step": $0]) },
    onQuestionAnswered: { q, opt in Analytics.log("onboarding_question_answered", ["question": q.id, "answer": opt.id]) },
    onContinue: { stage = .permission }
)
```

**3. Como step do `CinematicOnboardingScaffold`** — `CinematicOnboardingStep(question:selection:progressSymbol:proofSymbol:proofText:accentColor:)`; o Continue do scaffold fica desabilitado até escolher.

Analytics: `onboarding_question_answered` (params `question`, `answer`) é o nome proposto na pesquisa 2026-09 e **ainda não está na taxonomia canônica** (`analytics/event-taxonomy.md`) — logar pelo `onSelect`/`onQuestionAnswered` e registrar no report até a taxonomia adotar.

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

## Kits r2 (28/09/2026) — barra de progresso, valor antes do paywall, compromisso

Três views aditivas, asset-free, strings do app. O host continua orquestrando os estágios.

### `OnboardingProgressBar`
Barra fina no topo (N segmentos, `current` preenchidos). Overlay em todos os estágios — pager, perguntas, valor — com `current` sincronizado ao enum de estágio do host; conte o paywall no `total` se ele for o último estágio. Id `onboarding.progress` (accessibilityValue "3 of 6").

```swift
ZStack(alignment: .top) {
    stageView
    OnboardingProgressBar(current: stageIndex, total: 6)   // tint .white, track .white.opacity(0.28)
}
```

### `OnboardingValueStep` — "é isso que você ganha", logo ANTES do paywall
Título + 3 resultados com check + CTA padrão. Paywall antes do valor é a maior queda do funil (30-60%, pesquisa 2026-09, achado 11); os itens podem ecoar as respostas do usuário ("blocos de 25 min, 4 por ciclo"). Ids `onboarding.value`, `onboarding.value.item.<id>`, `onboarding.value.continue`.

```swift
OnboardingValueStep(
    title: String(localized: "onboarding.value.title"),
    subtitle: String(localized: "onboarding.value.subtitle"),
    items: [
        .init(symbol: "timer", title: String(localized: "onboarding.value.item1"), detail: ..., id: "blocks"),
        .init(symbol: "chart.bar.fill", title: String(localized: "onboarding.value.item2"), id: "history"),
        .init(symbol: "bell.badge.fill", title: String(localized: "onboarding.value.item3"), id: "reminders")
    ],
    gradientTop: AppColors.primary, gradientBottom: AppColors.primaryDeep,
    continueText: String(localized: "action.continue"),
    onContinue: { appState.completeOnboarding() }   // o host apresenta o paywall
)
```

### `OnboardingCommitmentStep` (opcional) — "quero <objetivo>"
Uma frase em primeira pessoa num card e UM botão ("Topo"); o check anima ~0,6 s antes de `onCommit`. `skipText`/`onSkip` opcionais. Ids `onboarding.commitment`, `.statement`, `.commit`, `.skip`.

```swift
OnboardingCommitmentStep(
    title: String(localized: "onboarding.commitment.title"),
    statement: String(localized: "onboarding.commitment.statement \(minutes)"),
    gradientTop: AppColors.primary, gradientBottom: AppColors.primaryDeep,
    commitText: String(localized: "onboarding.commitment.commit"),
    skipText: String(localized: "onboarding.commitment.skip"),
    onCommit: { stage = .value }, onSkip: { stage = .value }
)
```
