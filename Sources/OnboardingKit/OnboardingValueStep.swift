//
//  OnboardingValueStep.swift
//  OnboardingKit
//
//  "Here is what you get" — the screen right BEFORE the paywall: a title, three checkmarked
//  outcomes and the standard CTA. Paywall before value is the biggest drop of the funnel
//  (30-60%, research 2026-09, finding 11); a small indie doubled subscribers by showing value
//  first (finding 13). The items can echo the user's answers ("25-minute blocks, 4 per cycle")
//  so the screen reads as a preview of THEIR result, not a feature list. Asset-free; strings
//  from the app.
//
//  Usage:
//      OnboardingValueStep(
//          title: String(localized: "onboarding.value.title"),
//          subtitle: String(localized: "onboarding.value.subtitle"),
//          items: [
//              .init(symbol: "timer", title: String(localized: "onboarding.value.item1")),
//              .init(symbol: "chart.bar.fill", title: String(localized: "onboarding.value.item2")),
//              .init(symbol: "bell.badge.fill", title: String(localized: "onboarding.value.item3"))
//          ],
//          gradientTop: AppColors.primary,
//          gradientBottom: AppColors.primaryDeep,
//          continueText: String(localized: "action.continue"),
//          onContinue: { appState.completeOnboarding() }
//      )
//

import SwiftUI

// MARK: - OnboardingValueItem

public struct OnboardingValueItem: Identifiable, Sendable {
    public let id: String
    public let symbol: String
    public let title: String
    public let detail: String?

    /// - Parameter id: stable key for the accessibility id (`onboarding.value.item.<id>`); defaults to the index order.
    public init(symbol: String, title: String, detail: String? = nil, id: String? = nil) {
        self.id = id ?? symbol
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }
}

// MARK: - OnboardingValueStep

public struct OnboardingValueStep: View {
    // MARK: - Configuration
    private let title: String
    private let subtitle: String?
    private let items: [OnboardingValueItem]
    private let gradientTop: Color
    private let gradientBottom: Color
    private let continueText: String
    private let onContinue: () -> Void

    // MARK: - State
    @State private var showTitle = false
    @State private var visibleItems = 0
    @State private var showButton = false

    // MARK: - Init
    public init(
        title: String,
        subtitle: String? = nil,
        items: [OnboardingValueItem],
        gradientTop: Color,
        gradientBottom: Color,
        continueText: String,
        onContinue: @escaping () -> Void
    ) {
        precondition((2...4).contains(items.count), "OnboardingValueStep shows 3 outcomes (2-4)")
        self.title = title
        self.subtitle = subtitle
        self.items = items
        self.gradientTop = gradientTop
        self.gradientBottom = gradientBottom
        self.continueText = continueText
        self.onContinue = onContinue
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        header
                        itemList
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 48)
                    .padding(.bottom, 16)
                }
                OnboardingPrimaryButton(text: continueText, textColor: gradientBottom, isEnabled: true, action: handleContinue)
                    .opacity(showButton ? 1 : 0)
                    .offset(y: showButton ? 0 : 16)
                    .accessibilityIdentifier("onboarding.value.continue")
            }
        }
        .accessibilityIdentifier("onboarding.value")
        .onAppear(perform: startEntranceAnimations)
    }

    // MARK: - Subviews
    private var background: some View {
        ZStack {
            LinearGradient(colors: [gradientTop, gradientBottom], startPoint: .topLeading, endPoint: .bottomTrailing)
            Circle().fill(Color.white.opacity(0.18))
                .frame(width: 320, height: 320).blur(radius: 90).offset(x: -120, y: -220)
            Circle().fill(gradientTop.opacity(0.5))
                .frame(width: 300, height: 300).blur(radius: 100).offset(x: 140, y: 260)
        }
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Color.white.opacity(0.18)).frame(width: 88, height: 88)
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .padding(.bottom, 8)
            Text(title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .opacity(showTitle ? 1 : 0)
        .offset(y: showTitle ? 0 : 16)
    }

    private var itemList: some View {
        VStack(spacing: 12) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                itemRow(item)
                    .opacity(index < visibleItems ? 1 : 0)
                    .offset(y: index < visibleItems ? 0 : 16)
            }
        }
    }

    private func itemRow(_ item: OnboardingValueItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(Color.white.opacity(0.18)).frame(width: 44, height: 44)
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                if let detail = item.detail {
                    Text(detail)
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.14)))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.white.opacity(0.25), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("onboarding.value.item.\(item.id)")
        .accessibilityLabel(item.title)
    }

    // MARK: - Actions
    private func handleContinue() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        onContinue()
    }

    // MARK: - Private Methods
    private func startEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.5)) { showTitle = true }
        for index in items.indices {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + 0.15 * Double(index)) {
                withAnimation(.easeOut(duration: 0.4)) { visibleItems = index + 1 }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3 + 0.15 * Double(items.count) + 0.1) {
            withAnimation(.easeOut(duration: 0.4)) { showButton = true }
        }
    }
}
