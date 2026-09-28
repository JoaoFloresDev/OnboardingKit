//
//  OnboardingProgressBar.swift
//  OnboardingKit
//
//  Thin progress bar for the top of an onboarding flow: N segments, the first `current` filled.
//  Users who can see the end of a 5-6 step flow complete it more often than users guessing
//  (research 2026-09, finding 11: 3-5 steps with visible value complete 60-80%). Asset-free;
//  the host overlays it on every stage (feature pager, questions, value step) and keeps
//  `current` in sync with its own stage enum.
//
//  Usage:
//      ZStack(alignment: .top) {
//          stageView
//          OnboardingProgressBar(current: stageIndex, total: 6)
//      }
//

import SwiftUI

// MARK: - OnboardingProgressBar

public struct OnboardingProgressBar: View {
    // MARK: - Configuration
    private let current: Int
    private let total: Int
    private let tint: Color
    private let track: Color
    private let height: CGFloat

    // MARK: - Init
    /// - Parameters:
    ///   - current: steps completed or in progress, 1-based (the bar shows `current` of `total` filled).
    ///   - total: number of steps in the whole flow (include the paywall if it is the last stage).
    ///   - tint: fill of the done segments (default white — the onboarding runs on gradients).
    public init(
        current: Int,
        total: Int,
        tint: Color = .white,
        track: Color = .white.opacity(0.28),
        height: CGFloat = 4
    ) {
        self.current = current
        self.total = max(1, total)
        self.tint = tint
        self.track = track
        self.height = height
    }

    // MARK: - View Body
    public var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index < current ? tint : track)
                    .frame(height: height)
                    .animation(.easeInOut(duration: 0.3), value: current)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("onboarding.progress")
        .accessibilityLabel("Progress")
        .accessibilityValue("\(min(current, total)) of \(total)")
    }
}
