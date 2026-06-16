//
//  CinematicOnboardingComponents.swift
//  OnboardingKit
//
//  Asset-free media views for CinematicOnboardingScaffold:
//  a rotating testimonial carousel and an animated SF Symbol hero.
//
//  Adapted for GambitStudio from CinematicOnboardingView-SwiftUI by Adam Lyttle
//  (https://github.com/adamlyttleapps/CinematicOnboardingView-SwiftUI, MIT).
//  Original avatar / laurel image assets replaced with SF Symbols so the kit
//  drops in with zero bundled resources.
//

import SwiftUI

// MARK: - Testimonial Model

public struct CinematicTestimonial: Identifiable, Sendable {
    // MARK: - Properties
    public let id: Int
    public let title: String
    public let description: String
    public let rating: Int
    public let avatarSymbol: String

    // MARK: - Init
    public init(
        id: Int,
        title: String,
        description: String = "",
        rating: Int = 5,
        avatarSymbol: String = "person.crop.circle.fill"
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.rating = rating
        self.avatarSymbol = avatarSymbol
    }
}

// MARK: - Testimonial Carousel

/// Rotating, animated testimonial card with a blur/scale/rotation entrance.
/// Use as the `media` of a `CinematicOnboardingStep` (typically the first step).
public struct CinematicTestimonialCarousel: View {
    // MARK: - Configuration
    private let accentColor: Color
    private let starColor: Color

    // MARK: - State
    @State private var testimonials: [CinematicTestimonial]
    @State private var opacity: CGFloat = 0
    @State private var hasStarted = false

    // MARK: - Init
    public init(
        testimonials: [CinematicTestimonial],
        accentColor: Color,
        starColor: Color = .yellow
    ) {
        self._testimonials = State(initialValue: testimonials)
        self.accentColor = accentColor
        self.starColor = starColor
    }

    // MARK: - View Body
    public var body: some View {
        VStack {
            if let testimonial = testimonials.first {
                card(for: testimonial)
                    .opacity(opacity)
                    .scaleEffect(opacity == 1 ? 1 : 2)
                    .blur(radius: opacity == 1 ? 0 : 20)
                    .rotationEffect(.degrees(opacity == 1 ? 0 : 30))
                    .frame(minHeight: 100)
                    .onAppear {
                        guard !hasStarted else { return }
                        hasStarted = true
                        advance()
                    }
            }
        }
        .padding(.horizontal)
        .onAppear { testimonials.shuffle() }
    }

    // MARK: - Subviews
    private func card(for testimonial: CinematicTestimonial) -> some View {
        VStack(spacing: 30) {
            HStack(alignment: .bottom) {
                Spacer()

                Image(systemName: "laurel.leading")
                    .font(.system(size: 38))
                    .foregroundStyle(accentColor)

                VStack(spacing: 9) {
                    Image(systemName: testimonial.avatarSymbol)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .foregroundStyle(accentColor)
                        .padding(.horizontal)

                    Text(testimonial.title)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .layoutPriority(100)
                        .font(.title2.italic())

                    HStack(spacing: 3) {
                        ForEach(0..<max(0, testimonial.rating), id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .foregroundStyle(starColor)
                        }
                    }
                }
                .padding()

                Image(systemName: "laurel.trailing")
                    .font(.system(size: 38))
                    .foregroundStyle(accentColor)

                Spacer()
            }

            if !testimonial.description.isEmpty {
                Text("\"\(testimonial.description)\"")
                    .multilineTextAlignment(.center)
                    .italic()
            }
        }
        .padding()
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .foregroundStyle(Color.white.opacity(0.05))
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            }
        }
    }

    // MARK: - Private Methods
    private func advance() {
        if let first = testimonials.first {
            testimonials.append(first)
            testimonials.remove(at: 0)
        }

        withAnimation { opacity = 1.0 }

        guard testimonials.count > 1 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.4) {
            withAnimation { opacity = 0.0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                advance()
            }
        }
    }
}

// MARK: - Symbol Hero

/// An animated SF Symbol hero with a pulsing glow and rotating sparkle ring.
/// A zero-asset default media view for cinematic onboarding steps.
public struct CinematicSymbolHero: View {
    // MARK: - Configuration
    private let symbol: String
    private let accentColor: Color

    // MARK: - State
    @State private var pulse = false
    @State private var rotate = false

    // MARK: - Init
    public init(symbol: String, accentColor: Color) {
        self.symbol = symbol
        self.accentColor = accentColor
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(accentColor.opacity(0.25 - Double(ring) * 0.07), lineWidth: 2)
                    .frame(width: 150 + CGFloat(ring) * 60, height: 150 + CGFloat(ring) * 60)
                    .scaleEffect(pulse ? 1.08 : 0.95)
            }

            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundStyle(accentColor)
                .offset(y: -110)
                .rotationEffect(.degrees(rotate ? 360 : 0))

            Image(systemName: symbol)
                .font(.system(size: 80, weight: .semibold))
                .foregroundStyle(accentColor)
                .scaleEffect(pulse ? 1.05 : 0.95)
        }
        .frame(height: 300)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                pulse = true
            }
            withAnimation(.linear(duration: 14).repeatForever(autoreverses: false)) {
                rotate = true
            }
        }
    }
}
