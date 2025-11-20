//
//  PracticeView.swift
//  WordCraft
//
//  Created on [Date]
//

import SwiftUI
import SwiftData

struct PracticeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let test: SpellingTest
    
    @State private var viewModel = PracticeViewModel()
    @State private var showFeedback = false
    @State private var lastAnswerWasCorrect = false
    @State private var showingRoundTransition = false
    @State private var nextRoundNumber = 1
    @State private var isInputDisabled = false
    @State private var feedbackTimer: Timer?
    @State private var nextWordTimer: Timer?
    @State private var incorrectAnswer: String = ""
    @State private var correctWord: String = ""
    @State private var showContinueButton = false
    @State private var showAchievementUnlock = false
    @State private var unlockedAchievement: AchievementID?
    @State private var previousComboCount = 0
    @State private var showComboBreakthrough = false
    
    @StateObject private var ttsService = TTSService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isComplete {
                    PracticeSummaryView(
                        roundsCompleted: viewModel.currentRound,
                        streak: viewModel.currentStreak,
                        sessionPoints: viewModel.sessionPoints,
                        totalStars: viewModel.totalStarsEarned,
                        performanceGrade: viewModel.performanceGrade,
                        newlyUnlockedAchievements: viewModel.newlyUnlockedAchievements,
                        levelUpOccurred: viewModel.levelUpOccurred,
                        newLevel: viewModel.newLevel,
                        currentLevel: viewModel.userProgress?.level ?? 1,
                        experiencePoints: viewModel.userProgress?.experiencePoints ?? 0,
                        onPracticeAgain: {
                            viewModel.reset()
                            viewModel.setup(test: test, modelContext: modelContext)
                        },
                        onBack: {
                            dismiss()
                        }
                    )
                } else if showingRoundTransition {
                    roundTransitionView
                } else {
                    practiceContentView
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setup(test: test, modelContext: modelContext)
                previousComboCount = 0
                
                // Auto-play first word after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let firstWord = viewModel.currentWord {
                        ttsService.speak(firstWord.text)
                    }
                }
            }
            .onChange(of: viewModel.newlyUnlockedAchievements) { oldValue, newValue in
                // Show achievement unlock when new achievements are unlocked
                if let firstAchievement = newValue.first, !oldValue.contains(firstAchievement) {
                    unlockedAchievement = firstAchievement
                    withAnimation {
                        showAchievementUnlock = true
                    }
                }
            }
            .onDisappear {
                // Clean up timers when view disappears
                feedbackTimer?.invalidate()
                nextWordTimer?.invalidate()
            }
            .errorAlert(errorMessage: $viewModel.errorMessage)
            .overlay {
                // Combo breakthrough overlay
                if showComboBreakthrough {
                    CelebrationView(
                        type: .comboBreakthrough,
                        message: "\(viewModel.comboMultiplier)x Combo!",
                        emoji: "⚡"
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                // Achievement unlock overlay
                if showAchievementUnlock, let achievementId = unlockedAchievement,
                   let achievement = Achievement.achievement(for: achievementId) {
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
            // Gamification header
            HStack(spacing: 12) {
                PointsDisplayView(points: viewModel.sessionPoints)
                
                if viewModel.comboCount > 0 {
                    ComboIndicatorView(
                        comboCount: viewModel.comboCount,
                        multiplier: viewModel.comboMultiplier
                    )
                }
            }
            .padding(.horizontal, AppConstants.padding)
            .padding(.top, AppConstants.padding)
            
            // Progress indicator
            VStack(spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .tint(AppConstants.primaryColor)
                
                Text(viewModel.progressText)
                    .font(.system(size: AppConstants.captionSize))
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("Practice_ProgressText")
            }
            .padding(.horizontal, AppConstants.padding)
            
            Spacer()
            
            // Word display and audio
            VStack(spacing: 24) {
                if let word = viewModel.currentWord {
                    // Audio play button
                    Button(action: {
                        ttsService.speak(word.text)
                    }) {
                        VStack(spacing: 12) {
                            Image(systemName: ttsService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Tap to hear the word")
                                .font(.system(size: AppConstants.bodySize, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .frame(width: 200, height: 200)
                        .background(AppConstants.primaryColor)
                        .clipShape(Circle())
                        .shadow(color: AppConstants.primaryColor.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(ttsService.isSpeaking)
                    
                    // Feedback
                    if showFeedback {
                        VStack(spacing: 16) {
                            if lastAnswerWasCorrect {
                                VStack(spacing: 12) {
                                    CelebrationView(type: .wordCorrect)
                                        .transition(.scale.combined(with: .opacity))
                                    
                                    // Show stars earned
                                    if let lastStarCount = viewModel.starsEarned.last, lastStarCount > 0 {
                                        StarCollectionView(
                                            stars: lastStarCount,
                                            totalStars: viewModel.totalStarsEarned
                                        )
                                    .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            } else {
                                // Incorrect answer feedback
                                VStack(spacing: 12) {
                                    Text("Incorrect")
                                        .font(.system(size: AppConstants.titleSize, weight: .bold))
                                        .foregroundColor(AppConstants.errorColor)
                                    
                                    Text(incorrectAnswer)
                                        .font(.system(size: AppConstants.bodySize, weight: .medium))
                                        .foregroundColor(AppConstants.errorColor)
                                    
                                    Text(correctWord)
                                        .font(.system(size: AppConstants.bodySize, weight: .medium))
                                        .foregroundColor(AppConstants.successColor)
                                    
                                    if showContinueButton {
                                        Button(action: {
                                            continueToNext()
                                        }) {
                                            Text("Continue")
                                                .font(.system(size: AppConstants.bodySize, weight: .semibold))
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
            
            // Help Coin Button
            if !viewModel.isRoundComplete && viewModel.currentWord != nil {
                let isWordComplete = viewModel.currentWord?.text.matches(viewModel.userAnswer) ?? false
                
                Button(action: {
                    viewModel.useHelpCoin()
                }) {
                    HStack(spacing: 8) {
                        Text("🪙")
                            .font(.system(size: 20))
                        Text("Help (\(viewModel.availableCoins))")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color.orange, lineWidth: 1.5)
                    )
                }
                .disabled(viewModel.availableCoins <= 0 || isInputDisabled || isWordComplete)
                .opacity(viewModel.availableCoins <= 0 || isWordComplete ? 0.6 : 1)
                .padding(.bottom, 8)
                .accessibilityIdentifier("Practice_HelpCoinButton")
            }
            
            // Word input
            WordInputView(
                text: $viewModel.userAnswer,
                onSubmit: {
                    submitAnswer()
                },
                placeholder: "Type the word here",
                isDisabled: isInputDisabled
            )
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
            
            // List of misspelled words
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.misspelledWords, id: \.id) { word in
                        HStack {
                            Text(word.text)
                                .font(.system(size: AppConstants.bodySize, weight: .medium))
                                .foregroundColor(.primary)
                                .accessibilityIdentifier("RoundTransition_Word_\(word.text)")
                            
                            Spacer()
                            
                            Button(action: {
                                ttsService.speak(word.text)
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
                viewModel.startNextRound()
                
                // Auto-play first word of new round after a short delay
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    Task { @MainActor in
                        if let firstWord = viewModel.currentWord {
                            ttsService.speak(firstWord.text)
                        }
                    }
                }
            }) {
                Text("Start Round")
                    .font(.system(size: AppConstants.bodySize, weight: .semibold))
            }
            .largeButtonStyle(color: AppConstants.primaryColor)
            .padding(.horizontal, AppConstants.padding)
            .padding(.bottom, AppConstants.padding)
            .accessibilityIdentifier("RoundTransition_StartRoundButton")
        }
    }
    
    private func submitAnswer() {
        guard let word = viewModel.currentWord else { return }
        
        // Capture answer immediately before any delay
        let capturedAnswer = viewModel.userAnswer
        
        // Check for combo breakthrough before submitting
        let previousCombo = viewModel.comboCount
        let previousMultiplier = viewModel.comboMultiplier
        
        // Submit the answer and get points result
        let pointsResult = viewModel.submitAnswer(with: capturedAnswer)
        
        // Evaluate correctness
        let isCorrect = word.text.matches(capturedAnswer)
        lastAnswerWasCorrect = isCorrect
        
        // Check for combo breakthrough
        if isCorrect && viewModel.comboMultiplier > previousMultiplier {
            showComboBreakthrough = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                showComboBreakthrough = false
            }
        }
        
        // Disable input during feedback
        isInputDisabled = true
        
        if isCorrect {
            // For correct answers, show feedback and auto-advance
            withAnimation {
                showFeedback = true
                showContinueButton = false
            }
            
            // Cancel any existing timer
            feedbackTimer?.invalidate()
            
            // Wait to hide feedback and move to next word
            feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
                Task { @MainActor in
                    continueToNext()
                }
            }
        } else {
            // For incorrect answers, show detailed feedback with continue button
            incorrectAnswer = capturedAnswer
            correctWord = word.text
            
            withAnimation {
                showFeedback = true
                showContinueButton = true
            }
        }
    }
    
    private func continueToNext() {
        withAnimation {
            showFeedback = false
            showContinueButton = false
        }
        
        // Clear the input field
        viewModel.userAnswer = ""
        
        // Re-enable input
        isInputDisabled = false
        
        // Check if round is complete but not all words mastered
        if viewModel.isRoundComplete && !viewModel.allWordsMastered {
            // Show round transition
            nextRoundNumber = viewModel.currentRound + 1
            withAnimation {
                showingRoundTransition = true
            }
        } else if !viewModel.isComplete, let nextWord = viewModel.currentWord {
            // Auto-play next word after a short delay
            let nextWordText = nextWord.text
            nextWordTimer?.invalidate()
            nextWordTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                Task { @MainActor in
                    ttsService.speak(nextWordText)
                }
            }
        }
    }
}

