//
//  GameSelectionView.swift
//  SpellPlay
//

import SwiftUI

@MainActor
struct GameSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let test: SpellingTest

    // Words sorted by displayOrder to preserve entry order
    private var sortedWords: [Word] {
        test.words.sortedAsCreated()
    }

    @State private var selectedGame: GameKind?

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Choose a Game")
                            .font(.system(size: AppConstants.titleSize, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.top, AppConstants.padding)
                            .accessibilityIdentifier("GameSelection_Title")

                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 12),
                            GridItem(.flexible(), spacing: 12)
                        ], spacing: 12) {
                            gameCard(.balloonPop)
                            gameCard(.fishCatcher, isEnabled: false)
                            gameCard(.wordBuilder, isEnabled: false)
                            gameCard(.fallingStars, isEnabled: false)
                            gameCard(.rocketLaunch, isEnabled: false)
                        }
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.bottom, AppConstants.padding)
                    }
                }
            }
            .navigationTitle(test.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("GameSelection_CloseButton")
                }
            }
            .fullScreenCover(item: $selectedGame) { game in
                switch game {
                case .balloonPop:
                    BalloonPopView(words: sortedWords)
                case .fishCatcher, .wordBuilder, .fallingStars, .rocketLaunch:
                    ComingSoonView(gameName: game.title)
                }
            }
        }
    }

    private func gameCard(_ game: GameKind, isEnabled: Bool = true) -> some View {
        Button {
            guard isEnabled else { return }
            selectedGame = game
        } label: {
            VStack(spacing: 10) {
                Text(game.emoji)
                    .font(.system(size: 44))

                Text(game.title)
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    .foregroundColor(.primary)

                Text(isEnabled ? game.subtitle : "Coming soon")
                    .font(.system(size: AppConstants.captionSize))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(AppConstants.cardColor)
            .cornerRadius(AppConstants.cornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            .opacity(isEnabled ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("GameSelection_Card_\(game.accessibilityId)")
        .accessibilityLabel(game.title)
    }
}

private enum GameKind: String, Identifiable {
    case balloonPop
    case fishCatcher
    case wordBuilder
    case fallingStars
    case rocketLaunch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .balloonPop: "Balloon Pop"
        case .fishCatcher: "Fish Catcher"
        case .wordBuilder: "Word Builder"
        case .fallingStars: "Falling Stars"
        case .rocketLaunch: "Rocket Launch"
        }
    }

    var subtitle: String {
        switch self {
        case .balloonPop: "Tap letters in order"
        case .fishCatcher: "Catch the right fish"
        case .wordBuilder: "Drag letters to slots"
        case .fallingStars: "Tap stars before they fade"
        case .rocketLaunch: "Type to fuel the rocket"
        }
    }

    var emoji: String {
        switch self {
        case .balloonPop: "🎈"
        case .fishCatcher: "🐟"
        case .wordBuilder: "🧩"
        case .fallingStars: "⭐"
        case .rocketLaunch: "🚀"
        }
    }

    var accessibilityId: String {
        rawValue
    }
}

@MainActor
private struct ComingSoonView: View {
    @Environment(\.dismiss) private var dismiss

    let gameName: String

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 12) {
                    Text("Coming soon")
                        .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                        .foregroundColor(AppConstants.primaryColor)

                    Text("\(gameName) is not available yet.")
                        .font(.system(size: AppConstants.bodySize))
                        .foregroundColor(.secondary)
                }
                .padding(AppConstants.padding)
            }
            .navigationTitle(gameName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("ComingSoon_CloseButton")
                }
            }
        }
    }
}


