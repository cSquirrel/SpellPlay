import SwiftUI

@MainActor
struct RocketLaunchView: View {
    @Environment(\.dismiss) private var dismiss

    let words: [Word]

    @State private var difficulty: GameDifficulty = .easy

    @State private var phase: GamePhase = .ready
    @State private var currentWordIndex = 0
    @State private var typedText: String = ""

    @State private var fuelLevel: Double = 0.0
    @State private var isLaunching: Bool = false
    @State private var rocketOffset: CGFloat = 0
    @State private var countdownValue: Int? = nil

    @State private var mistakesThisWord: Int = 0
    @State private var totalMistakes: Int = 0

    @State private var score = 0
    @State private var comboCount = 0
    @State private var comboMultiplier = 1
    @State private var totalStars = 0

    @State private var wordStartTime: Date?

    @State private var showCelebration = false
    @State private var celebrationType: CelebrationType = .wordCorrect
    @State private var celebrationMessage: String? = nil
    @State private var celebrationEmoji: String? = nil

    @State private var showResult = false
    @State private var result: GameResult?

    @State private var shakeOffset: CGFloat = 0
    @State private var showWordHint = true

    @Environment(TTSService.self) private var ttsService

    /// Used to trigger celebration dismiss via .task(id:)
    @State private var celebrationDismissID = UUID()

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
                    background
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        GameProgressView(
                            title: "Rocket Launch",
                            wordIndex: currentWordIndex,
                            wordCount: words.count,
                            points: score,
                            comboMultiplier: comboMultiplier)

                        missionObjective
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.top, 10)
                            .accessibilityIdentifier("RocketLaunch_WordDisplay")

                        Spacer()

                        // Rocket and fuel gauge area
                        VStack(spacing: 20) {
                            ZStack {
                                // Launch pad background
                                launchPadBackground

                                // Rocket view
                                RocketView(
                                    fuelLevel: fuelLevel,
                                    isLaunching: isLaunching,
                                    verticalOffset: rocketOffset)
                                    .offset(x: shakeOffset)
                                    .accessibilityIdentifier("RocketLaunch_Rocket")
                            }
                            .frame(height: 200)

                            // Fuel gauge
                            fuelGauge
                                .accessibilityIdentifier("RocketLaunch_FuelGauge")
                        }
                        .padding(.horizontal, AppConstants.padding)

                        Spacer()

                        // Countdown overlay
                        if let countdown = countdownValue {
                            Text("\(countdown)")
                                .font(.system(size: 80, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                                .transition(.scale.combined(with: .opacity))
                                .accessibilityIdentifier("RocketLaunch_Countdown")
                        }

                        // Controls above keyboard
                        HStack(spacing: 12) {
                            Button {
                                if let currentWord {
                                    ttsService.speak(currentWord.text, rate: 0.3)
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "speaker.wave.2.fill")
                                    Text("Hear Word")
                                        .font(.system(size: AppConstants.captionSize, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(AppConstants.primaryColor)
                            .disabled(ttsService.isSpeaking || currentWord == nil)
                            .accessibilityIdentifier("RocketLaunch_SpeakWordButton")

                            Menu {
                                Picker("Difficulty", selection: $difficulty) {
                                    ForEach(GameDifficulty.allCases) { d in
                                        Text(d.displayName).tag(d)
                                    }
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "slider.horizontal.3")
                                    Text(difficulty.displayName)
                                        .font(.system(size: AppConstants.captionSize, weight: .semibold))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                            .tint(AppConstants.secondaryColor)
                            .accessibilityIdentifier("RocketLaunch_DifficultyMenu")

                            Spacer()
                        }
                        .padding(.horizontal, AppConstants.padding)
                        .padding(.bottom, 8)

                        // On-screen keyboard
                        onScreenKeyboard
                            .padding(.horizontal, AppConstants.padding)
                            .padding(.bottom, AppConstants.padding)
                    }

                    if showCelebration {
                        CelebrationView(type: celebrationType, message: celebrationMessage, emoji: celebrationEmoji)
                            .transition(.scale.combined(with: .opacity))
                            .accessibilityIdentifier("RocketLaunch_Celebration")
                    }
                }
            }
            .navigationTitle("Rocket Launch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("RocketLaunch_CloseButton")
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
                        title: "Rocket Launch",
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
        .accessibilityIdentifier("RocketLaunch_Root")
    }

    // MARK: - Background

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.3),
                Color(red: 0.2, green: 0.3, blue: 0.5),
                Color(red: 0.4, green: 0.5, blue: 0.7),
            ],
            startPoint: .top,
            endPoint: .bottom)
    }

    private var launchPadBackground: some View {
        VStack(spacing: 0) {
            Spacer()
            // Ground/launch pad
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.3, green: 0.3, blue: 0.3),
                            Color(red: 0.2, green: 0.2, blue: 0.2),
                        ],
                        startPoint: .top,
                        endPoint: .bottom))
                .frame(height: 60)
                .overlay(alignment: .top) {
                    // Launch pad grid pattern
                    HStack(spacing: 8) {
                        ForEach(0 ..< 8, id: \.self) { _ in
                            Rectangle()
                                .fill(Color.white.opacity(0.1))
                                .frame(width: 4, height: 4)
                        }
                    }
                    .padding(.top, 8)
                }
        }
    }

    // MARK: - Mission Objective

    private var missionObjective: some View {
        VStack(spacing: 8) {
            Text("Mission Word")
                .font(.system(size: AppConstants.captionSize, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
                .textCase(.uppercase)

            let letters = Array(targetText)
            HStack(spacing: 8) {
                ForEach(letters.indices, id: \.self) { idx in
                    let isTyped = idx < typedText.count
                    let shouldShow = shouldShowLetter(at: idx)

                    if shouldShow {
                        Text(String(letters[idx]).uppercased())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(isTyped ? .white : Color.white.opacity(0.3))
                            .frame(minWidth: 28)
                    } else {
                        Text("_")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.3))
                            .frame(minWidth: 28)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.2))
            .cornerRadius(AppConstants.cornerRadius)
        }
    }

    private func shouldShowLetter(at index: Int) -> Bool {
        switch difficulty {
        case .easy:
            true // Always show full word
        case .medium:
            showWordHint || index < typedText.count // Show briefly, then hide
        case .hard:
            index < typedText.count // Only show typed letters
        }
    }

    // MARK: - Fuel Gauge

    private var fuelGauge: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Fuel")
                    .font(.system(size: AppConstants.captionSize, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("\(Int(fuelLevel * 100))%")
                    .font(.system(size: AppConstants.captionSize, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.3))

                    // Fuel fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.orange,
                                    Color.yellow,
                                    Color.green,
                                ],
                                startPoint: .leading,
                                endPoint: .trailing))
                        .frame(width: geo.size.width * fuelLevel)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: fuelLevel)
                }
            }
            .frame(height: 24)
        }
    }

    // MARK: - On-Screen Keyboard

    private var onScreenKeyboard: some View {
        VStack(spacing: 8) {
            // QWERTY layout
            let rows = [
                ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
                ["A", "S", "D", "F", "G", "H", "J", "K", "L"],
                ["Z", "X", "C", "V", "B", "N", "M"],
            ]

            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 6) {
                    ForEach(rows[rowIndex], id: \.self) { letter in
                        keyboardKey(letter: letter)
                    }
                }
            }

            // Backspace button
            HStack {
                Button {
                    handleBackspace()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 60, height: 50)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(8)
                }
                .accessibilityLabel("Backspace")
                .accessibilityIdentifier("RocketLaunch_Key_Backspace")
            }
        }
    }

    private func keyboardKey(letter: String) -> some View {
        Button {
            handleKeyTap(letter: Character(letter.lowercased()))
        } label: {
            Text(letter)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 32, height: 50)
                .background(Color.white.opacity(0.2))
                .cornerRadius(8)
        }
        .accessibilityLabel(letter)
        .accessibilityIdentifier("RocketLaunch_Key_\(letter)")
    }

    // MARK: - Game Lifecycle

    private func startGameIfNeeded() {
        guard phase == .ready else { return }
        phase = .playing
        currentWordIndex = 0
        typedText = ""
        fuelLevel = 0.0
        score = 0
        totalStars = 0
        comboCount = 0
        comboMultiplier = 1
        totalMistakes = 0
        mistakesThisWord = 0
        showWordHint = true
    }

    private func startWord() async {
        guard phase == .playing else { return }
        guard currentWord != nil else { return }

        // Reset per-word state
        typedText = ""
        fuelLevel = 0.0
        mistakesThisWord = 0
        wordStartTime = Date()
        isLaunching = false
        rocketOffset = 0
        countdownValue = nil
        shakeOffset = 0
        showWordHint = true

        // Small delay to let UI settle, then speak
        try? await Task.sleep(for: .milliseconds(250))
        if let currentWord {
            ttsService.speak(currentWord.text, rate: 0.3)
        }

        // Hide word hint after delay (for medium/hard difficulty)
        if difficulty != .easy {
            try? await Task.sleep(for: .seconds(2))
            withAnimation {
                showWordHint = false
            }
        }
    }

    private func resetAll() {
        showResult = false
        result = nil
        phase = .ready
        startGameIfNeeded()
        // Note: startWord will be called automatically via .task(id: currentWordIndex)
    }

    // MARK: - Input Handling

    private func handleKeyTap(letter: Character) {
        guard phase == .playing else { return }
        guard !isLaunching else { return }
        guard typedText.count < targetText.count else { return }

        let expectedLetter = Array(targetText.lowercased())[typedText.count]

        if letter == expectedLetter {
            // Correct letter
            typedText.append(letter)
            fuelLevel = Double(typedText.count) / Double(targetText.count)

            // Rumble effect
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = 2
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                    shakeOffset = -2
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                    shakeOffset = 0
                }
            }

            showCelebrationTransient(type: .wordCorrect, message: nil, emoji: "✨")

            // Check if word is complete
            if typedText.count >= targetText.count {
                triggerLaunch()
            }
        } else {
            // Wrong letter
            mistakesThisWord += 1
            totalMistakes += 1

            // Shake animation
            withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                shakeOffset = -10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                    shakeOffset = 10
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.2)) {
                    shakeOffset = 0
                }
            }

            showCelebrationTransient(type: .comboBreakthrough, message: "Try again", emoji: "💭")
        }
    }

    private func handleBackspace() {
        guard phase == .playing else { return }
        guard !isLaunching else { return }
        guard !typedText.isEmpty else { return }

        typedText.removeLast()
        fuelLevel = Double(typedText.count) / Double(targetText.count)
    }

    // MARK: - Launch Sequence

    private func triggerLaunch() {
        guard !isLaunching else { return }
        isLaunching = true

        // Countdown
        Task { @MainActor in
            for i in (1 ... 3).reversed() {
                countdownValue = i
                try? await Task.sleep(for: .milliseconds(600))
            }
            countdownValue = nil

            // Launch animation
            withAnimation(.easeIn(duration: 2.0)) {
                rocketOffset = -UIScreen.main.bounds.height - 200
            }

            // Complete word after animation
            try? await Task.sleep(for: .milliseconds(2100))
            completeWord()
        }
    }

    private func completeWord() {
        let timeTaken = wordStartTime.map { Date().timeIntervalSince($0) }

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
            emoji: "🚀")

        // Reset rocket position and advance
        rocketOffset = 0
        isLaunching = false

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

        // Trigger dismiss via .task(id:)
        celebrationDismissID = UUID()
    }
}
