import SwiftUI

@MainActor
struct WordBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TTSService.self) private var ttsService

    let words: [Word]

    @State private var gameState = GameStateManager()

    @State private var scrambledLetters: [LetterTile] = []
    @State private var placedLetters: [Character?] = []
    @State private var lockedSlotIndices: Set<Int> = []
    @State private var wiggleSlotIndex: Int? = nil

    @State private var celebrationDismissID = UUID()

    private var currentWord: Word? {
        gameState.currentWord
    }

    private var targetText: String {
        gameState.targetText
    }

    var body: some View {
        @Bindable var gameState = gameState

        gameContent
            .gameViewChrome(
                title: "Word Builder",
                wordCount: words.count,
                gameState: gameState,
                onClose: { dismiss() },
                closeAccessibilityIdentifier: "WordBuilder_CloseButton")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Difficulty", selection: $gameState.difficulty) {
                            ForEach(GameDifficulty.allCases) { d in
                                Text(d.displayName).tag(d)
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityIdentifier("WordBuilder_DifficultyMenu")
                }
            }
            .task {
                gameState.setup(words: words)
                startGameIfNeeded()
            }
            .task(id: gameState.currentWordIndex) {
                await startWord()
            }
            .task(id: celebrationDismissID) {
                guard gameState.showCelebration else { return }
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeOut(duration: 0.2)) {
                    gameState.hideCelebration()
                }
            }
            .fullScreenCover(isPresented: $gameState.showResult) {
                if let result = gameState.result {
                    GameResultView(
                        title: "Word Builder",
                        result: result,
                        onPlayAgain: {
                            resetAll()
                        },
                        onChooseDifferentGame: {
                            dismiss()
                        })
                }
            }
            .accessibilityIdentifier("WordBuilder_Root")
    }

    private var gameContent: some View {
        GeometryReader { _ in
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    wordSlots
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.top, 20)
                        .accessibilityIdentifier("WordBuilder_WordSlots")

                    Spacer()

                    speakerButton
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.vertical, 12)
                        .accessibilityIdentifier("WordBuilder_SpeakWordButton")

                    Spacer()

                    letterTilesTray
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.bottom, AppConstants.padding)
                        .accessibilityIdentifier("WordBuilder_TilesTray")
                }

                if gameState.showCelebration {
                    CelebrationView(
                        type: gameState.celebrationType,
                        message: gameState.celebrationMessage,
                        emoji: gameState.celebrationEmoji)
                        .transition(.scale.combined(with: .opacity))
                        .accessibilityIdentifier("WordBuilder_Celebration")
                }
            }
        }
    }

    // MARK: - Word Slots

    private var wordSlots: some View {
        HStack(spacing: 12) {
            ForEach(Array(targetText.enumerated()), id: \.offset) { index, expectedLetter in
                let placedLetter = index < placedLetters.count ? placedLetters[index] : nil
                let isLocked = lockedSlotIndices.contains(index)

                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isLocked ? AppConstants.successColor.opacity(0.2) : AppConstants.cardColor)
                        .frame(width: 60, height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    isLocked ? AppConstants.successColor : Color.gray.opacity(0.3),
                                    lineWidth: isLocked ? 3 : 2))
                        .shadow(
                            color: isLocked ? AppConstants.successColor.opacity(0.3) : Color.black.opacity(0.1),
                            radius: isLocked ? 8 : 2,
                            x: 0,
                            y: 2)
                        .rotationEffect(.degrees(wiggleSlotIndex == index ? -3 : 0))

                    if let placedLetter {
                        Text(String(placedLetter).uppercased())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(isLocked ? AppConstants.successColor : .primary)
                    } else if gameState.difficulty == .easy, index == 0 {
                        Text(String(expectedLetter).uppercased())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .dropDestination(for: String.self) { droppedStrings, _ in
                    guard !isLocked else { return false }
                    guard
                        let droppedString = droppedStrings.first,
                        let droppedLetter = droppedString.first
                    else { return false }

                    if droppedLetter.lowercased() == expectedLetter.lowercased() {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            placedLetters[index] = droppedLetter
                            lockedSlotIndices.insert(index)
                        }

                        if
                            let tileIndex = scrambledLetters
                                .firstIndex(where: { $0.letter.lowercased() == droppedLetter.lowercased() && !$0.isPlaced })
                        {
                            scrambledLetters[tileIndex] = LetterTile(
                                id: scrambledLetters[tileIndex].id,
                                letter: scrambledLetters[tileIndex].letter,
                                isPlaced: true)
                        }

                        if lockedSlotIndices.count == targetText.count {
                            completeWord()
                        } else {
                            gameState.showCelebration(type: .wordCorrect, message: nil, emoji: "✨")
                            celebrationDismissID = UUID()
                        }
                        return true
                    } else {
                        gameState.handleIncorrectAnswer()
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.3).repeatCount(3, autoreverses: true)) {
                            wiggleSlotIndex = index
                        }
                        Task {
                            try? await Task.sleep(for: .milliseconds(600))
                            wiggleSlotIndex = nil
                        }
                        gameState.showCelebration(type: .comboBreakthrough, message: "Try again", emoji: "💭")
                        celebrationDismissID = UUID()
                        return false
                    }
                }
                .accessibilityIdentifier("WordBuilder_Slot_\(index)")
                .accessibilityLabel(isLocked ?
                    "Slot \(index + 1), locked, letter \(String(placedLetter ?? expectedLetter).uppercased())" :
                    "Slot \(index + 1), empty")
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Speaker Button

    private var speakerButton: some View {
        Button {
            if let currentWord {
                ttsService.speak(currentWord.text, rate: 0.3)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "speaker.wave.2.fill")
                Text("Hear Word")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
            }
            .frame(maxWidth: .infinity, minHeight: AppConstants.largeButtonHeight)
        }
        .buttonStyle(.borderedProminent)
        .tint(AppConstants.primaryColor)
        .disabled(ttsService.isSpeaking || currentWord == nil)
    }

    // MARK: - Letter Tiles Tray

    private var letterTilesTray: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(scrambledLetters) { tile in
                    LetterTileView(letter: tile.letter, isPlaced: tile.isPlaced, isDragging: false)
                        .draggable(String(tile.letter).lowercased()) {
                            LetterTileView(letter: tile.letter, isPlaced: tile.isPlaced, isDragging: true)
                        }
                        .disabled(tile.isPlaced)
                        .accessibilityIdentifier("WordBuilder_Tile_\(String(tile.letter).uppercased())_\(tile.id)")
                        .accessibilityLabel("Letter \(String(tile.letter).uppercased())")
                        .accessibilityHint(tile.isPlaced ? "Already placed" : "Drag to slot")
                }
            }
            .padding(.horizontal, AppConstants.padding)
        }
        .frame(height: 80)
    }

    // MARK: - Game Lifecycle

    private func startGameIfNeeded() {
        guard gameState.phase == .ready else { return }
        gameState.phase = .playing
    }

    private func startWord() async {
        guard gameState.phase == .playing else { return }
        guard currentWord != nil else { return }

        gameState.startWordTimer()
        lockedSlotIndices.removeAll()
        placedLetters = Array(repeating: nil, count: targetText.count)

        let targetLetters = Array(targetText.lowercased())
        var tiles: [LetterTile] = targetLetters.map { letter in
            LetterTile(id: UUID(), letter: letter, isPlaced: false)
        }

        if gameState.difficulty == .hard {
            let decoyCount = min(3, targetLetters.count)
            let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
            for _ in 0 ..< decoyCount {
                if let randomLetter = alphabet.randomElement(), !targetLetters.contains(randomLetter) {
                    tiles.append(LetterTile(id: UUID(), letter: randomLetter, isPlaced: false))
                }
            }
        }

        scrambledLetters = tiles.shuffled()

        try? await Task.sleep(for: .milliseconds(250))
        if let currentWord {
            ttsService.speak(currentWord.text, rate: 0.3)
        }
    }

    private func completeWord() {
        gameState.handleCorrectAnswer()

        let timeTaken = gameState.wordStartTime.map { Date().timeIntervalSince($0) }
        let pointsResult = PointsService.calculatePoints(
            isCorrect: true,
            comboCount: gameState.comboCount,
            timeTaken: timeTaken,
            isFirstTry: gameState.mistakesThisWord == 0)
        let starsEarned = timeTaken != nil && gameState.mistakesThisWord == 0
            ? (timeTaken! <= PointsService.speedBonusThreshold ? 3 : 2)
            : 1
        gameState.showCelebration(
            type: .sessionComplete,
            message: "Word Architect! +\(pointsResult.totalPoints) pts • \(starsEarned)★",
            emoji: "🏗️")
        celebrationDismissID = UUID()

        gameState.advanceToNextWord()
        if gameState.isComplete {
            gameState.showResultScreen()
        }
    }

    private func resetAll() {
        gameState.reset()
        gameState.phase = .playing
    }
}

// MARK: - Letter Tile Model

private struct LetterTile: Identifiable {
    let id: UUID
    let letter: Character
    var isPlaced: Bool
}
