//
//  OnboardingCommitmentStep.swift
//  OnboardingKit
//
//  Optional single-tap commitment: "I want to <goal>". A stated intention right before the
//  value step / paywall raises follow-through (Superwall's "soft commitment" pattern, research
//  2026-09, finding 6); it is a one-button screen, never a form. The statement can be built
//  from the user's answers ("I want to focus 2 hours a day"). Asset-free; strings from the app.
//
//  Usage:
//      OnboardingCommitmentStep(
//          title: String(localized: "onboarding.commitment.title"),
//          statement: String(localized: "onboarding.commitment.statement \(minutes)"),
//          gradientTop: AppColors.primary,
//          gradientBottom: AppColors.primaryDeep,
//          commitText: String(localized: "onboarding.commitment.commit"),
//          skipText: String(localized: "onboarding.commitment.skip"),
//          onCommit: { stage = .value },
//          onSkip: { stage = .value }
//      )
//

import SwiftUI

// MARK: - OnboardingCommitmentStep

public struct OnboardingCommitmentStep: View {
    // MARK: - Configuration
    private let title: String
    private let statement: String
    private let symbol: String
    private let gradientTop: Color
    private let gradientBottom: Color
    private let commitText: String
    private let skipText: String?
    private let onCommit: () -> Void
    private let onSkip: (() -> Void)?

    // MARK: - State
    @State private var isCommitted = false
    @State private var showContent = false

    // MARK: - Init
    /// - Parameters:
    ///   - statement: the commitment in first person ("I want to focus 2 hours a day").
    ///   - commitText: the one button ("I'm in"). Tapping it animates the check, then calls `onCommit`.
    ///   - skipText/onSkip: optional quiet way out; omit both to hide it.
    public init(
        title: String,
        statement: String,
        symbol: String = "hand.raised.fill",
        gradientTop: Color,
        gradientBottom: Color,
        commitText: String,
        skipText: String? = nil,
        onCommit: @escaping () -> Void,
        onSkip: (() -> Void)? = nil
    ) {
        self.title = title
        self.statement = statement
        self.symbol = symbol
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.commitText = commitText
        self.skipText = skipText
        self.onCommit = onCommit
        self.onSkip = onSkip
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                Spacer(minLength: 24)
                hero
                Text(title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 28)
                statementCard
                    .padding(.top, 20)
                Spacer(minLength: 24)
                buttons
            }
            .padding(.horizontal, 24)
            .opacity(showContent ? 1 : 0)
            .offset(y: showContent ? 0 : 16)
        }
        .accessibilityIdentifier("onboarding.commitment")
        .onAppear { withAnimation(.easeOut(duration: 0.5)) { showContent = true } }
    }

    // MARK: - Subviews
    private var hero: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.18)).frame(width: 110, height: 110)
            Image(systemName: isCommitted ? "checkmark.circle.fill" : symbol)
                .font(.system(size: 48, weight: .semibold))
                .foregroundStyle(.white)
                .contentTransition(.symbolEffect(.replace))
        }
        .scaleEffect(isCommitted ? 1.08 : 1)
    }

    private var statementCard: some View {
        Text("\u{201C}\(statement)\u{201D}")
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 20).fill(Color.white.opacity(isCommitted ? 0.26 : 0.14)))
            .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.white.opacity(isCommitted ? 0.9 : 0.25), lineWidth: isCommitted ? 2 : 1))
            .accessibilityIdentifier("onboarding.commitment.statement")
    }

    private var buttons: some View {
        VStack(spacing: 4) {
            OnboardingPrimaryButton(text: commitText, textColor: gradientBottom, isEnabled: !isCommitted, action: handleCommit)
                .accessibilityIdentifier("onboarding.commitment.commit")
                .padding(.bottom, skipText == nil ? 0 : -24)
            if let skipText, let onSkip {
                Button(action: onSkip) {
                    Text(skipText)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("onboarding.commitment.skip")
                .accessibilityLabel(skipText)
                .padding(.bottom, 24)
            }
        }
    }

    // MARK: - Actions
    /// The check plays for ~0.6 s before the host moves on, so the commitment is SEEN.
    private func handleCommit() {
        guard !isCommitted else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) { isCommitted = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onCommit() }
    }
}
