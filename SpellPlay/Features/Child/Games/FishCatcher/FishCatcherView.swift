import SwiftUI

@MainActor
struct FishCatcherView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(TTSService.self) private var ttsService

    let words: [Word]

    @State private var gameState = GameStateManager()

    @State private var nextExpectedIndex = 0

    @State private var activeFish: [Fish] = []
    @State private var lastSpawnAt: Date = .distantPast

    @State private var bucketBounce: CGFloat = 1.0
    @State private var waveOffset: CGFloat = 0

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
                title: "Fish Catcher",
                wordCount: words.count,
                gameState: gameState,
                onClose: { dismiss() },
                closeAccessibilityIdentifier: "FishCatcher_CloseButton")
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
                        title: "Fish Catcher",
                        result: result,
                        onPlayAgain: {
                            resetAll()
                        },
                        onChooseDifferentGame: {
                            dismiss()
                        })
                }
            }
            .accessibilityIdentifier("FishCatcher_Root")
    }

    private var gameContent: some View {
        GeometryReader { geo in
            ZStack {
                background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    wordDisplay
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.top, 10)
                        .accessibilityIdentifier("FishCatcher_WordDisplay")

                    Spacer()

                    TimelineView(.animation) { context in
                        ZStack {
                            ForEach(visibleFish(in: geo.size, now: context.date)) { fish in
                                FishView(letter: fish.letter, id: fish.id, color: fish.color) {
                                    handleTap(fish: fish, now: context.date)
                                }
                                .position(
                                    x: fishX(for: fish, size: geo.size, now: context.date),
                                    y: fish.yDepth)
                                .accessibilityIdentifier("FishCatcher_Fish_\(fish.id.uuidString)")
                            }
                        }
                        .onChange(of: context.date) { _, newDate in
                            tick(now: newDate, size: geo.size)
                        }
                    }
                    .accessibilityIdentifier("FishCatcher_Playfield")

                    bucketView
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.bottom, AppConstants.padding)
                        .accessibilityIdentifier("FishCatcher_Bucket")

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
                        .accessibilityIdentifier("FishCatcher_Celebration")
                }
            }
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.4, green: 0.7, blue: 0.95),
                Color(red: 0.2, green: 0.5, blue: 0.8),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .overlay(alignment: .bottom) {
                WaveShape(offset: waveOffset)
                    .fill(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.3))
                    .frame(height: 40)
            }
            .onAppear {
                withAnimation(.linear(duration: 3).repeatForever(autoreverses: false)) {
                    waveOffset = 360
                }
            }
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

    private var bucketView: some View {
        VStack(spacing: 8) {
            if nextExpectedIndex > 0 {
                HStack(spacing: 8) {
                    Text("Caught:")
                        .font(.system(size: AppConstants.captionSize, weight: .semibold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        ForEach(0 ..< nextExpectedIndex, id: \.self) { idx in
                            Text(String(Array(targetText)[idx]).uppercased())
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(AppConstants.successColor)
                                .clipShape(Circle())
                        }
                    }
                }
                .accessibilityIdentifier("FishCatcher_CaughtLetters")
            }

            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.brown.opacity(0.8),
                                Color.brown.opacity(0.6),
                            ],
                            startPoint: .top,
                            endPoint: .bottom))
                    .frame(height: 60)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brown.opacity(0.9), lineWidth: 3)
                    }

                Text("🪣")
                    .font(.system(size: 32))
            }
            .scaleEffect(bucketBounce)
        }
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
            .accessibilityIdentifier("FishCatcher_SpeakWordButton")

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
            .accessibilityIdentifier("FishCatcher_DifficultyMenu")
        }
    }

    // MARK: - Game lifecycle

    private func startGameIfNeeded() {
        guard gameState.phase == .ready else { return }
        gameState.phase = .playing
        nextExpectedIndex = 0
        activeFish.removeAll()
        lastSpawnAt = .distantPast
    }

    private func startWord() async {
        guard gameState.phase == .playing else { return }
        guard currentWord != nil else { return }

        nextExpectedIndex = 0
        gameState.startWordTimer()
        activeFish.removeAll()
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

        activeFish = activeFish.filter { fish in
            fishX(for: fish, size: size, now: now) < size.width + 100
        }

        let interval = spawnInterval(for: gameState.difficulty)
        if now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnFish(now: now, size: size)
            lastSpawnAt = now
        }
    }

    private func spawnFish(now: Date, size: CGSize) {
        guard let nextLetter = expectedLetter else { return }

        let letterToUse: Character = if shouldSpawnDecoy(for: gameState.difficulty) {
            randomDecoyLetter(avoid: nextLetter) ?? nextLetter
        } else {
            nextLetter
        }

        let startX: CGFloat = -50

        let topMargin: CGFloat = 250
        let bottomMargin: CGFloat = 250
        let availableHeight = size.height - topMargin - bottomMargin
        let middleStart = topMargin + (availableHeight * 0.2)
        let middleEnd = topMargin + (availableHeight * 0.8)
        let yDepth = CGFloat.random(in: middleStart ... middleEnd)

        let fish = Fish(
            id: UUID(),
            letter: letterToUse,
            startX: startX,
            yDepth: yDepth,
            speed: fishSpeed(for: gameState.difficulty),
            color: fishColor(),
            spawnedAt: now)

        activeFish.append(fish)
    }

    private func visibleFish(in size: CGSize, now: Date) -> [Fish] {
        activeFish.filter { fish in
            let x = fishX(for: fish, size: size, now: now)
            return x > -100 && x < size.width + 100
        }
    }

    private func fishX(for fish: Fish, size: CGSize, now: Date) -> CGFloat {
        let elapsed = now.timeIntervalSince(fish.spawnedAt)
        return fish.startX + CGFloat(elapsed) * fish.speed
    }

    // MARK: - Tap handling / scoring

    private func handleTap(fish: Fish, now: Date) {
        guard gameState.phase == .playing else { return }

        activeFish.removeAll { $0.id == fish.id }

        guard let expectedLetter else { return }

        if fish.letter.lowercased() == expectedLetter.lowercased() {
            nextExpectedIndex += 1

            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bucketBounce = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                bucketBounce = 1.0
            }

            gameState.showCelebration(type: .wordCorrect, message: nil, emoji: "🐟")
            celebrationDismissID = UUID()

            if nextExpectedIndex >= targetText.count {
                completeWord(now: now)
            }
        } else {
            gameState.handleIncorrectAnswer()
            gameState.showCelebration(type: .comboBreakthrough, message: "Try again", emoji: "💧")
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
            emoji: "🌊")
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

    private func fishSpeed(for difficulty: GameDifficulty) -> CGFloat {
        switch difficulty {
        case .easy: 120
        case .medium: 180
        case .hard: 250
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

    private func fishColor() -> Color {
        [
            Color.orange, Color.pink, Color.yellow, Color.green, Color.cyan, Color.purple,
        ].randomElement() ?? Color.blue
    }
}

private struct Fish: Identifiable {
    let id: UUID
    let letter: Character
    let startX: CGFloat
    let yDepth: CGFloat
    let speed: CGFloat
    let color: Color
    let spawnedAt: Date
}

private struct WaveShape: Shape {
    var offset: CGFloat = 0

    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let waveHeight: CGFloat = 8
        let waveLength: CGFloat = rect.width / 2

        path.move(to: CGPoint(x: 0, y: rect.midY))

        for x in stride(from: 0, through: rect.width, by: 1) {
            let angle = (x / waveLength) * .pi * 2 + (offset * .pi / 180)
            let y = rect.midY + sin(angle) * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }

        return path
    }
}
