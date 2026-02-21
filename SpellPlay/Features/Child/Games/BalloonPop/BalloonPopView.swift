import SwiftUI

@MainActor
struct BalloonPopView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [Word]

    @State private var difficulty: GameDifficulty = .easy

    @State private var phase: GamePhase = .ready
    @State private var currentWordIndex = 0
    @State private var nextExpectedIndex = 0

    @State private var activeBalloons: [Balloon] = []
    @State private var lastSpawnAt: Date = .distantPast

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
            GeometryReader { geo in
                ZStack {
                    background
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameProgressView(
                            title: "Balloon Pop",
                            wordIndex: currentWordIndex,
                            wordCount: words.count,
                            points: score,
                            comboMultiplier: comboMultiplier)

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

                    if showCelebration {
                        CelebrationView(type: celebrationType, message: celebrationMessage, emoji: celebrationEmoji)
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
                startGameIfNeeded()
            }
            .task(id: currentWordIndex) {
                await startWord()
            }
            .task(id: celebrationDismissID) {
                // Auto-hide celebration after delay
                guard showCelebration else { return }
                try? await Task.sleep(for: .milliseconds(700))
                withAnimation(.easeOut(duration: 0.2)) {
                    showCelebration = false
                }
            }
            .fullScreenCover(isPresented: $showResult) {
                if let result {
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
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(GameDifficulty.allCases) { d in
                        Text(d.displayName).tag(d)
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                    Text(difficulty.displayName)
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
        guard phase == .ready else { return }
        phase = .playing
        currentWordIndex = 0
        nextExpectedIndex = 0
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
        nextExpectedIndex = 0
        mistakesThisWord = 0
        wordStartTime = Date()
        activeBalloons.removeAll()
        lastSpawnAt = .distantPast

        // Small delay to let UI settle, then speak
        try? await Task.sleep(for: .milliseconds(250))
        if let currentWord {
            ttsService.speak(currentWord.text, rate: 0.3)
        }
    }

    private func resetAll() {
        showResult = false
        result = nil
        phase = .ready
        startGameIfNeeded()
        // Note: startWord will be called automatically via .task(id: currentWordIndex)
    }

    // MARK: - Timeline tick / spawning

    private func tick(now: Date, size: CGSize) {
        guard phase == .playing else { return }
        guard !targetText.isEmpty else { return }

        // Remove balloons that have left the screen
        activeBalloons = activeBalloons.filter { balloon in
            balloonY(for: balloon, size: size, now: now) > -160
        }

        let interval = spawnInterval(for: difficulty)
        if now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnBalloon(now: now, size: size)
            lastSpawnAt = now
        }
    }

    private func spawnBalloon(now: Date, size: CGSize) {
        guard let nextLetter = expectedLetter else { return }

        let letterToUse: Character = if shouldSpawnDecoy(for: difficulty) {
            randomDecoyLetter(avoid: nextLetter) ?? nextLetter
        } else {
            // Spawn the correct next letter more often
            nextLetter
        }

        let x = CGFloat.random(in: 40 ... max(41, size.width - 40))
        let yStart = size.height + 140

        let balloon = Balloon(
            id: UUID(),
            letter: letterToUse,
            x: x,
            yStart: yStart,
            speed: balloonSpeed(for: difficulty),
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
        guard phase == .playing else { return }

        // Remove balloon (harmless pop either way)
        activeBalloons.removeAll { $0.id == balloon.id }

        guard let expectedLetter else { return }

        if balloon.letter.lowercased() == expectedLetter.lowercased() {
            nextExpectedIndex += 1
            showCelebrationTransient(type: .wordCorrect, message: nil, emoji: "✨")

            if nextExpectedIndex >= targetText.count {
                completeWord(now: now)
            }
        } else {
            mistakesThisWord += 1
            totalMistakes += 1
            showCelebrationTransient(type: .comboBreakthrough, message: "Try again", emoji: "💭")
        }
    }

    private func completeWord(now: Date) {
        let timeTaken = wordStartTime.map { now.timeIntervalSince($0) }

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

        let starsEarned = if mistakesThisWord == 0, let t = timeTaken, t <= PointsService.speedBonusThreshold {
            3
        } else if mistakesThisWord == 0 {
            2
        } else {
            1
        }
        totalStars += starsEarned

        showCelebrationTransient(
            type: .sessionComplete,
            message: "+\(pointsResult.totalPoints) pts • \(starsEarned)★",
            emoji: "🎉")

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

    /// Show celebration with auto-hide using state change tracking
    /// Note: Using @State to track celebration dismiss via onChange is cleaner than Task {}
    @State private var celebrationDismissID = UUID()

    private func showCelebrationTransient(type: CelebrationType, message: String?, emoji: String?) {
        celebrationType = type
        celebrationMessage = message
        celebrationEmoji = emoji

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showCelebration = true
        }

        // Trigger dismiss after delay
        celebrationDismissID = UUID()
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
