//
//  PracticeView.swift
//  WordCraft
//
//  Created on [Date]
//

import SwiftUI
import SwiftData
import AVFoundation

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
    @State private var hasStartedPractice = false
    @State private var showCancelConfirmation = false
    
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
                            hasStartedPractice = true
                            // Auto-play first word after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                if let firstWord = viewModel.currentWord {
                                    ttsService.speak(firstWord.text, rate: 0.3)
                                }
                            }
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
            .toolbar {
                // Cancel button - only show when practice has started
                if hasStartedPractice && !viewModel.isComplete {
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
                    // Clean up timers before dismissing
                    feedbackTimer?.invalidate()
                    nextWordTimer?.invalidate()
                    dismiss()
                }
                Button("Continue", role: .cancel) {
                    // Do nothing, just dismiss the alert
                }
            } message: {
                Text("Are you sure you want to cancel? Your progress will not be saved.")
            }
            .onAppear {
                viewModel.setup(test: test, modelContext: modelContext)
                previousComboCount = 0
                hasStartedPractice = true
                // Auto-play first word after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if let firstWord = viewModel.currentWord {
                        ttsService.speak(firstWord.text, rate: 0.3)
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
                    // Audio play buttons - normal and slow speed
                    HStack(spacing: 16) {
                        // Normal speed button
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
                        
                        // Slow speed button (20% speed)
                        Button(action: {
                            // Use a slower rate for 20% speed
                            // Default is ~0.5, so 20% would be ~0.1
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
                viewModel.startNextRound()
                
                // Auto-play first word of new round after a short delay
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
                    Task { @MainActor in
                        if let firstWord = viewModel.currentWord {
                            ttsService.speak(firstWord.text, rate: 0.3)
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
                    ttsService.speak(nextWordText, rate: 0.3)
                }
            }
        }
    }
}

