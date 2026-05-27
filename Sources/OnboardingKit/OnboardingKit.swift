//
//  OnboardingKit
//  Shared GambitStudio onboarding scaffold (AppLock single-screen hero pattern).
//
//  Usage in your app:
//      import OnboardingKit
//
//      OnboardingScaffold(
//          gradient: [.purpleLight, .purpleMid, .purpleDeep],
//          iconSymbol: "shield.fill",
//          title: String(localized: "onboarding.title"),
//          subtitle: String(localized: "onboarding.subtitle"),
//          features: [
//              .init(symbol: "eye.slash.fill",
//                    title: String(localized: "onboarding.feature1.title"),
//                    description: String(localized: "onboarding.feature1.description")),
//              .init(symbol: "location.fill",
//                    title: String(localized: "onboarding.feature2.title"),
//                    description: String(localized: "onboarding.feature2.description")),
//              .init(symbol: "clock.fill",
//                    title: String(localized: "onboarding.feature3.title"),
//                    description: String(localized: "onboarding.feature3.description"))
//          ],
//          buttonText: String(localized: "onboarding.button.continue"),
//          buttonTextColor: AppColors.primary,
//          onContinue: { hasSeenOnboarding = true }
//      )
//

import SwiftUI

// MARK: - Public Types

public struct OnboardingFeatureItem: Identifiable, Sendable {
    public let id = UUID()
    public let symbol: String
    public let title: String
    public let description: String

    public init(symbol: String, title: String, description: String) {
        self.symbol = symbol
        self.title = title
        self.description = description
    }
}

// MARK: - Scaffold

public struct OnboardingScaffold: View {
    // MARK: - Configuration
    private let gradient: [Color]
    private let iconSymbol: String
    private let title: String
    private let subtitle: String
    private let features: [OnboardingFeatureItem]
    private let buttonText: String
    private let buttonTextColor: Color
    private let onContinue: () -> Void

    // MARK: - Animation State
    @State private var showIcon = false
    @State private var showTitle = false
    @State private var visibleFeatures: Int = 0
    @State private var showButton = false
    @State private var iconPulse = false
    @State private var isButtonPressed = false

    // MARK: - Init
    public init(
        gradient: [Color],
        iconSymbol: String,
        title: String,
        subtitle: String,
        features: [OnboardingFeatureItem],
        buttonText: String,
        buttonTextColor: Color,
        onContinue: @escaping () -> Void
    ) {
        precondition(gradient.count >= 2, "OnboardingScaffold requires at least 2 gradient colors")
        precondition(features.count <= 4, "Use at most 4 features — more becomes visually heavy")
        self.gradient = gradient
        self.iconSymbol = iconSymbol
        self.title = title
        self.subtitle = subtitle
        self.features = features
        self.buttonText = buttonText
        self.buttonTextColor = buttonTextColor
        self.onContinue = onContinue
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            LinearGradient(
                colors: gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()
                iconBubble
                titleBlock
                featureList
                Spacer()
                continueButton
            }
        }
        .onAppear { startEntranceAnimations() }
    }

    // MARK: - Subviews
    private var iconBubble: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 130, height: 130)
                .scaleEffect(iconPulse ? 1.08 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: iconPulse
                )

            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 120)

            Image(systemName: iconSymbol)
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .scaleEffect(iconPulse ? 1.05 : 1.0)
                .animation(
                    .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                    value: iconPulse
                )
        }
        .opacity(showIcon ? 1 : 0)
        .offset(y: showIcon ? 0 : 20)
    }

    private var titleBlock: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.horizontal, 16)
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : 20)
    }

    private var featureList: some View {
        VStack(spacing: 24) {
            ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                OnboardingFeatureRow(item: feature)
                    .opacity(index < visibleFeatures ? 1 : 0)
                    .offset(y: index < visibleFeatures ? 0 : 20)
            }
        }
        .padding(.horizontal, 30)
    }

    private var continueButton: some View {
        Button(action: handleContinue) {
            Text(buttonText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(buttonTextColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(16)
        }
        .scaleEffect(isButtonPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isButtonPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isButtonPressed = true }
                .onEnded { _ in isButtonPressed = false }
        )
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 20)
        .padding(.horizontal, 30)
        .padding(.bottom, 40)
    }

    // MARK: - Actions
    private func handleContinue() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onContinue()
    }

    // MARK: - Private Methods
    private func startEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.6)) { showIcon = true }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.6)) { showTitle = true }
        }

        for (index, _) in features.enumerated() {
            let delay = 0.5 + (0.2 * Double(index))
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeOut(duration: 0.5)) {
                    visibleFeatures = index + 1
                }
            }
        }

        let buttonDelay = 0.5 + (0.2 * Double(features.count)) + 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
            withAnimation(.easeOut(duration: 0.5)) { showButton = true }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay + 0.2) {
            iconPulse = true
        }
    }
}

// MARK: - Feature Row

private struct OnboardingFeatureRow: View {
    let item: OnboardingFeatureItem

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: item.symbol)
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(item.description)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
    }
}
