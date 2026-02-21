import SwiftData
import SwiftUI

/// Mode for the unified test card: parent (Edit/Delete) or child (Play).
enum TestCardMode {
    case parent(onEdit: () -> Void, onDelete: () -> Void)
    case child(onStart: () -> Void)
}

/// Single configurable card for spelling tests in parent and child home views.
struct TestCardView: View {
    let test: SpellingTest
    let mode: TestCardMode

    /// Uses cached DateFormatter (#16) for "last practiced" display.
    private var lastPracticedText: String {
        if let lastDate = test.lastPracticed {
            lastDate.mediumFormatted
        } else {
            "Never"
        }
    }

    private var wordCount: Int {
        (test.words ?? []).count
    }

    var body: some View {
        switch mode {
        case let .parent(onEdit, onDelete):
            parentCard(onEdit: onEdit, onDelete: onDelete)
        case let .child(onStart):
            childCard(onStart: onStart)
        }
    }

    // MARK: - Parent mode: two separate buttons (Edit, Delete)

    private func parentCard(onEdit: @escaping () -> Void, onDelete: @escaping () -> Void) -> some View {
        HStack {
            cardContent(showIconRow: false)

            Spacer()

            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 18))
                        .foregroundColor(AppConstants.primaryColor)
                }
                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                .accessibilityLabel("Edit")
                .accessibilityIdentifier("TestCard_Edit_\(test.name)")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 18))
                        .foregroundColor(AppConstants.errorColor)
                }
                .frame(width: AppConstants.minimumTouchTarget, height: AppConstants.minimumTouchTarget)
                .accessibilityLabel("Delete")
                .accessibilityIdentifier("TestCard_Delete_\(test.name)")
            }
        }
        .padding(AppConstants.padding)
        .cardStyle()
        .accessibilityIdentifier("TestCard_\(test.name)")
        .accessibilityElement(children: .combine)
    }

    // MARK: - Child mode: entire card is one button (Play)

    private func childCard(onStart: @escaping () -> Void) -> some View {
        Button(action: onStart) {
            cardContent(showIconRow: true)
                .padding(AppConstants.padding)
                .cardStyle()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("TestCard_\(test.name)")
        .accessibilityLabel(test.name)
        .accessibilityHint("Play")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Shared content

    @ViewBuilder
    private func cardContent(showIconRow: Bool) -> some View {
        VStack(alignment: .leading, spacing: showIconRow ? 12 : 8) {
            if showIconRow {
                HStack {
                    Image(systemName: "book.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppConstants.secondaryColor)

                    Spacer()

                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(AppConstants.primaryColor)
                }
            }

            Text(test.name)
                .font(.system(
                    size: showIconRow ? AppConstants.titleSize : AppConstants.bodySize,
                    weight: showIconRow ? .bold : .semibold))
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("\(wordCount) words")
                .font(.system(size: showIconRow ? AppConstants.bodySize : AppConstants.captionSize))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Last practiced: \(lastPracticedText)")
                .font(.system(size: AppConstants.captionSize))
                .foregroundColor(.secondary)
        }
    }
}
