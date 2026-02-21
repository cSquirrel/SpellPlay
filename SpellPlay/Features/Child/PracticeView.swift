import AVFoundation
import SwiftData
import SwiftUI

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(TTSService.self) private var ttsService

    let test: SpellingTest

    @State private var practiceSession = PracticeSessionState()
    @State private var practiceService = PracticeService()
    @State private var showFeedback = false
    @State private var lastAnswerWasCorrect = false
    @State private var showingRoundTransition = false
    @State private var nextRoundNumber = 1
    @State private var isInputDisabled = false
    @State private var feedbackTimer: Timer?
    @State private var nextWordTimer: Timer?
    @State private var incorrectAnswer: String = ""
    @State private var correctWord: String = ""
    @State private var feedbackMessage: String = ""
    @State private var showContinueButton = false
    @State private var showAchievementUnlock = false
    @State private var unlockedAchievement: AchievementID?
    @State private var previousComboCount = 0
    @State private var showComboBreakthrough = false
    @State private var hasStartedPractice = false
    @State private var showCancelConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                if practiceSession.isComplete {
                    PracticeSummaryView(
                        roundsCompleted: practiceSession.currentRound,
                        streak: practiceSession.currentStreak,
                        sessionPoints: practiceSession.sessionPoints,
                        totalStars: practiceSession.totalStarsEarned,
                        performanceGrade: practiceSession.performanceGrade,
                        newlyUnlockedAchievements: practiceSession.newlyUnlockedAchievements,
                        levelUpOccurred: practiceSession.levelUpOccurred,
                        newLevel: practiceSession.newLevel,
                        currentLevel: practiceSession.currentLevel,
                        experiencePoints: practiceSession.experiencePoints,
                        onPracticeAgain: {
                            practiceSession.reset()
                            practiceSession.apply(practiceService.setup(test: test, modelContext: modelContext))
                            hasStartedPractice = true
                            Task { @MainActor in
                                try? await Task.sleep(for: .milliseconds(500))
                                if let firstWord = practiceSession.currentWord {
                                    ttsService.speak(firstWord.text, rate: 0.3)
                                }
                            }
                        },
                        onBack: {
                            dismiss()
                        })
                } else if showingRoundTransition {
                    roundTransitionView
                } else {
                    practiceContentView
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if hasStartedPractice, !practiceSession.isComplete {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showCancelConfirmation = true
                        }) {
                            Text("Cancel")
                                .font(.system(size: AppConstants.bodySize))
                                .foregroundColor(.secondary)
                        }
                        .accessibilityIdentifier("Practice_CancelButton")
                    }
                }
            }
            .alert("Cancel Practice?", isPresented: $showCancelConfirmation) {
                Button("Cancel Practice", role: .destructive) {
                    feedbackTimer?.invalidate()
                    nextWordTimer?.invalidate()
                    dismiss()
                }
                Button("Continue", role: .cancel) {}
            } message: {
                Text("Are you sure you want to cancel? Your progress will not be saved.")
            }
            .task(id: test.id) {
                practiceSession.apply(practiceService.setup(test: test, modelContext: modelContext))
                previousComboCount = 0
                hasStartedPractice = true
                try? await Task.sleep(for: .milliseconds(500))
                if let firstWord = practiceSession.currentWord {
                    ttsService.speak(firstWord.text, rate: 0.3)
                }
            }
            .onChange(of: practiceSession.newlyUnlockedAchievements) { oldValue, newValue in
                if let firstAchievement = newValue.first, !oldValue.contains(firstAchievement) {
                    unlockedAchievement = firstAchievement
                    withAnimation {
                        showAchievementUnlock = true
                    }
                }
            }
            .onDisappear {
                feedbackTimer?.invalidate()
                nextWordTimer?.invalidate()
            }
            .errorAlert(errorMessage: $practiceSession.errorMessage)
            .overlay {
                if showComboBreakthrough {
                    CelebrationView(
                        type: .comboBreakthrough,
                        message: "\(practiceSession.comboMultiplier)x Combo!",
                        emoji: "⚡")
                        .transition(.scale.combined(with: .opacity))
                }
                if
                    showAchievementUnlock, let achievementId = unlockedAchievement,
                    let achievement = Achievement.achievement(for: achievementId)
                {
                    AchievementUnlockView(achievement: achievement)
                        .transition(.scale.combined(with: .opacity))
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation {
                                    showAchievementUnlock = false
                                }
                            }
                        }
                }
            }
        }
    }

    private var practiceContentView: some View {
        VStack(spacing: 24) {
            HStack(spacing: 12) {
                PointsDisplayView(points: practiceSession.sessionPoints)
                if practiceSession.comboCount > 0 {
                    ComboIndicatorView(
                        comboCount: practiceSession.comboCount,
                        multiplier: practiceSession.comboMultiplier)
                }
            }
            .padding(.horizontal, AppConstants.padding)
            .padding(.top, AppConstants.padding)

            VStack(spacing: 8) {
                ProgressView(value: practiceSession.progress)
                    .progressViewStyle(.linear)
                    .tint(AppConstants.primaryColor)
                Text(practiceSession.progressText)
                    .font(.system(size: AppConstants.captionSize))
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("Practice_ProgressText")
            }
            .padding(.horizontal, AppConstants.padding)

            Spacer()

            VStack(spacing: 24) {
                if let word = practiceSession.currentWord {
                    HStack(spacing: 16) {
                        Button(action: {
                            ttsService.speak(word.text, rate: 0.3)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                Text("Normal")
                                    .font(.system(size: AppConstants.captionSize, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(AppConstants.primaryColor)
                            .cornerRadius(AppConstants.cornerRadius)
                            .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(ttsService.isSpeaking)

                        Button(action: {
                            ttsService.speak(word.text, rate: 0.1)
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white)
                                Text("Slow")
                                    .font(.system(size: AppConstants.captionSize, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(AppConstants.primaryColor)
                            .cornerRadius(AppConstants.cornerRadius)
                            .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(ttsService.isSpeaking)
                    }
                    .padding(.horizontal, AppConstants.padding)

                    if showFeedback {
                        VStack(spacing: 16) {
                            if lastAnswerWasCorrect {
                                VStack(spacing: 12) {
                                    CelebrationView(type: .wordCorrect)
                                        .transition(.scale.combined(with: .opacity))
                                    if let lastStarCount = practiceSession.starsEarned.last, lastStarCount > 0 {
                                        StarCollectionView(
                                            stars: lastStarCount,
                                            totalStars: practiceSession.totalStarsEarned)
                                            .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            } else {
                                VStack(spacing: 12) {
                                    Text(feedbackMessage.isEmpty ? "Incorrect" : feedbackMessage)
                                        .font(.system(size: AppConstants.titleSize, weight: .bold))
                                        .foregroundColor(AppConstants.errorColor)
                                    VStack(spacing: 8) {
                                        SpellingComparisonView(
                                            userAnswer: incorrectAnswer,
                                            correctWord: correctWord)
                                        Text(correctWord)
                                            .font(.system(size: AppConstants.bodySize, weight: .medium))
                                            .foregroundColor(.secondary)
                                    }
                                    if showContinueButton {
                                        Button(action: {
                                            continueToNext()
                                        }) {
                                            Text("Continue")
                                                .font(.system(size: AppConstants.bodySize, weight: .semibold))
                                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                                .contentShape(Rectangle())
                                        }
                                        .largeButtonStyle(color: AppConstants.primaryColor)
                                        .padding(.top, 8)
                                    }
                                }
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                }
            }

            Spacer()

            if !practiceSession.isRoundComplete, practiceSession.currentWord != nil {
                let isWordComplete = practiceSession.currentWord?.text.matches(practiceSession.userAnswer) ?? false
                Button(action: {
                    practiceSession.useHelpCoin()
                }) {
                    HStack(spacing: 8) {
                        Text("🪙")
                            .font(.system(size: 20))
                        Text("Help (\(practiceSession.availableCoins))")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.orange, lineWidth: 1.5))
                }
                .disabled(practiceSession.availableCoins <= 0 || isInputDisabled || isWordComplete)
                .opacity(practiceSession.availableCoins <= 0 || isWordComplete ? 0.6 : 1)
                .padding(.bottom, 8)
                .accessibilityIdentifier("Practice_HelpCoinButton")
            }

            WordInputView(
                text: $practiceSession.userAnswer,
                onSubmit: {
                    submitAnswer()
                },
                placeholder: "Type the word here",
                isDisabled: isInputDisabled)
                .padding(.horizontal, AppConstants.padding)
                .padding(.bottom, AppConstants.padding)
        }
    }

    private var roundTransitionView: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Round \(nextRoundNumber)")
                    .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                    .foregroundColor(AppConstants.primaryColor)
                    .accessibilityIdentifier("RoundTransition_RoundTitle")
                Text("Misspelled Words")
                    .font(.system(size: AppConstants.titleSize, weight: .semibold))
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("RoundTransition_Subtitle")
            }
            .padding(.top, AppConstants.padding * 2)

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(practiceSession.misspelledWords, id: \.id) { word in
                        HStack {
                            Text(word.text)
                                .font(.system(size: AppConstants.bodySize, weight: .medium))
                                .foregroundColor(.primary)
                                .accessibilityIdentifier("RoundTransition_Word_\(word.text)")
                            Spacer()
                            Button(action: {
                                ttsService.speak(word.text, rate: 0.3)
                            }) {
                                Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppConstants.primaryColor)
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .disabled(ttsService.isSpeaking)
                        }
                        .padding(AppConstants.padding)
                        .background(Color(.systemGray6))
                        .cornerRadius(AppConstants.cornerRadius)
                    }
                }
                .padding(.horizontal, AppConstants.padding)
            }

            Button(action: {
                withAnimation {
                    showingRoundTransition = false
                }
                practiceSession.startNextRound()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(500))
                    if let firstWord = practiceSession.currentWord {
                        ttsService.speak(firstWord.text, rate: 0.3)
                    }
                }
            }) {
                Text("Start Round")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .largeButtonStyle(color: AppConstants.primaryColor)
            .padding(.horizontal, AppConstants.padding)
            .padding(.bottom, AppConstants.padding)
            .accessibilityIdentifier("RoundTransition_StartRoundButton")
        }
    }

    private func submitAnswer() {
        guard let word = practiceSession.currentWord else { return }
        let capturedAnswer = practiceSession.userAnswer
        let previousMultiplier = practiceSession.comboMultiplier

        var hadInitialMistakes = practiceSession.hadInitialMistakes
        let result = practiceService.submitAnswer(
            word: word,
            answer: capturedAnswer,
            currentWordIndex: practiceSession.currentWordIndex,
            wordsInCurrentRound: practiceSession.wordsInCurrentRound,
            roundResults: practiceSession.roundResults,
            wordsMastered: practiceSession.wordsMastered,
            comboCount: practiceSession.comboCount,
            wordStartTime: practiceSession.wordStartTime,
            hadInitialMistakes: &hadInitialMistakes)

        practiceSession.apply(result, wordId: word.id, hadInitialMistakes: hadInitialMistakes)

        lastAnswerWasCorrect = result.isCorrect
        if result.isCorrect, practiceSession.comboMultiplier > previousMultiplier {
            showComboBreakthrough = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showComboBreakthrough = false
            }
        }

        isInputDisabled = true

        if result.isCorrect {
            withAnimation {
                showFeedback = true
                showContinueButton = false
            }
            feedbackTimer?.invalidate()
            feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                continueToNext()
            }
        } else {
            incorrectAnswer = capturedAnswer
            correctWord = word.text
            let similarity = word.text.similarityPercentage(to: capturedAnswer)
            feedbackMessage = FeedbackMessages.getFeedbackMessage(for: similarity)
            withAnimation {
                showFeedback = true
                showContinueButton = true
            }
        }

        if result.allWordsMastered {
            let completeResult = practiceService.completePractice(
                words: practiceSession.words,
                wordsMastered: practiceSession.wordsMastered,
                correctAnswers: practiceSession.correctAnswers,
                roundResults: practiceSession.roundResults,
                sessionPoints: practiceSession.sessionPoints,
                totalStarsEarned: practiceSession.totalStarsEarned,
                initialCoins: practiceSession.initialCoins,
                availableCoins: practiceSession.availableCoins,
                hadInitialMistakes: practiceSession.hadInitialMistakes,
                roundStartTime: practiceSession.roundStartTime,
                modelContext: modelContext,
                onError: { practiceSession.errorMessage = $0 })
            practiceSession.apply(completeResult)
        }
    }

    private func continueToNext() {
        withAnimation {
            showFeedback = false
            showContinueButton = false
        }
        feedbackMessage = ""
        isInputDisabled = false

        if practiceSession.isRoundComplete, !practiceSession.allWordsMastered {
            nextRoundNumber = practiceSession.currentRound + 1
            withAnimation {
                showingRoundTransition = true
            }
        } else if !practiceSession.isComplete, let nextWord = practiceSession.currentWord {
            let nextWordText = nextWord.text
            nextWordTimer?.invalidate()
            nextWordTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                ttsService.speak(nextWordText, rate: 0.3)
            }
        }
    }
}
