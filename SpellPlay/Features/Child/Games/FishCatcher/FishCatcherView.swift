import SwiftUI

@MainActor
struct FishCatcherView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [Word]

    @State private var difficulty: GameDifficulty = .easy

    @State private var phase: GamePhase = .ready
    @State private var currentWordIndex = 0
    @State private var nextExpectedIndex = 0

    @State private var activeFish: [Fish] = []
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

    @State private var ttsService = TTSService()

    @State private var bucketBounce: CGFloat = 1.0
    @State private var waveOffset: CGFloat = 0

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
                            title: "Fish Catcher",
                            wordIndex: currentWordIndex,
                            wordCount: words.count,
                            points: score,
                            comboMultiplier: comboMultiplier)

                        wordDisplay
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.top, 10)
                            .accessibilityIdentifier("FishCatcher_WordDisplay")

                        Spacer()

                        // Fish playfield
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

                        // Bucket at bottom
                        bucketView
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.bottom, AppConstants.padding)
                            .accessibilityIdentifier("FishCatcher_Bucket")

                        controls
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.bottom, AppConstants.padding)
                    }

                    if showCelebration {
                        CelebrationView(type: celebrationType, message: celebrationMessage, emoji: celebrationEmoji)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityIdentifier("FishCatcher_Celebration")
                    }
                }
            }
            .navigationTitle("Fish Catcher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("FishCatcher_CloseButton")
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
        }
        .accessibilityIdentifier("FishCatcher_Root")
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
                // Water surface effect
                WaveShape(offset: waveOffset)
                    .fill(Color(red: 0.3, green: 0.6, blue: 0.9).opacity(0.3))
                    .frame(height: 40)
            }
            .onAppear {
                // Animate wave
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
            // Caught letters display
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

            // Bucket/net visual
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
            .accessibilityIdentifier("FishCatcher_DifficultyMenu")
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
        activeFish.removeAll()
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
        Task { @MainActor in
            await startWord()
        }
    }

    // MARK: - Timeline tick / spawning

    private func tick(now: Date, size: CGSize) {
        guard phase == .playing else { return }
        guard !targetText.isEmpty else { return }

        // Remove fish that have left the screen
        activeFish = activeFish.filter { fish in
            fishX(for: fish, size: size, now: now) < size.width + 100
        }

        let interval = spawnInterval(for: difficulty)
        if now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnFish(now: now, size: size)
            lastSpawnAt = now
        }
    }

    private func spawnFish(now: Date, size: CGSize) {
        guard let nextLetter = expectedLetter else { return }

        let letterToUse: Character = if shouldSpawnDecoy(for: difficulty) {
            randomDecoyLetter(avoid: nextLetter) ?? nextLetter
        } else {
            // Spawn the correct next letter more often
            nextLetter
        }

        // Spawn from left side
        let startX: CGFloat = -50

        // Random depth (y position) in the middle portion of the screen
        // Leave room for top UI (~250) and bottom UI (~250)
        let topMargin: CGFloat = 250
        let bottomMargin: CGFloat = 250
        let availableHeight = size.height - topMargin - bottomMargin
        let middleStart = topMargin + (availableHeight * 0.2) // Start 20% into available space
        let middleEnd = topMargin + (availableHeight * 0.8) // End 80% into available space
        let yDepth = CGFloat.random(in: middleStart ... middleEnd)

        let fish = Fish(
            id: UUID(),
            letter: letterToUse,
            startX: startX,
            yDepth: yDepth,
            speed: fishSpeed(for: difficulty),
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
        guard phase == .playing else { return }

        // Remove fish
        activeFish.removeAll { $0.id == fish.id }

        guard let expectedLetter else { return }

        if fish.letter.lowercased() == expectedLetter.lowercased() {
            nextExpectedIndex += 1

            // Animate bucket bounce
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                bucketBounce = 1.2
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5).delay(0.1)) {
                bucketBounce = 1.0
            }

            showCelebrationTransient(type: .wordCorrect, message: nil, emoji: "🐟")

            if nextExpectedIndex >= targetText.count {
                completeWord(now: now)
            }
        } else {
            mistakesThisWord += 1
            totalMistakes += 1
            showCelebrationTransient(type: .comboBreakthrough, message: "Try again", emoji: "💧")
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
            emoji: "🌊")

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

/// Simple wave shape for water surface effect
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
