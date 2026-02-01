import SwiftUI

enum CelebrationType {
    case wordCorrect
    case comboBreakthrough
    case perfectRound
    case achievement
    case levelUp
    case sessionComplete
}

struct CelebrationView: View {
    let type: CelebrationType
    let message: String?
    let emoji: String?

    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0

    init(type: CelebrationType = .wordCorrect, message: String? = nil, emoji: String? = nil) {
        self.type = type
        self.message = message
        self.emoji = emoji
    }

    var body: some View {
        ZStack {
            // Confetti effect using emojis
            if showConfetti {
                ForEach(0 ..< confettiCount, id: \.self) { index in
                    Text(confettiEmojis.randomElement() ?? "🎉")
                        .font(.system(size: confettiSize))
                        .offset(
                            x: CGFloat.random(in: -150 ... 150),
                            y: CGFloat.random(in: -200 ... 200))
                        .opacity(showConfetti ? 1 : 0)
                        .animation(
                            .easeOut(duration: confettiDuration)
                                .delay(Double(index) * 0.05),
                            value: showConfetti)
                }
            }

            VStack(spacing: 16) {
                Text(displayEmoji)
                    .font(.system(size: emojiSize))
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))

                if let message = displayMessage {
                    Text(message)
                        .font(.system(size: AppConstants.titleSize, weight: .bold))
                        .foregroundColor(messageColor)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 360
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            await MainActor.run {
                showConfetti = true
            }
        }
    }

    private var displayEmoji: String {
        if let emoji {
            return emoji
        }

        switch type {
        case .wordCorrect:
            return "✓"
        case .comboBreakthrough:
            return "⚡"
        case .perfectRound:
            return "⭐"
        case .achievement:
            return "🏆"
        case .levelUp:
            return "🚀"
        case .sessionComplete:
            return "🎉"
        }
    }

    private var displayMessage: String? {
        if let message {
            return message
        }

        switch type {
        case .wordCorrect:
            return "Correct!"
        case .comboBreakthrough:
            return "Combo!"
        case .perfectRound:
            return "Perfect Round!"
        case .achievement:
            return "Achievement Unlocked!"
        case .levelUp:
            return "Level Up!"
        case .sessionComplete:
            return "Great Job!"
        }
    }

    private var messageColor: Color {
        switch type {
        case .wordCorrect:
            AppConstants.successColor
        case .comboBreakthrough:
            .yellow
        case .perfectRound:
            Color(red: 1.0, green: 0.84, blue: 0.0) // Gold
        case .achievement:
            AppConstants.secondaryColor
        case .levelUp:
            AppConstants.primaryColor
        case .sessionComplete:
            AppConstants.successColor
        }
    }

    private var confettiEmojis: [String] {
        switch type {
        case .wordCorrect:
            ["✨", "⭐"]
        case .comboBreakthrough:
            ["⚡", "✨", "💫"]
        case .perfectRound:
            ["⭐", "🌟", "✨", "🎉"]
        case .achievement:
            ["🏆", "🎉", "⭐", "✨", "🌟"]
        case .levelUp:
            ["🚀", "🎉", "⭐", "✨", "🌟", "💫"]
        case .sessionComplete:
            ["🎉", "⭐", "✨", "🎊", "🌟"]
        }
    }

    private var confettiCount: Int {
        switch type {
        case .wordCorrect:
            10
        case .comboBreakthrough:
            15
        case .perfectRound:
            25
        case .achievement:
            30
        case .levelUp:
            40
        case .sessionComplete:
            20
        }
    }

    private var confettiSize: CGFloat {
        switch type {
        case .wordCorrect:
            20
        case .comboBreakthrough:
            25
        case .perfectRound:
            30
        case .achievement:
            30
        case .levelUp:
            30
        case .sessionComplete:
            30
        }
    }

    private var confettiDuration: Double {
        switch type {
        case .wordCorrect:
            1.0
        case .comboBreakthrough:
            1.5
        case .perfectRound:
            2.0
        case .achievement:
            2.0
        case .levelUp:
            2.0
        case .sessionComplete:
            1.5
        }
    }

    private var emojiSize: CGFloat {
        switch type {
        case .wordCorrect:
            60
        case .comboBreakthrough:
            70
        case .perfectRound:
            80
        case .achievement:
            80
        case .levelUp:
            100
        case .sessionComplete:
            80
        }
    }
}
