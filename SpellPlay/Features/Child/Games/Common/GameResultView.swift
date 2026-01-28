//
//  GameResultView.swift
//  SpellPlay
//

import SwiftUI

@MainActor
struct GameResultView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let result: GameResult
    let onPlayAgain: () -> Void
    let onChooseDifferentGame: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    Text("Great job!")
                        .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                        .foregroundColor(AppConstants.primaryColor)
                        .accessibilityIdentifier("GameResult_Title")

                    VStack(spacing: 14) {
                        Text(title)
                            .font(.system(size: AppConstants.titleSize, weight: .semibold))
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            statTile(title: "Points", value: "\(result.totalPoints)", tint: AppConstants.primaryColor)
                            statTile(title: "Stars", value: "\(result.totalStars)", tint: .yellow)
                        }

                        HStack(spacing: 12) {
                            statTile(title: "Words", value: "\(result.wordsCompleted)", tint: AppConstants.successColor)
                            statTile(title: "Mistakes", value: "\(result.totalMistakes)", tint: AppConstants.errorColor)
                        }
                    }
                    .padding(AppConstants.padding)
                    .background(AppConstants.cardColor)
                    .cornerRadius(AppConstants.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
                    .padding(.horizontal, AppConstants.padding)
                    .accessibilityIdentifier("GameResult_StatsCard")

                    Spacer()

                    VStack(spacing: 12) {
                        Button(action: onPlayAgain) {
                            Text("Play Again")
                                .font(.system(size: AppConstants.bodySize, weight: .semibold))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .largeButtonStyle(color: AppConstants.primaryColor)
                        .accessibilityIdentifier("GameResult_PlayAgainButton")

                        Button(action: onChooseDifferentGame) {
                            Text("Different Game")
                                .font(.system(size: AppConstants.bodySize, weight: .semibold))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .largeButtonStyle(color: AppConstants.secondaryColor)
                        .accessibilityIdentifier("GameResult_DifferentGameButton")

                        Button(action: { dismiss() }) {
                            Text("Done")
                                .font(.system(size: AppConstants.bodySize, weight: .semibold))
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .contentShape(Rectangle())
                        }
                        .largeButtonStyle(color: Color(.systemGray4))
                        .accessibilityIdentifier("GameResult_DoneButton")
                    }
                    .padding(.horizontal, AppConstants.padding)
                    .padding(.bottom, AppConstants.padding)
                }
                .padding(.top, AppConstants.padding)
            }
            .navigationTitle("Results")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func statTile(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: AppConstants.captionSize, weight: .medium))
                .foregroundColor(.secondary)

            Text(value)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(tint.opacity(0.10))
        .cornerRadius(AppConstants.cornerRadius)
    }
}


