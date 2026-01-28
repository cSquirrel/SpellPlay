//
//  WordSelectionView.swift
//  SpellPlay
//

import SwiftUI

@MainActor
struct WordSelectionView: View {
    @Environment(\.dismiss) private var dismiss

    let test: SpellingTest

    // Words sorted by displayOrder to preserve entry order
    private var sortedWords: [Word] {
        test.words.sortedAsCreated()
    }

    @State private var selectedWordIds: Set<UUID> = []
    @State private var showGameSelection = false

    private var selectedWords: [Word] {
        sortedWords.filter { selectedWordIds.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppConstants.backgroundColor
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Choose Words to Practice")
                                .font(.system(size: AppConstants.titleSize, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, AppConstants.padding)
                                .padding(.top, AppConstants.padding)
                                .accessibilityIdentifier("WordSelection_Title")

                            // Select All / Deselect All buttons
                            HStack(spacing: 12) {
                                Button {
                                    if selectedWordIds.count == sortedWords.count {
                                        selectedWordIds.removeAll()
                                    } else {
                                        selectedWordIds = Set(sortedWords.map { $0.id })
                                    }
                                } label: {
                                    Text(selectedWordIds.count == sortedWords.count ? "Deselect All" : "Select All")
                                        .font(.system(size: AppConstants.captionSize, weight: .medium))
                                        .foregroundColor(AppConstants.primaryColor)
                                }
                                .accessibilityIdentifier("WordSelection_SelectAllButton")

                                Spacer()

                                Text("\(selectedWordIds.count) of \(sortedWords.count) selected")
                                    .font(.system(size: AppConstants.captionSize))
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, AppConstants.padding)

                            // Word checkboxes
                            LazyVStack(spacing: 8) {
                                ForEach(sortedWords) { word in
                                    wordCheckbox(word: word)
                                }
                            }
                            .padding(.horizontal, AppConstants.padding)
                        }
                    }

                    // Continue button
                    Button(action: {
                        showGameSelection = true
                    }) {
                        Text("Continue")
                            .font(.system(size: AppConstants.bodySize, weight: .semibold))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .contentShape(Rectangle())
                    }
                    .largeButtonStyle(color: selectedWords.isEmpty ? Color.gray : AppConstants.primaryColor)
                    .padding(.horizontal, AppConstants.padding)
                    .padding(.bottom, AppConstants.padding)
                    .disabled(selectedWords.isEmpty)
                    .opacity(selectedWords.isEmpty ? 0.6 : 1.0)
                    .accessibilityIdentifier("WordSelection_ContinueButton")
                }
            }
            .navigationTitle(test.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("Close")
                    .accessibilityIdentifier("WordSelection_CloseButton")
                }
            }
            .onAppear {
                // Select all words by default
                if selectedWordIds.isEmpty {
                    selectedWordIds = Set(sortedWords.map { $0.id })
                }
            }
            .fullScreenCover(isPresented: $showGameSelection) {
                GameSelectionView(test: test, selectedWords: selectedWords)
            }
        }
        .accessibilityIdentifier("WordSelection_Root")
    }

    private func wordCheckbox(word: Word) -> some View {
        Button {
            if selectedWordIds.contains(word.id) {
                selectedWordIds.remove(word.id)
            } else {
                selectedWordIds.insert(word.id)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedWordIds.contains(word.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(selectedWordIds.contains(word.id) ? AppConstants.primaryColor : .gray)

                Text(word.text)
                    .font(.system(size: AppConstants.bodySize, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
            }
            .padding(.horizontal, AppConstants.padding)
            .padding(.vertical, 10)
            .background(selectedWordIds.contains(word.id) ? AppConstants.primaryColor.opacity(0.1) : AppConstants.cardColor)
            .cornerRadius(AppConstants.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                    .stroke(selectedWordIds.contains(word.id) ? AppConstants.primaryColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("WordSelection_Word_\(word.id.uuidString)")
        .accessibilityLabel("\(word.text), \(selectedWordIds.contains(word.id) ? "selected" : "not selected")")
    }
}

