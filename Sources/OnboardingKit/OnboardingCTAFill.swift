//
//  OnboardingCTAFill.swift
//  OnboardingKit
//

import SwiftUI

// MARK: - Onboarding CTA Fill
/// GambitStudio standard: the onboarding continue button is **never** a flat fill.
/// It always carries a soft top-lit gradient, which reads as a raised, tappable
/// surface and keeps the primary action the brightest thing on the screen.
///
/// Use `OnboardingCTAFill.gradient(base)` for any onboarding CTA. For a two-tone
/// brand fill (a light tint above the base colour) pass `top:` explicitly.
public enum OnboardingCTAFill {

    // MARK: - Public Methods

    /// Soft sheen derived from a single colour — the top stays at full strength
    /// and the bottom eases off, so it works over any backdrop.
    public static func gradient(_ base: Color) -> LinearGradient {
        LinearGradient(
            colors: [base, base.opacity(0.86)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Explicit two-tone fill, for apps that own a light/base pair in their palette.
    public static func gradient(top: Color, bottom: Color) -> LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}
