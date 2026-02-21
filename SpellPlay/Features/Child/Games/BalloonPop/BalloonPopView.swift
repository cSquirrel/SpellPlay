import SwiftUI

@MainActor
struct BalloonPopView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TTSService.self) private var ttsService

    let words: [Word]

    @State private var gameState = GameStateManager()

    @State private var nextExpectedIndex = 0

    @State private var activeBalloons: [Balloon] = []
    @State private var lastSpawnAt: Date = .distantPast

    @State private var celebrationDismissID = UUID()

    private var currentWord: Word? {
        gameState.currentWord
    }

    private var targetText: String {
        gameState.targetText
    }

    var body: some View {
        @Bindable var gameState = gameState

        NavigationStack {
            GeometryReader { geo in
                ZStack {
                    background
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameProgressView(
                            title: "Balloon Pop",
                            wordIndex: gameState.currentWordIndex,
                            wordCount: words.count,
                            points: gameState.score,
                            comboMultiplier: gameState.comboMultiplier)

                        wordDisplay
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.top, 10)
                            .accessibilityIdentifier("BalloonPop_WordDisplay")

                        Spacer()

                        // Balloon playfield
                        TimelineView(.animation) { context in
                            ZStack {
                                ForEach(visibleBalloons(in: geo.size, now: context.date)) { balloon in
                                    BalloonView(letter: balloon.letter, color: balloon.color) {
                                        handleTap(balloon: balloon, now: context.date)
                                    }
                                    .position(
                                        x: balloon.x,
                                        y: balloonY(for: balloon, size: geo.size, now: context.date))
                                    .accessibilityIdentifier("BalloonPop_Balloon_\(balloon.id.uuidString)")
                                }
                            }
                            .onChange(of: context.date) { _, newDate in
                                tick(now: newDate, size: geo.size)
                            }
                        }
                        .accessibilityIdentifier("BalloonPop_Playfield")

                        Spacer()

                        controls
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.bottom, AppConstants.padding)
                    }

                    if gameState.showCelebration {
                        CelebrationView(
                            type: gameState.celebrationType,
                            message: gameState.celebrationMessage,
                            emoji: gameState.celebrationEmoji)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityIdentifier("BalloonPop_Celebration")
                    }
                }
            }
            .navigationTitle("Balloon Pop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("BalloonPop_CloseButton")
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
                        title: "Balloon Pop",
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
        .accessibilityIdentifier("BalloonPop_Root")
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.80, blue: 0.98),
                Color(red: 0.90, green: 0.97, blue: 1.00),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .overlay(alignment: .topLeading) {
                cloud(offsetX: 40, offsetY: 40)
            }
            .overlay(alignment: .topTrailing) {
                cloud(offsetX: -30, offsetY: 90)
            }
    }

    private func cloud(offsetX: CGFloat, offsetY: CGFloat) -> some View {
        HStack(spacing: -18) {
            Circle().fill(Color.white.opacity(0.65)).frame(width: 52, height: 52)
            Circle().fill(Color.white.opacity(0.65)).frame(width: 64, height: 64)
            Circle().fill(Color.white.opacity(0.65)).frame(width: 52, height: 52)
        }
        .offset(x: offsetX, y: offsetY)
    }

    private var wordDisplay: some View {
        let letters = Array(targetText)

        return HStack(spacing: 10) {
            ForEach(letters.indices, id: \.self) { idx in
                let isFilled = idx < nextExpectedIndex
                Text(String(letters[idx]).uppercased())
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(isFilled ? .primary : Color.gray.opacity(0.4))
                    .frame(minWidth: 22)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.55))
        .cornerRadius(AppConstants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .stroke(Color.white.opacity(0.45), lineWidth: 2))
    }

    private var controls: some View {
        HStack(spacing: 12) {
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
            .accessibilityIdentifier("BalloonPop_SpeakWordButton")

            Menu {
                Picker("Difficulty", selection: $gameState.difficulty) {
                    ForEach(GameDifficulty.allCases) { d in
                        Text(d.displayName).tag(d)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text(gameState.difficulty.displayName)
                        .font(.system(size: AppConstants.bodySize, weight: .semibold))
                }
                .frame(minHeight: AppConstants.largeButtonHeight)
            }
            .buttonStyle(.bordered)
            .tint(AppConstants.secondaryColor)
            .accessibilityIdentifier("BalloonPop_DifficultyMenu")
        }
    }

    // MARK: - Game lifecycle

    private func startGameIfNeeded() {
        guard gameState.phase == .ready else { return }
        gameState.phase = .playing
        nextExpectedIndex = 0
        activeBalloons.removeAll()
        lastSpawnAt = .distantPast
    }

    private func startWord() async {
        guard gameState.phase == .playing else { return }
        guard currentWord != nil else { return }

        nextExpectedIndex = 0
        gameState.startWordTimer()
        activeBalloons.removeAll()
        lastSpawnAt = .distantPast

        try? await Task.sleep(for: .milliseconds(250))
        if let currentWord {
            ttsService.speak(currentWord.text, rate: 0.3)
        }
    }

    private func resetAll() {
        gameState.reset()
        gameState.phase = .playing
    }

    // MARK: - Timeline tick / spawning

    private func tick(now: Date, size: CGSize) {
        guard gameState.phase == .playing else { return }
        guard !targetText.isEmpty else { return }

        activeBalloons = activeBalloons.filter { balloon in
            balloonY(for: balloon, size: size, now: now) > -160
        }

        let interval = spawnInterval(for: gameState.difficulty)
        if now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnBalloon(now: now, size: size)
            lastSpawnAt = now
        }
    }

    private func spawnBalloon(now: Date, size: CGSize) {
        guard let nextLetter = expectedLetter else { return }

        let letterToUse: Character = if shouldSpawnDecoy(for: gameState.difficulty) {
            randomDecoyLetter(avoid: nextLetter) ?? nextLetter
        } else {
            nextLetter
        }

        let x = CGFloat.random(in: 40 ... max(41, size.width - 40))
        let yStart = size.height + 140

        let balloon = Balloon(
            id: UUID(),
            letter: letterToUse,
            x: x,
            yStart: yStart,
            speed: balloonSpeed(for: gameState.difficulty),
            color: balloonColor(),
            spawnedAt: now)

        activeBalloons.append(balloon)
    }

    private func visibleBalloons(in size: CGSize, now: Date) -> [Balloon] {
        activeBalloons.filter { balloonY(for: $0, size: size, now: now) > -160 }
    }

    private func balloonY(for balloon: Balloon, size: CGSize, now: Date) -> CGFloat {
        let elapsed = now.timeIntervalSince(balloon.spawnedAt)
        return balloon.yStart - CGFloat(elapsed) * balloon.speed
    }

    // MARK: - Tap handling / scoring

    private func handleTap(balloon: Balloon, now: Date) {
        guard gameState.phase == .playing else { return }

        activeBalloons.removeAll { $0.id == balloon.id }

        guard let expectedLetter else { return }

        if balloon.letter.lowercased() == expectedLetter.lowercased() {
            nextExpectedIndex += 1
            gameState.showCelebration(type: .wordCorrect, message: nil, emoji: "✨")
            celebrationDismissID = UUID()

            if nextExpectedIndex >= targetText.count {
                completeWord(now: now)
            }
        } else {
            gameState.handleIncorrectAnswer()
            gameState.showCelebration(type: .comboBreakthrough, message: "Try again", emoji: "💭")
            celebrationDismissID = UUID()
        }
    }

    private func completeWord(now: Date) {
        gameState.handleCorrectAnswer()

        let timeTaken = gameState.wordStartTime.map { now.timeIntervalSince($0) }
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
            message: "+\(pointsResult.totalPoints) pts • \(starsEarned)★",
            emoji: "🎉")
        celebrationDismissID = UUID()

        gameState.advanceToNextWord()
        if gameState.isComplete {
            gameState.showResultScreen()
        }
    }

    // MARK: - Difficulty knobs

    private func spawnInterval(for difficulty: GameDifficulty) -> TimeInterval {
        switch difficulty {
        case .easy: 1.0
        case .medium: 0.75
        case .hard: 0.55
        }
    }

    private func balloonSpeed(for difficulty: GameDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: 140
        case .medium: 190
        case .hard: 240
        }
    }

    private func shouldSpawnDecoy(for difficulty: GameDifficulty) -> Bool {
        let roll = Double.random(in: 0 ... 1)
        switch difficulty {
        case .easy: return roll < 0.25
        case .medium: return roll < 0.40
        case .hard: return roll < 0.55
        }
    }

    private var expectedLetter: Character? {
        let letters = Array(targetText)
        guard nextExpectedIndex < letters.count else { return nil }
        return letters[nextExpectedIndex]
    }

    private func randomDecoyLetter(avoid: Character) -> Character? {
        let alphabet = Array("abcdefghijklmnopqrstuvwxyz")
        let candidates = alphabet.filter { $0.lowercased() != avoid.lowercased() }
        return candidates.randomElement()
    }

    private func balloonColor() -> Color {
        [
            Color.red, Color.blue, Color.green, Color.purple, Color.orange, Color.pink, Color.teal,
        ].randomElement() ?? Color.blue
    }
}

private struct Balloon: Identifiable {
    let id: UUID
    let letter: Character
    let x: CGFloat
    let yStart: CGFloat
    let speed: CGFloat
    let color: Color
    let spawnedAt: Date
}
