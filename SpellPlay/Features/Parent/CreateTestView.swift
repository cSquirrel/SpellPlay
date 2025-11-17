//
//  CreateTestView.swift
//  SpellPlay
//
//  Created on [Date]
//

import SwiftUI
import SwiftData

struct CreateTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var testName = ""
    @State private var wordText = ""
    @State private var words: [String] = []
    @State private var showingTTS = false
    @State private var selectedWordForTTS: String?
    
    @StateObject private var ttsService = TTSService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Test Name") {
                    TextField("Enter test name", text: $testName)
                        .font(.system(size: AppConstants.bodySize))
                }
                
                Section("Add Words") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: $wordText)
                            .frame(height: 120)
                            .font(.system(size: AppConstants.bodySize))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        Text("Enter words separated by commas or new lines")
                            .font(.system(size: AppConstants.captionSize))
                            .foregroundColor(.secondary)
                        
                        Button(action: addWords) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Words")
                            }
                        }
                        .disabled(wordText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if !words.isEmpty {
                    Section("Words (\(words.count))") {
                        ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                            HStack {
                                Text(word)
                                    .font(.system(size: AppConstants.bodySize))
                                
                                Spacer()
                                
                                Button(action: {
                                    selectedWordForTTS = word
                                    ttsService.speak(word)
                                }) {
                                    Image(systemName: ttsService.isSpeaking && selectedWordForTTS == word ? "speaker.wave.2.fill" : "speaker.wave.2")
                                        .foregroundColor(AppConstants.primaryColor)
                                }
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                                
                                Button(action: {
                                    words.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(AppConstants.errorColor)
                                }
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Create Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTest()
                    }
                    .disabled(testName.isEmpty || words.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    private func addWords() {
        let text = wordText
        let newWords = text.splitIntoWords()
        words.append(contentsOf: newWords)
        words = Array(Set(words)) // Remove duplicates
        wordText = ""
    }
    
    private func saveTest() {
        let test = SpellingTest(name: testName)
        
        for wordText in words {
            let word = Word(text: wordText)
            test.words.append(word)
        }
        
        modelContext.insert(test)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving test: \(error)")
        }
    }
}

