import SwiftUI

struct LevelProgressView: View {
    let level: Int
    let experience: Int
    @State private var progress: Double = 0

    private var experienceForCurrentLevel: Int {
        LevelService.experienceForLevel(level)
    }

    private var experienceForNextLevel: Int {
        LevelService.experienceForLevel(level + 1)
    }

    private var experienceNeeded: Int {
        experienceForNextLevel - experienceForCurrentLevel
    }

    private var experienceInCurrentLevel: Int {
        experience - experienceForCurrentLevel
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Level \(level)")
                    .font(.system(size: AppConstants.titleSize, weight: .bold))
                    .foregroundColor(AppConstants.primaryColor)

                Spacer()

                Text("\(experienceInCurrentLevel)/\(experienceNeeded) XP")
                    .font(.system(size: AppConstants.bodySize))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))

                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                                startPoint: .leading,
                                endPoint: .trailing))
                        .frame(width: geometry.size.width * progress)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(AppConstants.primaryColor.opacity(0.1))
        .cornerRadius(AppConstants.cornerRadius)
        .onAppear {
            updateProgress()
        }
        .onChange(of: experience) { _, _ in
            updateProgress()
        }
        .onChange(of: level) { _, _ in
            updateProgress()
        }
    }

    private func updateProgress() {
        progress = LevelService.progressToNextLevel(
            currentLevel: level,
            currentExperience: experience)
    }
}

struct LevelUpView: View {
    let newLevel: Int
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Confetti effect
            if showConfetti {
                ForEach(0 ..< 40, id: \.self) { index in
                    Text(["🎉", "⭐", "✨", "🎊", "🌟", "💫", "🚀"].randomElement() ?? "🎉")
                        .font(.system(size: 30))
                        .offset(
                            x: CGFloat.random(in: -200 ... 200),
                            y: CGFloat.random(in: -250 ... 250))
                        .opacity(showConfetti ? 1 : 0)
                        .animation(
                            .easeOut(duration: 2.0)
                                .delay(Double(index) * 0.05),
                            value: showConfetti)
                }
            }

            VStack(spacing: 24) {
                Text("LEVEL UP!")
                    .font(.system(size: AppConstants.largeTitleSize, weight: .bold))
                    .foregroundColor(AppConstants.secondaryColor)

                Text("\(newLevel)")
                    .font(.system(size: 100, weight: .bold))
                    .foregroundColor(AppConstants.primaryColor)
                    .scaleEffect(scale)
                    .rotationEffect(.degrees(rotation))

                Text("You've reached level \(newLevel)!")
                    .font(.system(size: AppConstants.titleSize, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                rotation = 360
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            showConfetti = true
        }
    }
}
