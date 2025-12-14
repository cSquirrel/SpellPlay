//
//  WordReviewView.swift
//  WordCraft
//
//  Created on [Date]
//

import SwiftUI
import SwiftData

@MainActor
struct WordReviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let test: SpellingTest
    
    @State private var showPractice = false
    
    // Words sorted by displayOrder to preserve entry order
    private var sortedWords: [Word] {
        test.words.sortedAsCreated()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Words list
                    ScrollView {
                        VStack(spacing: 16) {
                            // Title
                            Text("Words to Practice")
                                .font(.system(size: AppConstants.titleSize, weight: .semibold))
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, AppConstants.padding)
                                .padding(.top, AppConstants.padding)
                                .accessibilityIdentifier("WordReview_Title")
                            
                            // Words
                            LazyVStack(spacing: 12) {
                                ForEach(sortedWords) { word in
                                    HStack {
                                        Text(word.text)
                                            .font(.system(size: AppConstants.bodySize, weight: .medium))
                                            .foregroundColor(.primary)
                                        
                                        Spacer()
                                    }
                                    .padding(AppConstants.padding)
                                    .background(AppConstants.cardColor)
                                    .cornerRadius(AppConstants.cornerRadius)
                                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                                }
                            }
                            .padding(.horizontal, AppConstants.padding)
                        }
                    }
                    
                    // Start button
                    Button(action: {
                        showPractice = true
                    }) {
                        Text("Start")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                    }
                    .largeButtonStyle(color: AppConstants.primaryColor)
                    .padding(.horizontal, AppConstants.padding)
                    .padding(.bottom, AppConstants.padding)
                    .accessibilityIdentifier("WordReview_StartButton")
                }
            }
            .navigationTitle(test.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("WordReview_CloseButton")
                }
            }
            .fullScreenCover(isPresented: $showPractice) {
                PracticeView(test: test)
            }
        }
    }
}
