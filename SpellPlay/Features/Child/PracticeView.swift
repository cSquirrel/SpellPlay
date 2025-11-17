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
    
    @StateObject private var ttsService = TTSService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()
                
                if viewModel.isComplete {
                    PracticeSummaryView(
                        score: viewModel.score,
                        streak: viewModel.currentStreak,
                        onPracticeAgain: {
                            viewModel.reset()
                            viewModel.setup(test: test, modelContext: modelContext)
                        },
                        onBack: {
                            dismiss()
                        }
                    )
                } else {
                    practiceContentView
                }
            }
            .navigationTitle("Practice")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.setup(test: test, modelContext: modelContext)
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
            .padding(.horizontal, AppConstants.padding)
            .padding(.bottom, AppConstants.padding)
        }
    }
    
    private func submitAnswer() {
        guard let word = viewModel.currentWord else { return }
        
        let isCorrect = word.text.matches(viewModel.userAnswer)
        lastAnswerWasCorrect = isCorrect
        
        withAnimation {
            showFeedback = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showFeedback = false
            }
            viewModel.submitAnswer()
            
            // Auto-play next word
            if !viewModel.isComplete, let nextWord = viewModel.currentWord {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    ttsService.speak(nextWord.text)
                }
            }
        }
    }
}

