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

    public init(id: Int, icon: String, gradientTop: Color, gradientBottom: Color, title: String, subtitle: String, heroImage: String? = nil) {
        self.id = id
        self.icon = icon
        self.heroImage = heroImage
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.title = title
        self.subtitle = subtitle
    }
}

// MARK: - OnboardingFeaturePager

public struct OnboardingFeaturePager: View {
    // MARK: - Configuration
    private let steps: [OnboardingFeatureStep]
    private let nextText: String
    private let continueText: String
    private let skipText: String?
    private let onContinue: () -> Void

    // MARK: - State
    @State private var step = 0
    @State private var iconBounce = false

    // MARK: - Init
    public init(
        steps: [OnboardingFeatureStep],
        nextText: String,
        continueText: String,
        skipText: String? = nil,
        onContinue: @escaping () -> Void
    ) {
        self.steps = steps
        self.nextText = nextText
        self.continueText = continueText
        self.skipText = skipText
        self.onContinue = onContinue
    }

    private var isLastStep: Bool { step == steps.count - 1 }
    private var current: OnboardingFeatureStep { steps[min(step, steps.count - 1)] }

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

    private func page(_ item: OnboardingFeatureStep) -> some View {
        VStack(spacing: 28) {
            Spacer()
            ZStack {
                if let heroImage = item.heroImage {
                    Image(heroImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250, height: 250)
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
                Text(item.title)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 2)
                Text(item.subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
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
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }
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
}
