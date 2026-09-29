//
//  GambitOnboardingPreset.swift
//  OnboardingKit
//
//  The lab's DEFAULT onboarding (João 28/09/2026): one view that runs the order of
//  spec/paywall-onboarding-template.md with the existing components — no new visual system.
//
//    2-3 outcome steps (OnboardingFeaturePager, dots hidden) → 2-3 personalization questions
//    (OnboardingQuestionStep) → value step "your X is ready" (OnboardingValueStep, built from the
//    answers) → permission primer, only if the app needs one now (OnboardingPermissionStep, one
//    button) → `onFinish`, where the host presents the paywall (GambitPaywallPreset).
//    OnboardingProgressBar on top of everything, the paywall counted as the last segment.
//
//  Why this order: value before the paywall (paywall before value drops 30-60%, OPA-11; Jigger
//  doubled subscribers showing value first, OPA-13); 2-3 questions +8,5% trial / +17% payers
//  and outcome copy +17% trial (PROD-3); paywall at the END of the onboarding = best placement
//  (onboarding + trial 1,35% install→paid vs 0,76% in-app, OPA-9; 82-90% of trials on day 0,
//  PROD-4). OPA = research-2026-09-onboarding-paywall-analytics.md, PROD = research-2026-09-product.md.
//
//  Analytics (canonical names, event-taxonomy.md): `onboarding_step_viewed(step, step_name)`,
//  `onboarding_question_answered(question, answer)`, `permission_prompted` / `permission_result`
//  (kind, granted), `onboarding_completed(steps, seconds)` — through `OnboardingAnalytics.onEvent`.
//  The paywall logs its own `paywall_shown`; the step count here already includes it.
//

import SwiftUI

// MARK: - Analytics hook

public enum OnboardingAnalytics {
    /// Wire once in `@main`: `OnboardingAnalytics.onEvent = { Analytics.log($0, $1) }`.
    nonisolated(unsafe) public static var onEvent: ((String, [String: Any]) -> Void)?

    static func log(_ name: String, _ params: [String: Any]) {
        onEvent?(name, params)
    }
}

// MARK: - Configuration types

/// The "your X is ready" step right before the paywall. `items` receives the answers
/// (`question.id → option.id`) so the screen echoes the user's choices.
public struct GambitOnboardingValue {
    public var title: String
    public var subtitle: String?
    public var items: ([String: String]) -> [OnboardingValueItem]

    public init(title: String, subtitle: String? = nil, items: @escaping ([String: String]) -> [OnboardingValueItem]) {
        self.title = title
        self.subtitle = subtitle
        self.items = items
    }
}

/// Optional permission primer (only for a permission the app uses right after onboarding).
public struct GambitOnboardingPermission {
    /// Taxonomy `kind`: notifications / camera / health / photos / family_controls.
    public var kind: String
    public var title: String
    public var subtitle: String
    public var symbol: String
    public var buttonText: String
    public var request: () async -> Bool

    public init(kind: String, title: String, subtitle: String, symbol: String = "bell.badge.fill",
                buttonText: String, request: @escaping () async -> Bool) {
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.buttonText = buttonText
        self.request = request
    }
}

// MARK: - Preset

public struct GambitOnboardingPreset: View {
    // MARK: - Stage
    private enum Stage: Equatable {
        case features
        case question(Int)
        case value
        case permission
    }

    // MARK: - Configuration
    private let features: [OnboardingFeatureStep]
    private let questions: [OnboardingQuestion]
    private let value: GambitOnboardingValue
    private let permission: GambitOnboardingPermission?
    private let gradientTop: Color
    private let gradientBottom: Color
    private let nextText: String
    private let continueText: String
    private let paywallFollows: Bool
    private let onAnswer: ((OnboardingQuestion, OnboardingQuestionOption) -> Void)?
    private let onFinish: () -> Void

    // MARK: - State
    @Binding private var answers: [String: String]
    @State private var stage: Stage = .features
    @State private var pagerStep = 1
    @State private var selection: String?
    @State private var startedAt = Date()

    // MARK: - Init
    /// - Parameters:
    ///   - features: 2-3 outcome steps ("durma melhor em 7 noites", not "alarme inteligente").
    ///   - questions: 2-3 questions whose answers the app USES (default of the home, plan, reminder).
    ///   - answers: `question.id → option.id`, host-owned (persist it in `onAnswer` / `onFinish`).
    ///   - gradientTop/Bottom: questions, value and permission background (the pager uses its steps').
    ///   - paywallFollows: the host presents the paywall in `onFinish` (counted in the progress bar).
    public init(
        features: [OnboardingFeatureStep],
        questions: [OnboardingQuestion],
        value: GambitOnboardingValue,
        permission: GambitOnboardingPermission? = nil,
        answers: Binding<[String: String]>,
        gradientTop: Color,
        gradientBottom: Color,
        nextText: String,
        continueText: String,
        paywallFollows: Bool = true,
        onAnswer: ((OnboardingQuestion, OnboardingQuestionOption) -> Void)? = nil,
        onFinish: @escaping () -> Void
    ) {
        assert((2...3).contains(features.count), "GambitOnboardingPreset: 2-3 outcome steps")
        assert((1...3).contains(questions.count), "GambitOnboardingPreset: 2-3 personalization questions")
        self.features = features
        self.questions = questions
        self.value = value
        self.permission = permission
        self._answers = answers
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.nextText = nextText
        self.continueText = continueText
        self.paywallFollows = paywallFollows
        self.onAnswer = onAnswer
        self.onFinish = onFinish
    }

    // MARK: - Computed
    /// features + questions + value + permission? + paywall?
    private var totalSteps: Int {
        features.count + questions.count + 1 + (permission == nil ? 0 : 1) + (paywallFollows ? 1 : 0)
    }

    private var progressStep: Int {
        switch stage {
        case .features: return min(pagerStep, features.count)
        case .question(let index): return features.count + index + 1
        case .value: return features.count + questions.count + 1
        case .permission: return features.count + questions.count + 2
        }
    }

    // MARK: - View Body
    public var body: some View {
        ZStack(alignment: .top) {
            stageView
            OnboardingProgressBar(current: progressStep, total: totalSteps)
        }
        .onAppear { startedAt = Date() }
    }

    @ViewBuilder
    private var stageView: some View {
        switch stage {
        case .features:
            OnboardingFeaturePager(
                steps: features,
                nextText: nextText,
                continueText: continueText,
                onStepShown: { step in
                    pagerStep = step
                    logStep(step, name: "feature_\(step)")
                },
                onContinue: { advance(from: .features) }
            )
            .pageDotsHidden()
            .transition(.opacity)
        case .question(let index):
            if let question = questions[safe: index] {
                OnboardingQuestionStep(
                    question: question,
                    selection: $selection,
                    gradientTop: gradientTop,
                    gradientBottom: gradientBottom,
                    continueText: continueText,
                    onContinue: { option in answer(question, option) }
                )
                .id(question.id)
                .transition(.opacity)
                .onAppear {
                    selection = answers[question.id]
                    logStep(features.count + index + 1, name: "question_\(question.id)")
                }
            }
        case .value:
            OnboardingValueStep(
                title: value.title,
                subtitle: value.subtitle,
                items: value.items(answers),
                gradientTop: gradientTop,
                gradientBottom: gradientBottom,
                continueText: continueText,
                onContinue: { advance(from: .value) }
            )
            .transition(.opacity)
            .onAppear { logStep(features.count + questions.count + 1, name: "preview") }
        case .permission:
            if let permission {
                OnboardingPermissionStep(
                    title: permission.title,
                    subtitle: permission.subtitle,
                    symbol: permission.symbol,
                    buttonText: permission.buttonText,
                    gradientTop: gradientTop,
                    gradientBottom: gradientBottom,
                    request: {
                        OnboardingAnalytics.log("permission_prompted", ["kind": permission.kind])
                        return await permission.request()
                    },
                    onFinished: { granted in
                        OnboardingAnalytics.log("permission_result", ["kind": permission.kind, "granted": granted])
                        finish()
                    }
                )
                .transition(.opacity)
                .onAppear {
                    logStep(features.count + questions.count + 2, name: "permission_\(permission.kind)")
                }
            }
        }
    }

    // MARK: - Flow
    private func advance(from current: Stage) {
        let next: Stage?
        switch current {
        case .features: next = questions.isEmpty ? .value : .question(0)
        case .question(let index): next = index + 1 < questions.count ? .question(index + 1) : .value
        case .value: next = permission == nil ? nil : .permission
        case .permission: next = nil
        }
        guard let next else { return finish() }
        withAnimation(.easeInOut(duration: 0.3)) { stage = next }
    }

    private func answer(_ question: OnboardingQuestion, _ option: OnboardingQuestionOption) {
        answers[question.id] = option.id
        OnboardingAnalytics.log("onboarding_question_answered", ["question": question.id, "answer": option.id])
        onAnswer?(question, option)
        UISelectionFeedbackGenerator().selectionChanged()
        if case .question(let index) = stage { advance(from: .question(index)) }
    }

    private func finish() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        OnboardingAnalytics.log("onboarding_completed", ["steps": totalSteps,
                                                         "seconds": Int(Date().timeIntervalSince(startedAt))])
        onFinish()
    }

    private func logStep(_ step: Int, name: String) {
        OnboardingAnalytics.log("onboarding_step_viewed", ["step": step, "step_name": name])
    }
}
