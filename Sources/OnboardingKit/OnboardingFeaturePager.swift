//
//  OnboardingFeaturePager.swift
//  OnboardingKit
//
//  GambitStudio standard onboarding (multi-step). Paged feature highlights over a vibrant
//  per-step colored gradient, with dots, optional skip, and a Continue/Next button.
//  Self-contained — no app-specific references.
//
//  Standard flow (host orchestrates): OnboardingFeaturePager → optional data step
//  (weight/height, etc.) → optional permission step (HealthKit, notifications, etc.) →
//  PaywallScaffold (PaywallKit) → mark onboarding complete. `onContinue` fires when the
//  user finishes (or skips) the feature tour; the host then advances through the remaining
//  stages and the paywall.
//
//  Personalization: a step built with `OnboardingFeatureStep(id:question:gradientTop:gradientBottom:)`
//  renders a single-choice question page (see OnboardingQuestionStep.swift); create the pager
//  with the `answers:` overload so the host owns the answers.
//
//  Usage:
//      OnboardingFeaturePager(
//          steps: [
//              .init(id: 0, icon: "figure.walk.circle.fill",
//                    gradientTop: Color(red: 0.23, green: 0.51, blue: 0.96),
//                    gradientBottom: Color(red: 0.12, green: 0.11, blue: 0.29),
//                    title: "…", subtitle: "…"),
//              .init(id: 1, icon: "chart.bar.xaxis",
//                    gradientTop: Color(red: 0.06, green: 0.72, blue: 0.51),
//                    gradientBottom: Color(red: 0.02, green: 0.31, blue: 0.23),
//                    title: "…", subtitle: "…")
//          ],
//          nextText: "Next",
//          continueText: "Continue",
//          skipText: "Skip",
//          onContinue: { stage = .personalInfo }
//      )
//

import SwiftUI

// MARK: - OnboardingFeatureStep

public struct OnboardingFeatureStep: Identifiable, Sendable {
    public let id: Int
    public let icon: String
    /// Optional asset-catalog image name (from the host app's main bundle).
    /// When set, the pager shows this illustration instead of the SF Symbol bubble.
    public let heroImage: String?
    public let gradientTop: Color
    public let gradientBottom: Color
    public let title: String
    public let subtitle: String
    /// When set, the page is a personalization question instead of a feature highlight.
    /// Its answer lives in the pager's `answers` binding, keyed by `question.id`.
    public let question: OnboardingQuestion?

    public init(id: Int, icon: String, gradientTop: Color, gradientBottom: Color, title: String, subtitle: String, heroImage: String? = nil) {
        self.id = id
        self.icon = icon
        self.heroImage = heroImage
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.title = title
        self.subtitle = subtitle
        self.question = nil
    }

    /// A question page. Requires the pager to be created with an `answers:` binding.
    public init(id: Int, question: OnboardingQuestion, gradientTop: Color, gradientBottom: Color) {
        self.id = id
        self.icon = ""
        self.heroImage = nil
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.title = question.title
        self.subtitle = question.subtitle ?? ""
        self.question = question
    }
}

// MARK: - OnboardingFeaturePager

public struct OnboardingFeaturePager: View {
    // MARK: - Configuration
    private let steps: [OnboardingFeatureStep]
    private let nextText: String
    private let continueText: String
    private let skipText: String?
    private let questionSkipText: String?
    private let onStepShown: ((Int) -> Void)?
    private let onQuestionAnswered: ((OnboardingQuestion, OnboardingQuestionOption) -> Void)?
    private let onContinue: () -> Void

    // MARK: - State
    @State private var step = 0
    @State private var iconBounce = false
    /// Answers of question pages, keyed by `OnboardingQuestion.id` (host-owned).
    @Binding private var answers: [String: String]
    @State private var skippedQuestionIDs: Set<String> = []
    @State private var isRevertingStep = false

    // MARK: - Init
    public init(
        steps: [OnboardingFeatureStep],
        nextText: String,
        continueText: String,
        skipText: String? = nil,
        onStepShown: ((Int) -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.steps = steps
        self.nextText = nextText
        self.continueText = continueText
        self.skipText = skipText
        self.questionSkipText = nil
        self.onStepShown = onStepShown
        self.onQuestionAnswered = nil
        self.onContinue = onContinue
        self._answers = .constant([:])
    }

    /// Pager with personalization question pages (`OnboardingFeatureStep(id:question:...)`).
    /// `answers` is keyed by `OnboardingQuestion.id` and holds the chosen `OnboardingQuestionOption.id`;
    /// the Continue button stays disabled on a question page until it has an answer, and a
    /// forward swipe past an unanswered question snaps back. `questionSkipText` (hidden by
    /// default) adds a per-question skip below the options.
    public init(
        steps: [OnboardingFeatureStep],
        answers: Binding<[String: String]>,
        nextText: String,
        continueText: String,
        skipText: String? = nil,
        questionSkipText: String? = nil,
        onStepShown: ((Int) -> Void)? = nil,
        onQuestionAnswered: ((OnboardingQuestion, OnboardingQuestionOption) -> Void)? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.steps = steps
        self.nextText = nextText
        self.continueText = continueText
        self.skipText = skipText
        self.questionSkipText = questionSkipText
        self.onStepShown = onStepShown
        self.onQuestionAnswered = onQuestionAnswered
        self.onContinue = onContinue
        self._answers = answers
    }

    private var isLastStep: Bool { step == steps.count - 1 }
    private var current: OnboardingFeatureStep { steps[min(step, steps.count - 1)] }

    /// A feature page can always advance; a question page only once answered.
    private var canAdvance: Bool {
        guard let question = current.question else { return true }
        return answers[question.id] != nil
    }

    private func isResolved(_ question: OnboardingQuestion) -> Bool {
        answers[question.id] != nil || skippedQuestionIDs.contains(question.id)
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                skipBar
                TabView(selection: $step) {
                    ForEach(steps) { item in
                        page(item).tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: step)
                pageDots
                continueButton
            }
        }
    }

    // MARK: - Subviews
    private var background: some View {
        ZStack {
            LinearGradient(colors: [current.gradientTop, current.gradientBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320).blur(radius: 90).offset(x: -120, y: -220)
            Circle().fill(current.gradientTop.opacity(0.5))
                .frame(width: 300, height: 300).blur(radius: 100).offset(x: 140, y: 260)
        }
        .ignoresSafeArea()
        .animation(.easeInOut(duration: 0.5), value: step)
        .onAppear { onStepShown?(step + 1) }
        .onChange(of: step) { old, new in handleStepChange(from: old, to: new) }
    }

    @ViewBuilder
    private var skipBar: some View {
        if let skipText {
            HStack {
                Spacer()
                Button {
                    onContinue()
                } label: {
                    Text(skipText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                }
                .padding(.trailing, 24).padding(.top, 16)
            }
        } else {
            Color.clear.frame(height: 1)
        }
    }

    @ViewBuilder
    private func page(_ item: OnboardingFeatureStep) -> some View {
        if let question = item.question {
            questionPage(question)
        } else {
            featurePage(item)
        }
    }

    private func questionPage(_ question: OnboardingQuestion) -> some View {
        OnboardingQuestionContent(
            question: question,
            selection: answerBinding(for: question),
            style: .onGradient,
            skipText: questionSkipText,
            onSelect: { onQuestionAnswered?(question, $0) },
            onSkip: questionSkipText == nil ? nil : { skipQuestion(question) }
        )
    }

    private func answerBinding(for question: OnboardingQuestion) -> Binding<String?> {
        Binding(
            get: { answers[question.id] },
            set: { new in
                if let new { answers[question.id] = new } else { answers.removeValue(forKey: question.id) }
            }
        )
    }

    private func featurePage(_ item: OnboardingFeatureStep) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                if let heroImage = item.heroImage {
                    // maxWidth/maxHeight (not fixed) so the hero yields vertical space on
                    // short canvases (iPad compatibility mode, small iPhones) instead of
                    // squeezing the title/subtitle into truncation.
                    Image(heroImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 250, maxHeight: 250)
                        .shadow(color: .black.opacity(0.18), radius: 14, y: 8)
                        .scaleEffect(iconBounce && item.id == step ? 1.0 : 0.9)
                } else {
                    Circle().fill(.ultraThinMaterial).frame(width: 156, height: 156)
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
                    Image(systemName: item.icon)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                        .scaleEffect(iconBounce && item.id == step ? 1.0 : 0.9)
                }
            }
            VStack(spacing: 14) {
                // fixedSize(vertical) keeps the copy fully visible under vertical
                // compression — the hero shrinks instead of the text truncating.
                Text(item.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                Text(item.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 36)
            }
            Spacer(); Spacer()
        }
        .padding(.horizontal, 24)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { iconBounce = true }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index == step ? Color.white : Color.white.opacity(0.4))
                    .frame(width: index == step ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: step)
            }
        }
        .padding(.bottom, 24)
    }

    private var continueButton: some View {
        Button(action: advance) {
            Text(isLastStep ? continueText : nextText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(current.gradientBottom)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 16).fill(OnboardingCTAFill.gradient(.white)))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }
        .disabled(!canAdvance)
        .opacity(canAdvance ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.2), value: canAdvance)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }

    // MARK: - Actions
    private func advance() {
        if isLastStep {
            onContinue()
        } else {
            iconBounce = false
            withAnimation(.easeInOut) { step += 1 }
        }
    }

    private func skipQuestion(_ question: OnboardingQuestion) {
        skippedQuestionIDs.insert(question.id)
        advance()
    }

    /// Logs the step view, except when the change is a forward swipe past an
    /// unanswered question — that one is reverted (and the revert itself is not logged).
    private func handleStepChange(from old: Int, to new: Int) {
        if isRevertingStep {
            isRevertingStep = false
            return
        }
        if new > old, let question = steps[safe: old]?.question, !isResolved(question) {
            isRevertingStep = true
            withAnimation(.easeInOut) { step = old }
            return
        }
        onStepShown?(new + 1)
    }
}
