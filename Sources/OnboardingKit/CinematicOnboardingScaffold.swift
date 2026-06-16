//
//  CinematicOnboardingScaffold.swift
//  OnboardingKit
//
//  Bold, animated multi-step onboarding with hero frame, progress dots,
//  rotating testimonials and fade/scale step transitions.
//
//  Adapted for GambitStudio from CinematicOnboardingView-SwiftUI by Adam Lyttle
//  (https://github.com/adamlyttleapps/CinematicOnboardingView-SwiftUI, MIT).
//  Generalized to N steps, asset-free defaults (SF Symbols / gradients),
//  and a fully parameterized public API.
//
//  Usage in your app:
//
//      CinematicOnboardingScaffold(
//          isPresented: $showOnboarding,
//          accentColor: AppColors.primary,
//          continueText: String(localized: "onboarding.continue"),
//          steps: [
//              CinematicOnboardingStep(
//                  title: String(localized: "onboarding.step1.title"),
//                  subtitle: String(localized: "onboarding.step1.subtitle"),
//                  progressSymbol: "sparkles",
//                  proofSymbol: "magnifyingglass",
//                  proofText: String(localized: "onboarding.step1.proof"),
//                  media: { CinematicTestimonialCarousel(
//                      testimonials: [.init(id: 1, title: "Such a good app")],
//                      accentColor: AppColors.primary) }
//              ),
//              CinematicOnboardingStep(
//                  title: String(localized: "onboarding.step2.title"),
//                  subtitle: String(localized: "onboarding.step2.subtitle"),
//                  progressSymbol: "camera.fill",
//                  proofSymbol: "photo.fill",
//                  proofText: String(localized: "onboarding.step2.proof"),
//                  media: { CinematicSymbolHero(symbol: "wand.and.stars",
//                                               accentColor: AppColors.primary) }
//              )
//          ],
//          onFinish: { hasSeenOnboarding = true }
//      )
//

import SwiftUI

// MARK: - Public Types

/// A single cinematic onboarding step: a headline + subtitle, a custom media view
/// (animation / illustration / testimonial carousel) and a social-proof caption.
public struct CinematicOnboardingStep: Identifiable {
    // MARK: - Properties
    public let id = UUID()
    public let title: String
    public let subtitle: String
    public let progressSymbol: String
    public let proofSymbol: String
    public let proofText: String
    public let media: AnyView

    // MARK: - Init
    public init<Media: View>(
        title: String,
        subtitle: String,
        progressSymbol: String,
        proofSymbol: String,
        proofText: String,
        @ViewBuilder media: () -> Media
    ) {
        self.title = title
        self.subtitle = subtitle
        self.progressSymbol = progressSymbol
        self.proofSymbol = proofSymbol
        self.proofText = proofText
        self.media = AnyView(media())
    }
}

// MARK: - Scaffold

public struct CinematicOnboardingScaffold: View {
    // MARK: - Configuration
    @Binding private var isPresented: Bool
    private let steps: [CinematicOnboardingStep]
    private let accentColor: Color
    private let headerImageName: String?
    private let footerImageName: String?
    private let continueText: String
    private let preferredScheme: ColorScheme?
    private let onFinish: () -> Void

    // MARK: - Animation State
    @State private var step: Int = 0
    @State private var animatedStep: Int = 0
    @State private var contentOpacity: Double = 1

    // MARK: - Init
    public init(
        isPresented: Binding<Bool>,
        accentColor: Color,
        continueText: String,
        steps: [CinematicOnboardingStep],
        headerImageName: String? = nil,
        footerImageName: String? = nil,
        preferredScheme: ColorScheme? = .dark,
        onFinish: @escaping () -> Void
    ) {
        self._isPresented = isPresented
        self.accentColor = accentColor
        self.continueText = continueText
        self.steps = steps
        self.headerImageName = headerImageName
        self.footerImageName = footerImageName
        self.preferredScheme = preferredScheme
        self.onFinish = onFinish
    }

    // MARK: - View Body
    public var body: some View {
        ZStack {
            CinematicHeroFrame(
                headerImageName: headerImageName,
                footerImageName: footerImageName,
                accentColor: accentColor
            )

            VStack(spacing: 30) {
                CinematicProgressView(
                    symbols: steps.map(\.progressSymbol),
                    current: animatedStep,
                    accentColor: accentColor
                )

                stepContent
                    .opacity(contentOpacity)
            }
        }
        .preferredColorScheme(preferredScheme)
    }

    // MARK: - Subviews
    @ViewBuilder
    private var stepContent: some View {
        if let current = steps[safe: step] {
            VStack {
                VStack(spacing: 20) {
                    Text(current.title)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(current.subtitle)
                        .multilineTextAlignment(.center)
                        .opacity(0.8)
                }
                .padding(.horizontal)
                .padding(.horizontal)

                Spacer()

                current.media

                Spacer()

                actionArea(for: current)
            }
        }
    }

    private func actionArea(for current: CinematicOnboardingStep) -> some View {
        VStack(spacing: 25) {
            Button(action: nextStep) {
                HStack {
                    Spacer()
                    Text(continueText)
                        .font(.title3.bold())
                    Spacer()
                }
                .padding()
            }
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .foregroundStyle(accentColor)
            }
            .tint(.white)

            HStack {
                Image(systemName: current.proofSymbol)
                    .foregroundStyle(accentColor)
                Text(current.proofText)
                    .bold()
            }
            .font(.caption)
        }
        .padding()
    }

    // MARK: - Actions
    private func nextStep() {
        let isLast = step >= steps.count - 1
        if isLast {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                onFinish()
                isPresented = false
            }
        } else {
            withAnimation(.easeInOut(duration: 0.5)) {
                contentOpacity = 0
            }
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedStep = step + 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                step += 1
                withAnimation(.easeInOut(duration: 0.5)) {
                    contentOpacity = 1
                }
            }
        }
    }
}

// MARK: - Progress View

struct CinematicProgressView: View {
    // MARK: - Properties
    let symbols: [String]
    let current: Int
    let accentColor: Color

    // MARK: - View Body
    var body: some View {
        HStack {
            ForEach(Array(symbols.enumerated()), id: \.offset) { index, symbol in
                if index > 0 {
                    Spacer()
                        .background {
                            Rectangle()
                                .frame(height: 2)
                                .foregroundStyle(current >= index ? accentColor : Color.white.opacity(0.1))
                                .padding(.horizontal)
                        }
                }
                dot(symbol: symbol, reached: current >= index)
            }
        }
        .padding(.vertical)
        .padding(.horizontal, 50)
    }

    // MARK: - Subviews
    private func dot(symbol: String, reached: Bool) -> some View {
        ZStack {
            Circle()
                .foregroundStyle(reached ? accentColor : Color.white.opacity(0.3))
            Image(systemName: symbol)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 20, maxHeight: 20)
                .opacity(reached ? 1.0 : 0.5)
        }
        .foregroundStyle(.white)
        .scaleEffect(reached ? 1.2 : 0.8)
        .frame(width: 30, height: 30)
    }
}

// MARK: - Hero Frame

struct CinematicHeroFrame: View {
    // MARK: - Properties
    let headerImageName: String?
    let footerImageName: String?
    let accentColor: Color

    // MARK: - View Body
    var body: some View {
        VStack {
            header
            Spacer()
            footer
        }
        .ignoresSafeArea()
    }

    // MARK: - Subviews
    @ViewBuilder
    private var header: some View {
        if let headerImageName {
            Image(headerImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            LinearGradient(
                colors: [accentColor.opacity(0.45), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 260)
        }
    }

    @ViewBuilder
    private var footer: some View {
        if let footerImageName {
            Image(footerImageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .opacity(0.5)
        } else {
            LinearGradient(
                colors: [.clear, accentColor.opacity(0.25)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 200)
        }
    }
}

// MARK: - Safe Index

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
