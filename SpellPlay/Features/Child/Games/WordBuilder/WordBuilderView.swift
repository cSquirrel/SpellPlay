import SwiftUI

@MainActor
struct WordBuilderView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [Word]

    @State private var difficulty: GameDifficulty = .easy

    @State private var phase: GamePhase = .ready
    @State private var currentWordIndex = 0

    @State private var scrambledLetters: [LetterTile] = []
    @State private var placedLetters: [Character?] = []
    @State private var lockedSlotIndices: Set<Int> = []

    @State private var score = 0
    @State private var totalStars = 0
    @State private var comboCount = 0
    @State private var comboMultiplier = 1
    @State private var totalMistakes = 0
    @State private var mistakesThisWord = 0

    @State private var wordStartTime: Date?

    @State private var showCelebration = false
    @State private var celebrationType: CelebrationType = .wordCorrect
    @State private var celebrationMessage: String? = nil
    @State private var celebrationEmoji: String? = nil

    @State private var showResult = false
    @State private var result: GameResult?
    @State private var wiggleSlotIndex: Int? = nil

    @Environment(TTSService.self) private var ttsService

    private var currentWord: Word? {
        guard currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }

    private var targetText: String {
        currentWord?.text ?? ""
    }

    var body: some View {
        NavigationStack {
            GeometryReader { _ in
                ZStack {
                    AppConstants.backgroundColor
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameProgressView(
                            title: "Word Builder",
                            wordIndex: currentWordIndex,
                            wordCount: words.count,
                            points: score,
                            comboMultiplier: comboMultiplier)

                        // Word slots at top
                        wordSlots
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.top, 20)
                            .accessibilityIdentifier("WordBuilder_WordSlots")

                        Spacer()

                        // Speaker button
                        speakerButton
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.vertical, 12)
                            .accessibilityIdentifier("WordBuilder_SpeakWordButton")

                        Spacer()

                        // Letter tiles tray at bottom
                        letterTilesTray
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.bottom, AppConstants.padding)
                            .accessibilityIdentifier("WordBuilder_TilesTray")
                    }

                    if showCelebration {
                        CelebrationView(type: celebrationType, message: celebrationMessage, emoji: celebrationEmoji)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityIdentifier("WordBuilder_Celebration")
                    }
                }
            }
            .navigationTitle("Word Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("WordBuilder_CloseButton")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Picker("Difficulty", selection: $difficulty) {
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
                startGameIfNeeded()
            }
            .task(id: currentWordIndex) {
                await startWord()
            }
            .fullScreenCover(isPresented: $showResult) {
                if let result {
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
        }
        .accessibilityIdentifier("WordBuilder_Root")
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
                    } else if difficulty == .easy, index == 0 {
                        // Hint: show first letter on easy difficulty
                        Text(String(expectedLetter).uppercased())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.gray.opacity(0.5))
                    }
                }
                .dropDestination(for: String.self) { droppedStrings, _ in
                    guard !isLocked else { return false }
                    guard
                        let droppedString = droppedStrings.first,
                        let droppedLetter = droppedString.first else { return false }

                    if droppedLetter.lowercased() == expectedLetter.lowercased() {
                        // Correct placement
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            placedLetters[index] = droppedLetter
                            lockedSlotIndices.insert(index)
                        }

                        // Mark tile as placed
                        if
                            let tileIndex = scrambledLetters
                                .firstIndex(where: { $0.letter.lowercased() == droppedLetter.lowercased() && !$0.isPlaced
                                })
                        {
                            scrambledLetters[tileIndex] = LetterTile(
                                id: scrambledLetters[tileIndex].id,
                                letter: scrambledLetters[tileIndex].letter,
                                isPlaced: true)
                        }

                        // Check if word is complete
                        if lockedSlotIndices.count == targetText.count {
                            completeWord()
                        } else {
                            showCelebrationTransient(type: .wordCorrect, message: nil, emoji: "✨")
                        }
                        return true
                    } else {
                        // Incorrect placement - wiggle animation
                        mistakesThisWord += 1
                        totalMistakes += 1
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.3).repeatCount(3, autoreverses: true)) {
                            wiggleSlotIndex = index
                        }
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(600))
                            wiggleSlotIndex = nil
                        }
                        showCelebrationTransient(type: .comboBreakthrough, message: "Try again", emoji: "💭")
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
        guard phase == .ready else { return }
        phase = .playing
        currentWordIndex = 0
        score = 0
        totalStars = 0
        comboCount = 0
        comboMultiplier = 1
        totalMistakes = 0
        mistakesThisWord = 0
    }

    private func startWord() async {
        guard phase == .playing else { return }
        guard currentWord != nil else { return }

        // Reset per-word state
        mistakesThisWord = 0
        wordStartTime = Date()
        lockedSlotIndices.removeAll()
        placedLetters = Array(repeating: nil, count: targetText.count)

        // Scramble letters and add decoys based on difficulty
        let targetLetters = Array(targetText.lowercased())
        var tiles: [LetterTile] = targetLetters.map { letter in
            LetterTile(id: UUID(), letter: letter, isPlaced: false)
        }

        // Add decoy letters for harder difficulties
        if difficulty == .hard {
            let decoyCount = min(3, targetLetters.count)
            let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
            for _ in 0 ..< decoyCount {
                if
                    let randomLetter = alphabet.randomElement(),
                    !targetLetters.contains(randomLetter)
                {
                    tiles.append(LetterTile(id: UUID(), letter: randomLetter, isPlaced: false))
                }
            }
        }

        // Shuffle tiles
        scrambledLetters = tiles.shuffled()

        // Small delay to let UI settle, then speak
        try? await Task.sleep(for: .milliseconds(250))
        if let currentWord {
            ttsService.speak(currentWord.text, rate: 0.3)
        }
    }

    private func completeWord() {
        guard let wordStartTime else { return }
        let timeTaken = Date().timeIntervalSince(wordStartTime)

        // Combo is based on mistake-free word completion
        if mistakesThisWord == 0 {
            comboCount += 1
        } else {
            comboCount = 0
        }
        comboMultiplier = PointsService.getComboMultiplier(for: comboCount)

        let pointsResult = PointsService.calculatePoints(
            isCorrect: true,
            comboCount: comboCount,
            timeTaken: timeTaken,
            isFirstTry: mistakesThisWord == 0)
        score += pointsResult.totalPoints

        let starsEarned = if mistakesThisWord == 0, timeTaken <= PointsService.speedBonusThreshold {
            3
        } else if mistakesThisWord == 0 {
            2
        } else {
            1
        }
        totalStars += starsEarned

        showCelebrationTransient(
            type: .sessionComplete,
            message: "Word Architect! +\(pointsResult.totalPoints) pts • \(starsEarned)★",
            emoji: "🏗️")

        advanceToNextWord()
    }

    private func advanceToNextWord() {
        if currentWordIndex >= words.count - 1 {
            phase = .gameComplete
            result = GameResult(
                totalPoints: score,
                totalStars: totalStars,
                wordsCompleted: words.count,
                totalMistakes: totalMistakes)
            showResult = true
        } else {
            currentWordIndex += 1
        }
    }

    private func resetAll() {
        showResult = false
        result = nil
        phase = .ready
        startGameIfNeeded()
        Task { @MainActor in
            await startWord()
        }
    }

    private func showCelebrationTransient(type: CelebrationType, message: String?, emoji: String?) {
        celebrationType = type
        celebrationMessage = message
        celebrationEmoji = emoji

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showCelebration = true
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(700))
            withAnimation(.easeOut(duration: 0.2)) {
                showCelebration = false
            }
        }
    }
}

// MARK: - Letter Tile Model

private struct LetterTile: Identifiable {
    let id: UUID
    let letter: Character
    var isPlaced: Bool
}
