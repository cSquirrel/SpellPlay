//
//  FallingStarsView.swift
//  SpellPlay
//
//  Falling Stars interactive spelling game
//

import SwiftUI

@MainActor
struct FallingStarsView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [Word]

    @State private var difficulty: GameDifficulty = .easy

    @State private var phase: GamePhase = .ready
    @State private var currentWordIndex = 0
    @State private var nextExpectedIndex = 0

    @State private var activeStars: [Star] = []
    @State private var lastSpawnAt: Date = .distantPast
    @State private var constellationPoints: [CGPoint] = []

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

    @StateObject private var ttsService = TTSService()

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
                    nightSkyBackground
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameProgressView(
                            title: "Falling Stars",
                            wordIndex: currentWordIndex,
                            wordCount: words.count,
                            points: score,
                            comboMultiplier: comboMultiplier
                        )

                        wordDisplay
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.top, 10)
                            .accessibilityIdentifier("FallingStars_WordDisplay")

                        Spacer()

                        // Star playfield with constellation overlay
                        ZStack {
                            // Constellation lines
                            constellationPath
                                .stroke(Color.yellow.opacity(0.6), lineWidth: 3)
                                .shadow(color: .yellow.opacity(0.4), radius: 8)
                            
                            // Constellation points
                            ForEach(constellationPoints.indices, id: \.self) { idx in
                                Circle()
                                    .fill(Color.yellow)
                                    .frame(width: 8, height: 8)
                                    .position(constellationPoints[idx])
                                    .shadow(color: .yellow.opacity(0.6), radius: 6)
                            }

                            // Falling stars
                            TimelineView(.animation) { context in
                                ZStack {
                                    ForEach(visibleStars(in: geo.size, now: context.date)) { star in
                                        StarView(letter: star.letter, id: star.id) {
                                            handleTap(star: star, now: context.date, size: geo.size)
                                        }
                                        .position(
                                            x: star.startX,
                                            y: starY(for: star, size: geo.size, now: context.date)
                                        )
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

                    if showCelebration {
                        CelebrationView(type: celebrationType, message: celebrationMessage, emoji: celebrationEmoji)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityIdentifier("FallingStars_Celebration")
                    }
                }
            }
            .navigationTitle("Falling Stars")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("FallingStars_CloseButton")
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
                        title: "Falling Stars",
                        result: result,
                        onPlayAgain: {
                            resetAll()
                        },
                        onChooseDifferentGame: {
                            dismiss()
                        }
                    )
                }
            }
        }
        .accessibilityIdentifier("FallingStars_Root")
    }

    // MARK: - Background

    private var nightSkyBackground: some View {
        ZStack {
            // Gradient night sky
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.15, green: 0.1, blue: 0.3),
                    Color(red: 0.2, green: 0.15, blue: 0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Twinkling background stars
            TimelineView(.animation) { timelineContext in
                Canvas { graphicsContext, size in
                    let time = timelineContext.date.timeIntervalSince1970
                    let starCount = 50
                    
                    for i in 0..<starCount {
                        // Use a seed based on index for stable positions
                        var generator = SeededRandomNumberGenerator(seed: UInt64(i))
                        let x = CGFloat.random(in: 0...size.width, using: &generator)
                        let y = CGFloat.random(in: 0...size.height, using: &generator)
                        
                        // Twinkle effect: opacity oscillates
                        let twinklePhase = (time + Double(i) * 0.3).truncatingRemainder(dividingBy: 4.0)
                        let opacity = 0.3 + (sin(twinklePhase) * 0.4)
                        
                        graphicsContext.fill(
                            Path(ellipseIn: CGRect(x: x, y: y, width: 2, height: 2)),
                            with: .color(.white.opacity(opacity))
                        )
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
        for i in 1..<constellationPoints.count {
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
                .stroke(Color.yellow.opacity(0.3), lineWidth: 2)
        )
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
            .accessibilityIdentifier("FallingStars_DifficultyMenu")
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
        activeStars.removeAll()
        constellationPoints.removeAll()
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

        // Remove stars that have faded or left the screen
        activeStars = activeStars.filter { star in
            let elapsed = now.timeIntervalSince(star.spawnTime)
            let y = starY(for: star, size: size, now: now)
            return elapsed < star.lifetime && y < size.height + 100
        }

        let interval = spawnInterval(for: difficulty)
        if now.timeIntervalSince(lastSpawnAt) >= interval {
            spawnStar(now: now, size: size)
            lastSpawnAt = now
        }
    }

    private func spawnStar(now: Date, size: CGSize) {
        guard let nextLetter = expectedLetter else { return }

        let letterToUse: Character
        if shouldSpawnDecoy(for: difficulty) {
            letterToUse = randomDecoyLetter(avoid: nextLetter) ?? nextLetter
        } else {
            // Spawn the correct next letter more often
            letterToUse = nextLetter
        }

        let x = CGFloat.random(in: 60...(max(61, size.width - 60)))
        let yStart: CGFloat = -60

        let star = Star(
            id: UUID(),
            letter: letterToUse,
            startX: x,
            startY: yStart,
            fallSpeed: fallSpeed(for: difficulty),
            spawnTime: now,
            lifetime: starLifetime(for: difficulty)
        )

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
        guard phase == .playing else { return }

        // Capture position for constellation before removing
        let currentY = starY(for: star, size: size, now: now)
        let tapPosition = CGPoint(x: star.startX, y: currentY)

        // Remove star
        activeStars.removeAll { $0.id == star.id }

        guard let expectedLetter else { return }

        if star.letter.lowercased() == expectedLetter.lowercased() {
            nextExpectedIndex += 1
            // Add to constellation
            constellationPoints.append(tapPosition)
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
            isFirstTry: mistakesThisWord == 0
        )
        score += pointsResult.totalPoints

        let starsEarned: Int
        if mistakesThisWord == 0, let t = timeTaken, t <= PointsService.speedBonusThreshold {
            starsEarned = 3
        } else if mistakesThisWord == 0 {
            starsEarned = 2
        } else {
            starsEarned = 1
        }
        totalStars += starsEarned

        showCelebrationTransient(
            type: .sessionComplete,
            message: "Star Collector! +\(pointsResult.totalPoints) pts • \(starsEarned)★",
            emoji: "⭐"
        )

        advanceToNextWord()
    }

    private func advanceToNextWord() {
        if currentWordIndex >= words.count - 1 {
            phase = .gameComplete
            result = GameResult(
                totalPoints: score,
                totalStars: totalStars,
                wordsCompleted: words.count,
                totalMistakes: totalMistakes
            )
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
        let roll = Double.random(in: 0...1)
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
        self.state = seed
    }

    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}

