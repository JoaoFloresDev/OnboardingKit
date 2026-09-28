//
//  OnboardingQuestionStep.swift
//  OnboardingKit
//
//  Single-choice personalization question. 2-3 of these between the feature tour and
//  the permission step lift trial starts and paying users (research 2026-09, finding 3).
//  The kit renders the question; the host owns the answer (a binding, usually backed by
//  `@AppStorage`) and every string. Asset-free: SF Symbols only.
//
//  Three ways to use it:
//    1. Standalone stage (host orchestrates stages like it does with the feature pager):
//
//      OnboardingQuestionStep(
//          question: OnboardingQuestion(
//              id: "goal",
//              title: String(localized: "onboarding.goal.title"),
//              subtitle: String(localized: "onboarding.goal.subtitle"),
//              options: [
//                  .init(id: "lose", title: String(localized: "onboarding.goal.lose"), symbol: "flame.fill"),
//                  .init(id: "keep", title: String(localized: "onboarding.goal.keep"), symbol: "heart.fill"),
//                  .init(id: "gain", title: String(localized: "onboarding.goal.gain"), symbol: "figure.run")
//              ]
//          ),
//          selection: $goal,                     // @AppStorage("onboarding.goal") var goal: String?
//          gradientTop: Color(red: 0.23, green: 0.51, blue: 0.96),
//          gradientBottom: Color(red: 0.12, green: 0.11, blue: 0.29),
//          continueText: String(localized: "onboarding.continue"),
//          onContinue: { _ in stage = .permission }
//      )
//
//    2. As a page of `OnboardingFeaturePager` — `OnboardingFeatureStep(id:question:gradientTop:gradientBottom:)`
//       plus the pager's `answers:` binding.
//    3. As a step of `CinematicOnboardingScaffold` — `CinematicOnboardingStep(question:selection:...)`.
//

import SwiftUI

// MARK: - OnboardingQuestionOption

public struct OnboardingQuestionOption: Identifiable, Sendable, Hashable {
    /// Stable key the host stores (never the localized title).
    public let id: String
    public let title: String
    public let subtitle: String?
    public let symbol: String?

    public init(id: String, title: String, subtitle: String? = nil, symbol: String? = nil) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
    }
}

// MARK: - OnboardingQuestion

public struct OnboardingQuestion: Identifiable, Sendable {
    /// Stable key for storage and analytics (`step_name`), e.g. "goal", "frequency", "level".
    public let id: String
    public let title: String
    public let subtitle: String?
    public let options: [OnboardingQuestionOption]

    public init(id: String, title: String, subtitle: String? = nil, options: [OnboardingQuestionOption]) {
        precondition((2...5).contains(options.count), "OnboardingQuestion takes 2 to 5 options")
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.options = options
    }

    public func option(withID id: String?) -> OnboardingQuestionOption? {
        guard let id else { return nil }
        return options.first { $0.id == id }
    }
}

// MARK: - OnboardingQuestionOptionStyle

/// Colors of the option rows. `.onGradient` for the colored backgrounds of the pager and
/// the standalone step; `.accent(_:)` for neutral surfaces (cinematic scaffold).
public struct OnboardingQuestionOptionStyle: Sendable {
    public var textColor: Color
    public var secondaryTextColor: Color
    public var fill: Color
    public var selectedFill: Color
    public var border: Color
    public var selectedBorder: Color
    public var symbolColor: Color
    public var checkColor: Color

    public init(
        textColor: Color,
        secondaryTextColor: Color,
        fill: Color,
        selectedFill: Color,
        border: Color,
        selectedBorder: Color,
        symbolColor: Color,
        checkColor: Color
    ) {
        self.textColor = textColor
        self.secondaryTextColor = secondaryTextColor
        self.fill = fill
        self.selectedFill = selectedFill
        self.border = border
        self.selectedBorder = selectedBorder
        self.symbolColor = symbolColor
        self.checkColor = checkColor
    }

    public static let onGradient = OnboardingQuestionOptionStyle(
        textColor: .white,
        secondaryTextColor: .white.opacity(0.8),
        fill: .white.opacity(0.14),
        selectedFill: .white.opacity(0.28),
        border: .white.opacity(0.25),
        selectedBorder: .white,
        symbolColor: .white,
        checkColor: .white
    )

    public static func accent(_ accent: Color) -> OnboardingQuestionOptionStyle {
        OnboardingQuestionOptionStyle(
            textColor: .primary,
            secondaryTextColor: .secondary,
            fill: .primary.opacity(0.05),
            selectedFill: accent.opacity(0.14),
            border: .primary.opacity(0.12),
            selectedBorder: accent,
            symbolColor: accent,
            checkColor: accent
        )
    }
}

// MARK: - OnboardingQuestionOptionList

/// The selectable rows alone — use as `media` of a cinematic step or inside a custom layout.
public struct OnboardingQuestionOptionList: View {
    // MARK: - Configuration
    private let question: OnboardingQuestion
    @Binding private var selection: String?
    private let style: OnboardingQuestionOptionStyle
    private let onSelect: ((OnboardingQuestionOption) -> Void)?

    // MARK: - Init
    public init(
        question: OnboardingQuestion,
        selection: Binding<String?>,
        style: OnboardingQuestionOptionStyle = .onGradient,
        onSelect: ((OnboardingQuestionOption) -> Void)? = nil
    ) {
        self.question = question
        self._selection = selection
        self.style = style
        self.onSelect = onSelect
    }

    // MARK: - View Body
    public var body: some View {
        VStack(spacing: 10) {
            ForEach(question.options) { option in
                OnboardingQuestionOptionRow(
                    option: option,
                    isSelected: selection == option.id,
                    style: style,
                    action: { select(option) }
                )
            }
        }
    }

    // MARK: - Actions
    private func select(_ option: OnboardingQuestionOption) {
        UISelectionFeedbackGenerator().selectionChanged()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { selection = option.id }
        onSelect?(option)
    }
}

// MARK: - Option Row

private struct OnboardingQuestionOptionRow: View {
    let option: OnboardingQuestionOption
    let isSelected: Bool
    let style: OnboardingQuestionOptionStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let symbol = option.symbol {
                    ZStack {
                        Circle().fill(style.fill).frame(width: 40, height: 40)
                        Image(systemName: symbol)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(style.symbolColor)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(style.textColor)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    if let subtitle = option.subtitle {
                        Text(subtitle)
                            .font(.system(size: 14))
                            .foregroundStyle(style.secondaryTextColor)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? style.checkColor : style.border)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(isSelected ? style.selectedFill : style.fill))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? style.selectedBorder : style.border, lineWidth: isSelected ? 2 : 1)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("onboarding.question.option.\(option.id)")
        .accessibilityLabel(option.title)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Question Content (header + rows + optional skip)

/// Shared by the standalone step and the feature pager's question page.
struct OnboardingQuestionContent: View {
    // MARK: - Properties
    let question: OnboardingQuestion
    @Binding var selection: String?
    let style: OnboardingQuestionOptionStyle
    let skipText: String?
    let onSelect: ((OnboardingQuestionOption) -> Void)?
    let onSkip: (() -> Void)?

    // MARK: - View Body
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                header
                OnboardingQuestionOptionList(question: question, selection: $selection, style: style, onSelect: onSelect)
                skipButton
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Subviews
    private var header: some View {
        VStack(spacing: 12) {
            Text(question.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(style.textColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle = question.subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(style.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    @ViewBuilder
    private var skipButton: some View {
        if let skipText, let onSkip {
            Button(action: onSkip) {
                Text(skipText)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(style.secondaryTextColor)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("onboarding.question.skip")
            .accessibilityLabel(skipText)
        }
    }
}

// MARK: - OnboardingQuestionStep (standalone)

/// Full-screen question over the same gradient as a feature pager page, with the
/// standard gradient CTA. The CTA is disabled until an option is chosen.
public struct OnboardingQuestionStep: View {
    // MARK: - Configuration
    private let question: OnboardingQuestion
    @Binding private var selection: String?
    private let gradientTop: Color
    private let gradientBottom: Color
    private let continueText: String
    private let skipText: String?
    private let onSelect: ((OnboardingQuestionOption) -> Void)?
    private let onContinue: (OnboardingQuestionOption) -> Void
    private let onSkip: (() -> Void)?

    // MARK: - Init
    public init(
        question: OnboardingQuestion,
        selection: Binding<String?>,
        gradientTop: Color,
        gradientBottom: Color,
        continueText: String,
        skipText: String? = nil,
        onSelect: ((OnboardingQuestionOption) -> Void)? = nil,
        onContinue: @escaping (OnboardingQuestionOption) -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.question = question
        self._selection = selection
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.continueText = continueText
        self.skipText = skipText
        self.onSelect = onSelect
        self.onContinue = onContinue
        self.onSkip = onSkip
    }

    private var selectedOption: OnboardingQuestionOption? { question.option(withID: selection) }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                OnboardingQuestionContent(
                    question: question,
                    selection: $selection,
                    style: .onGradient,
                    skipText: skipText,
                    onSelect: onSelect,
                    onSkip: onSkip
                )
                OnboardingPrimaryButton(
                    text: continueText,
                    textColor: gradientBottom,
                    isEnabled: selectedOption != nil,
                    action: handleContinue
                )
                .accessibilityIdentifier("onboarding.question.continue")
            }
        }
    }

    // MARK: - Subviews
    private var background: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320).blur(radius: 90).offset(x: -120, y: -220)
            Circle().fill(gradientTop.opacity(0.5))
                .frame(width: 300, height: 300).blur(radius: 100).offset(x: 140, y: 260)
        }
        .ignoresSafeArea()
    }

    // MARK: - Actions
    private func handleContinue() {
        guard let selectedOption else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onContinue(selectedOption)
    }
}

// MARK: - Primary Button

/// The standard onboarding CTA (white gradient fill, brand-colored text), with a
/// disabled state for gated steps.
struct OnboardingPrimaryButton: View {
    // MARK: - Properties
    let text: String
    let textColor: Color
    let isEnabled: Bool
    let action: () -> Void

    // MARK: - View Body
    var body: some View {
        Button(action: action) {
            Text(text)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, minHeight: 44)
                .padding(.vertical, 18)
                .background(RoundedRectangle(cornerRadius: 16).fill(OnboardingCTAFill.gradient(.white)))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
                .contentShape(Rectangle())
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.55)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
        .accessibilityLabel(text)
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}
