import SwiftData
import SwiftUI

struct EditTestView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let test: SpellingTest

    @State private var testName: String
    @State private var helpCoins: Int
    @State private var wordText = ""
    @State private var words: [Word]
    @State private var selectedWordForTTS: Word?
    @State private var errorMessage: String?

    @State private var ttsService = TTSService()

    init(test: SpellingTest) {
        self.test = test
        _testName = State(initialValue: test.name)
        _helpCoins = State(initialValue: test.helpCoins)
        // Sort words by displayOrder, fallback to createdAt for existing words without displayOrder
        let sortedWords = (test.words ?? []).sortedAsCreated()
        _words = State(initialValue: sortedWords)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Test Name") {
                    TextField("Enter test name", text: $testName)
                        .font(.system(size: AppConstants.bodySize))
                        .accessibilityIdentifier("EditTest_TestNameField")
                }

                Section("Settings") {
                    Stepper("Help Coins: \(helpCoins)", value: $helpCoins, in: 0 ... 10)
                        .accessibilityIdentifier("EditTest_HelpCoinsStepper")

                    Text("Number of hints available during the test.")
                        .font(.system(size: AppConstants.captionSize))
                        .foregroundColor(.secondary)
                }

                Section("Add Words") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextEditor(text: $wordText)
                            .frame(height: 120)
                            .font(.system(size: AppConstants.bodySize))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppConstants.cornerRadius)
                                    .stroke(Color(.systemGray4), lineWidth: 1))
                            .accessibilityIdentifier("EditTest_WordTextEditor")

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
                        .accessibilityIdentifier("EditTest_AddWordsButton")
                    }
                }

                if !words.isEmpty {
                    Section("Words (\(words.count))") {
                        ForEach(Array(words.enumerated()), id: \.element.id) { index, word in
                            HStack(spacing: 12) {
                                Text(word.text)
                                    .font(.system(size: AppConstants.bodySize))
                                    .accessibilityIdentifier("EditTest_Word_\(word.text)")

                                Spacer()

                                Button(action: {
                                    selectedWordForTTS = word
                                    ttsService.speak(word.text)
                                }) {
                                    Image(systemName: ttsService.isSpeaking && selectedWordForTTS?.id == word
                                        .id ? "speaker.wave.2.fill" : "speaker.wave.2")
                                        .foregroundColor(AppConstants.primaryColor)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                                .contentShape(Rectangle())
                                .accessibilityLabel("Play pronunciation for \(word.text)")
                                .accessibilityHint("Double tap to hear the word")

                                Button(action: {
                                    modelContext.delete(word)
                                    words.remove(at: index)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(AppConstants.errorColor)
                                        .font(.system(size: 18))
                                }
                                .buttonStyle(.plain)
                                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                                .contentShape(Rectangle())
                                .accessibilityLabel("Remove \(word.text) from list")
                                .accessibilityHint("Double tap to remove this word")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Edit Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .accessibilityIdentifier("EditTest_CancelButton")
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTest()
                    }
                    .fontWeight(.semibold)
                    .accessibilityIdentifier("EditTest_SaveButton")
                }
            }
            .errorAlert(errorMessage: $errorMessage) {
                saveTest()
            }
        }
    }

    private func addWords() {
        let text = wordText
        let newWordTexts = text.splitIntoWords()

        // Get the highest displayOrder from existing words, or use count as fallback
        let maxDisplayOrder = words.map(\.displayOrder).max() ?? (words.count - 1)

        // Ensure words array is initialized
        if test.words == nil {
            test.words = []
        }

        for (offset, wordText) in newWordTexts.enumerated() {
            let word = Word(text: wordText, displayOrder: maxDisplayOrder + 1 + offset)
            word.test = test
            test.words?.append(word)
            words.append(word)
        }

        // Re-sort words by displayOrder
        words = words.sortedAsCreated()

        wordText = ""
    }

    private func saveTest() {
        test.name = testName
        test.helpCoins = helpCoins

        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Unable to save test. Please try again."
        }
    }
}
