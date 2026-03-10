import SwiftUI

/// Shared chrome for game views: NavigationStack, progress bar, and close toolbar.
/// New games should use this modifier so nav and progress stay consistent.
@MainActor
struct GameViewModifier: ViewModifier {
    let title: String
    let wordCount: Int
    let gameState: GameStateManager
    let onClose: () -> Void
    let closeAccessibilityIdentifier: String

    func body(content: Content) -> some View {
        NavigationStack {
            VStack(spacing: 0) {
                GameProgressView(
                    title: title,
                    wordIndex: gameState.currentWordIndex,
                    wordCount: wordCount,
                    points: gameState.score,
                    comboMultiplier: gameState.comboMultiplier)
                content
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityHint("Closes the game and returns to game selection")
                    .accessibilityIdentifier(closeAccessibilityIdentifier)
                }
            }
        }
    }
}

extension View {
    /// Wraps game content with shared chrome: nav stack, progress, and close button.
    func gameViewChrome(
        title: String,
        wordCount: Int,
        gameState: GameStateManager,
        onClose: @escaping () -> Void,
        closeAccessibilityIdentifier: String
    )
    -> some View {
        modifier(GameViewModifier(
            title: title,
            wordCount: wordCount,
            gameState: gameState,
            onClose: onClose,
            closeAccessibilityIdentifier: closeAccessibilityIdentifier))
    }
}
