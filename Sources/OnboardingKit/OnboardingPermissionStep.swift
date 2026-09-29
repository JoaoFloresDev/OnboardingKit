//
//  OnboardingPermissionStep.swift
//  OnboardingKit
//
//  Single-button permission primer: explains WHY, then ONE neutral button that always leads to
//  the system prompt. No "Not now" — a secondary button on a primer was a 5.1.1(iv) rejection
//  (LEARNINGS #37). The button enters a loading state on tap and the step advances on every
//  outcome (granted, denied, error): the app keeps working without the permission.
//  Asked here only when the app uses the permission right away (product playbook §1: permission
//  configured inside the flow = +6,4% trial, +24% ARPU; research 2026-09-product finding 3).
//

import SwiftUI

// MARK: - OnboardingPermissionStep

public struct OnboardingPermissionStep: View {
    // MARK: - Configuration
    private let title: String
    private let subtitle: String
    private let symbol: String
    private let buttonText: String
    private let gradientTop: Color
    private let gradientBottom: Color
    private let request: () async -> Bool
    private let onFinished: (Bool) -> Void

    // MARK: - State
    @State private var isRequesting = false

    // MARK: - Init
    /// - Parameters:
    ///   - request: runs the system prompt and returns whether it was granted.
    ///   - onFinished: called with the result once the prompt is answered (any outcome).
    public init(
        title: String,
        subtitle: String,
        symbol: String = "bell.badge.fill",
        buttonText: String,
        gradientTop: Color,
        gradientBottom: Color,
        request: @escaping () async -> Bool,
        onFinished: @escaping (Bool) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbol = symbol
        self.buttonText = buttonText
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.request = request
        self.onFinished = onFinished
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.18)).frame(width: 104, height: 104)
                            Image(systemName: symbol)
                                .font(.system(size: 46, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.bottom, 8)
                        .accessibilityIdentifier("onboarding.permission")
                        Text(title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(subtitle)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 72)
                }
                ZStack {
                    OnboardingPrimaryButton(text: buttonText, textColor: gradientBottom,
                                            isEnabled: !isRequesting, action: ask)
                        .opacity(isRequesting ? 0 : 1)
                    if isRequesting {
                        ProgressView().tint(.white).padding(.bottom, 40).frame(minHeight: 44)
                    }
                }
                .accessibilityIdentifier("onboarding.permission.continue")
            }
        }
    }

    // MARK: - Actions
    private func ask() {
        guard !isRequesting else { return }
        isRequesting = true
        Task { @MainActor in
            let granted = await request()
            isRequesting = false
            onFinished(granted)
        }
    }
}
