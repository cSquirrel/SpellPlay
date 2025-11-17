//
//  PracticeView.swift
//  SpellPlay
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
    @State private var wordsRemaining = 0
    @State private var isInputDisabled = false
    @State private var feedbackTimer: Timer?
    @State private var nextWordTimer: Timer?
    
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
            }
            .onDisappear {
                // Clean up timers when view disappears
                feedbackTimer?.invalidate()
                nextWordTimer?.invalidate()
            }
        }
    }
    
    private var practiceContentView: some View {
        VStack(spacing: 32) {
            // Progress indicator
            VStack(spacing: 8) {
                ProgressView(value: viewModel.progress)
                    .progressViewStyle(.linear)
                    .tint(AppConstants.primaryColor)
                
                Text(viewModel.progressText)
                    .font(.system(size: AppConstants.captionSize))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, AppConstants.padding)
            .padding(.top, AppConstants.padding)
            
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
                    
                    // Feedback animation
                    if showFeedback {
                        Text(lastAnswerWasCorrect ? "✓ Correct!" : "✗ Try again")
                            .font(.system(size: AppConstants.titleSize, weight: .bold))
                            .foregroundColor(lastAnswerWasCorrect ? AppConstants.successColor : AppConstants.errorColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            
            Spacer()
            
            // Word input
            WordInputView(
                text: $viewModel.userAnswer,
                onSubmit: {
                    submitAnswer()
                },
                placeholder: "Type the word here"
            )
            .disabled(isInputDisabled)
            .padding(.horizontal, AppConstants.padding)
            .padding(.bottom, AppConstants.padding)
        }
    }
    
    private var roundTransitionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Text("Round \(nextRoundNumber)")
                    .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                    .foregroundColor(AppConstants.primaryColor)
                
                Text("Misspelled Words")
                    .font(.system(size: AppConstants.titleSize, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("\(wordsRemaining) word\(wordsRemaining == 1 ? "" : "s") remaining")
                    .font(.system(size: AppConstants.bodySize))
                    .foregroundColor(.secondary)
            }
            .padding(AppConstants.padding * 2)
            .cardStyle()
            
            Spacer()
        }
        .padding(.horizontal, AppConstants.padding)
        .onAppear {
            // Auto-dismiss after 2.5 seconds and start next round
            Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                Task { @MainActor in
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
                }
            }
        }
    }
    
    private func submitAnswer() {
        guard let word = viewModel.currentWord else { return }
        
        // Capture answer immediately before any delay
        let capturedAnswer = viewModel.userAnswer
        
        // Evaluate correctness immediately
        let isCorrect = word.text.matches(capturedAnswer)
        lastAnswerWasCorrect = isCorrect
        
        // Disable input during feedback animation
        isInputDisabled = true
        
        // Submit the answer immediately with captured value to prevent stale text issues
        viewModel.submitAnswer(with: capturedAnswer)
        
        // Show feedback animation
        withAnimation {
            showFeedback = true
        }
        
        // Cancel any existing timer
        feedbackTimer?.invalidate()
        
        // Wait to hide feedback and move to next word (UX delay for user to see feedback)
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            Task { @MainActor in
                withAnimation {
                    showFeedback = false
                }
                
                // Re-enable input
                isInputDisabled = false
                
                // Check if round is complete but not all words mastered
                if viewModel.isRoundComplete && !viewModel.allWordsMastered {
                    // Show round transition
                    nextRoundNumber = viewModel.currentRound + 1
                    wordsRemaining = viewModel.words.count - viewModel.wordsMastered.count
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
    }
}

