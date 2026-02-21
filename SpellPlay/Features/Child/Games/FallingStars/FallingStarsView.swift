import SwiftUI

@MainActor
struct FallingStarsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TTSService.self) private var ttsService

    let words: [Word]

    @State private var gameState = GameStateManager()

    @State private var nextExpectedIndex = 0

    @State private var activeStars: [Star] = []
    @State private var lastSpawnAt: Date = .distantPast
    @State private var constellationPoints: [CGPoint] = []

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
                title: "Falling Stars",
                wordCount: words.count,
                gameState: gameState,
                onClose: { dismiss() },
                closeAccessibilityIdentifier: "FallingStars_CloseButton")
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
                        title: "Falling Stars",
                        result: result,
                        onPlayAgain: {
                            resetAll()
                        },
                        onChooseDifferentGame: {
                            dismiss()
                        })
                }
            }
            .accessibilityIdentifier("FallingStars_Root")
    }

    private var gameContent: some View {
        GeometryReader { geo in
            ZStack {
                nightSkyBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    wordDisplay
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.top, 10)
                        .accessibilityIdentifier("FallingStars_WordDisplay")

                    Spacer()

                    ZStack {
                        constellationPath
                            .stroke(Color.yellow.opacity(0.6), lineWidth: 3)
                            .shadow(color: .yellow.opacity(0.4), radius: 8)

                        ForEach(constellationPoints.indices, id: \.self) { idx in
                            Circle()
                                .fill(Color.yellow)
                                .frame(width: 8, height: 8)
                                .position(constellationPoints[idx])
                                .shadow(color: .yellow.opacity(0.6), radius: 6)
                        }

                        TimelineView(.animation) { context in
                            ZStack {
                                ForEach(visibleStars(in: geo.size, now: context.date)) { star in
                                    StarView(letter: star.letter, id: star.id) {
                                        handleTap(star: star, now: context.date, size: geo.size)
                                    }
                                    .position(
                                        x: star.startX,
                                        y: starY(for: star, size: geo.size, now: context.date))
                                    .opacity(starOpacity(for: star, now: context.date))
                                }
                            }
                            .onChange(of: context.date) { _, newDate in
                                tick(now: newDate, size: geo.size)
                            }
                        }
                    }
                    .accessibilityIdentifier("FallingStars_Playfield")

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
                        .accessibilityIdentifier("FallingStars_Celebration")
                }
            }
        }
    }

    // MARK: - Background

    private var nightSkyBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.15, blue: 0.4),
                ],
                startPoint: .top,
                endPoint: .bottom)

            TimelineView(.animation) { timelineContext in
                Canvas { graphicsContext, size in
                    let time = timelineContext.date.timeIntervalSince1970
                    let starCount = 50

                    for i in 0 ..< starCount {
                        var generator = SeededRandomNumberGenerator(seed: UInt64(i))
                        let x = CGFloat.random(in: 0 ... size.width, using: &generator)
                        let y = CGFloat.random(in: 0 ... size.height, using: &generator)

                        let twinklePhase = (time + Double(i) * 0.3).truncatingRemainder(dividingBy: 4.0)
                        let opacity = 0.3 + (sin(twinklePhase) * 0.4)

                        graphicsContext.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(.white.opacity(opacity)))
                    }
                }
            }
        }
    }

    // MARK: - Constellation

    private var constellationPath: Path {
        var path = Path()
        guard constellationPoints.count > 1 else { return path }

        path.move(to: constellationPoints[0])
        for i in 1 ..< constellationPoints.count {
            path.addLine(to: constellationPoints[i])
        }

        return path
    }

    // MARK: - Word Display

    private var wordDisplay: some View {
        let letters = Array(targetText)

        return HStack(spacing: 10) {
            ForEach(letters.indices, id: \.self) { idx in
                let isFilled = idx < nextExpectedIndex
                Text(String(letters[idx]).uppercased())
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(isFilled ? .yellow : Color.white.opacity(0.3))
                    .frame(minWidth: 22)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
        .cornerRadius(AppConstants.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2))
    }

    // MARK: - Controls

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
            .accessibilityIdentifier("FallingStars_SpeakWordButton")

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
            .accessibilityIdentifier("FallingStars_DifficultyMenu")
        }
    }

    // MARK: - Game lifecycle

    private func startGameIfNeeded() {
        guard gameState.phase == .ready else { return }
        gameState.phase = .playing
        nextExpectedIndex = 0
        activeStars.removeAll()
        constellationPoints.removeAll()
        lastSpawnAt = .distantPast
    }

    private func startWord() async {
        guard gameState.phase == .playing else { return }
        guard currentWord != nil else { return }

        nextExpectedIndex = 0
        gameState.startWordTimer()
        activeStars.removeAll()
        constellationPoints.removeAll()
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

        activeStars = activeStars.filter { star in
            let elapsed = now.timeIntervalSince(star.spawnTime)
            let y = starY(for: star, size: size, now: now)
            return elapsed < star.lifetime && y < size.height + 100
        }

        let interval = spawnInterval(for: gameState.difficulty)
        if now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnStar(now: now, size: size)
            lastSpawnAt = now
        }
    }

    private func spawnStar(now: Date, size: CGSize) {
        guard let nextLetter = expectedLetter else { return }

        let letterToUse: Character = if shouldSpawnDecoy(for: gameState.difficulty) {
            randomDecoyLetter(avoid: nextLetter) ?? nextLetter
        } else {
            nextLetter
        }

        let x = CGFloat.random(in: 60 ... max(61, size.width - 60))
        let yStart: CGFloat = -60

        let star = Star(
            id: UUID(),
            letter: letterToUse,
            startX: x,
            startY: yStart,
            fallSpeed: fallSpeed(for: gameState.difficulty),
            spawnTime: now,
            lifetime: starLifetime(for: gameState.difficulty))

        activeStars.append(star)
    }

    private func visibleStars(in size: CGSize, now: Date) -> [Star] {
        activeStars.filter { star in
            let elapsed = now.timeIntervalSince(star.spawnTime)
            let y = starY(for: star, size: size, now: now)
            return elapsed < star.lifetime && y < size.height + 100 && y > -100
        }
    }

    private func starY(for star: Star, size: CGSize, now: Date) -> CGFloat {
        let elapsed = now.timeIntervalSince(star.spawnTime)
        return star.startY + CGFloat(elapsed) * star.fallSpeed
    }

    private func starOpacity(for star: Star, now: Date) -> Double {
        let elapsed = now.timeIntervalSince(star.spawnTime)
        let lifeProgress = elapsed / star.lifetime
        return max(0, 1.0 - lifeProgress)
    }

    // MARK: - Tap handling / scoring

    private func handleTap(star: Star, now: Date, size: CGSize) {
        guard gameState.phase == .playing else { return }

        let currentY = starY(for: star, size: size, now: now)
        let tapPosition = CGPoint(x: star.startX, y: currentY)

        activeStars.removeAll { $0.id == star.id }

        guard let expectedLetter else { return }

        if star.letter.lowercased() == expectedLetter.lowercased() {
            nextExpectedIndex += 1
            constellationPoints.append(tapPosition)
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
            message: "Star Collector! +\(pointsResult.totalPoints) pts • \(starsEarned)★",
            emoji: "⭐")
        celebrationDismissID = UUID()

        gameState.advanceToNextWord()
        if gameState.isComplete {
            gameState.showResultScreen()
        }
    }

    // MARK: - Difficulty knobs

    private func spawnInterval(for difficulty: GameDifficulty) -> TimeInterval {
        switch difficulty {
        case .easy: 1.2
        case .medium: 0.9
        case .hard: 0.6
        }
    }

    private func fallSpeed(for difficulty: GameDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: 80
        case .medium: 120
        case .hard: 180
        }
    }

    private func starLifetime(for difficulty: GameDifficulty) -> TimeInterval {
        switch difficulty {
        case .easy: 8.0
        case .medium: 6.0
        case .hard: 4.0
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
}

// MARK: - Star Model

private struct Star: Identifiable {
    let id: UUID
    let letter: Character
    let startX: CGFloat
    let startY: CGFloat
    let fallSpeed: CGFloat
    let spawnTime: Date
    let lifetime: TimeInterval
}

// MARK: - Seeded Random Number Generator

private struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 1_103_515_245 &+ 12345
        return state
    }
}
