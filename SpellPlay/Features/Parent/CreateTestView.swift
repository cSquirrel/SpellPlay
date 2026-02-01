import SwiftData
import SwiftUI

struct CreateTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var testName = ""
    @State private var helpCoins = 3
    @State private var wordText = ""
    @State private var words: [String] = []
    @State private var showingTTS = false
    @State private var selectedWordForTTS: String?
    @State private var errorMessage: String?

    @State private var ttsService = TTSService()

    var body: some View {
        NavigationStack {
            Form {
                Section("Test Name") {
                    TextField("Enter test name", text: $testName)
                        .font(.system(size: AppConstants.bodySize))
                        .accessibilityIdentifier("CreateTest_TestNameField")
                }

                Section("Settings") {
                    Stepper("Help Coins: \(helpCoins)", value: $helpCoins, in: 0 ... 10)
                        .accessibilityIdentifier("CreateTest_HelpCoinsStepper")

                    Text("Number of hints available during the test.")
                        .font(.system(size: AppConstants.captionSize))
                        .foregroundColor(.secondary)
                }

                Section("Add Words") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: $wordText)
                            .frame(height: 120)
                            .font(.system(size: AppConstants.bodySize))
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                    .stroke(Color(.systemGray4), lineWidth: 1))
                            .accessibilityIdentifier("CreateTest_WordTextEditor")

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
                        .accessibilityIdentifier("CreateTest_AddWordsButton")
                    }
                }

                if !words.isEmpty {
                    Section("Words (\(words.count))") {
                        ForEach(Array(words.enumerated()), id: \.offset) { index, word in
                            HStack(spacing: 12) {
                                Text(word)
                                    .font(.system(size: AppConstants.bodySize))
                                    .accessibilityIdentifier("CreateTest_Word_\(word)")

                                Spacer()

                                Button(action: {
                                    selectedWordForTTS = word
                                    ttsService.speak(word)
                                }) {
                                    Image(systemName: ttsService
                                        .isSpeaking && selectedWordForTTS == word ? "speaker.wave.2.fill" :
                                        "speaker.wave.2")
                                        .foregroundColor(AppConstants.primaryColor)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                                .contentShape(Rectangle())

                                Button(action: {
                                    words.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(AppConstants.errorColor)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                                .contentShape(Rectangle())
                            }
                            .padding(.vertical, 4)
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
                    .accessibilityIdentifier("CreateTest_CancelButton")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTest()
                    }
                    .disabled(testName.isEmpty || words.isEmpty)
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("CreateTest_SaveButton")
                }
            }
            .errorAlert(errorMessage: $errorMessage) {
                saveTest()
            }
        }
    }

    private func addWords() {
        let text = wordText
        let newWords = text.splitIntoWords()
        words.append(contentsOf: newWords)
        words = removeDuplicatesPreservingOrder(words)
        wordText = ""
    }

    /// Removes duplicate words while preserving the original order
    /// - Parameter words: Array of words that may contain duplicates
    /// - Returns: Array with duplicates removed, preserving first occurrence order
    private func removeDuplicatesPreservingOrder(_ words: [String]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for word in words {
            let normalized = word.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if !seen.contains(normalized) {
                seen.insert(normalized)
                result.append(word) // Keep original casing
            }
        }

        return result
    }

    private func saveTest() {
        let test = SpellingTest(name: testName, helpCoins: helpCoins)

        // Ensure words array is initialized
        if test.words == nil {
            test.words = []
        }

        for (index, wordText) in words.enumerated() {
            let word = Word(text: wordText, displayOrder: index)
            test.words?.append(word)
        }

        modelContext.insert(test)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Unable to save test. Please try again."
        }
    }
}
