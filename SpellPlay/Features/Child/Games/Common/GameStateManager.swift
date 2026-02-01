//
//  GameStateManager.swift
//  SpellPlay
//
//  Centralized game state management for all spelling games
//  Eliminates code duplication across game views
//

import SwiftUI

/// Observable game state manager that centralizes common game state and logic
/// Used by all game views (BalloonPop, FallingStars, FishCatcher, WordBuilder, RocketLaunch)
@Observable
@MainActor
final class GameStateManager {
    // MARK: - Word Progress State
    
    /// All words to practice in this game session
    private(set) var words: [Word] = []
    
    /// Current word index
    var currentWordIndex: Int = 0
    
    /// Current game phase
    var phase: GamePhase = .ready
    
    /// Selected difficulty level
    var difficulty: GameDifficulty = .easy
    
    // MARK: - Score State
    
    /// Total points earned in this session
    var score: Int = 0
    
    /// Current combo count (consecutive correct answers)
    var comboCount: Int = 0
    
    /// Current combo multiplier
    var comboMultiplier: Int = 1
    
    /// Total stars earned
    var totalStars: Int = 0
    
    /// Total mistakes made
    var totalMistakes: Int = 0
    
    /// Mistakes on current word
    var mistakesThisWord: Int = 0
    
    // MARK: - Timing State
    
    /// Start time for current word (for speed bonus calculation)
    var wordStartTime: Date?
    
    // MARK: - Celebration State
    
    /// Whether to show celebration overlay
    var showCelebration: Bool = false
    
    /// Type of celebration to show
    var celebrationType: CelebrationType = .wordCorrect
    
    /// Custom celebration message
    var celebrationMessage: String?
    
    /// Custom celebration emoji
    var celebrationEmoji: String?
    
    // MARK: - Result State
    
    /// Whether to show result screen
    var showResult: Bool = false
    
    /// Final game result
    var result: GameResult?
    
    // MARK: - Computed Properties
    
    /// Current word being practiced
    var currentWord: Word? {
        guard currentWordIndex < words.count else { return nil }
        return words[currentWordIndex]
    }
    
    /// Target text for current word
    var targetText: String {
        currentWord?.text ?? ""
    }
    
    /// Whether all words have been completed
    var isComplete: Bool {
        currentWordIndex >= words.count
    }
    
    /// Progress as fraction (0.0 to 1.0)
    var progress: Double {
        guard !words.isEmpty else { return 0 }
        return Double(currentWordIndex) / Double(words.count)
    }
    
    // MARK: - Initialization
    
    init() {}
    
    /// Initialize game with words
    func setup(words: [Word]) {
        self.words = words
        reset()
    }
    
    /// Reset game to initial state
    func reset() {
        currentWordIndex = 0
        phase = .ready
        score = 0
        comboCount = 0
        comboMultiplier = 1
        totalStars = 0
        totalMistakes = 0
        mistakesThisWord = 0
        wordStartTime = nil
        showCelebration = false
        showResult = false
        result = nil
    }
    
    // MARK: - Word Progression
    
    /// Start timing for the current word
    func startWordTimer() {
        wordStartTime = Date()
        mistakesThisWord = 0
    }
    
    /// Handle a correct answer
    func handleCorrectAnswer() {
        // Calculate time taken
        let timeTaken = wordStartTime.map { Date().timeIntervalSince($0) }
        
        // Increment combo
        comboCount += 1
        comboMultiplier = PointsService.getComboMultiplier(for: comboCount)
        
        // Calculate points
        let pointsResult = PointsService.calculatePoints(
            isCorrect: true,
            comboCount: comboCount,
            timeTaken: timeTaken,
            isFirstTry: mistakesThisWord == 0
        )
        
        score += pointsResult.totalPoints
        
        // Calculate stars (1-3 based on performance)
        let stars: Int
        if let time = timeTaken, time <= PointsService.speedBonusThreshold && mistakesThisWord == 0 {
            stars = 3
        } else if mistakesThisWord == 0 {
            stars = 2
        } else {
            stars = 1
        }
        totalStars += stars
    }
    
    /// Handle an incorrect answer
    func handleIncorrectAnswer() {
        // Reset combo
        comboCount = 0
        comboMultiplier = 1
        
        // Track mistakes
        mistakesThisWord += 1
        totalMistakes += 1
    }
    
    /// Move to next word
    func advanceToNextWord() {
        currentWordIndex += 1
        mistakesThisWord = 0
        
        if isComplete {
            phase = .gameComplete
        }
    }
    
    // MARK: - Celebration
    
    /// Show celebration with specified type
    func showCelebration(type: CelebrationType, message: String? = nil, emoji: String? = nil) {
        celebrationType = type
        celebrationMessage = message
        celebrationEmoji = emoji
        showCelebration = true
    }
    
    /// Hide celebration
    func hideCelebration() {
        showCelebration = false
    }
    
    // MARK: - Result
    
    /// Calculate and show final result
    func calculateResult() -> GameResult {
        let gameResult = GameResult(
            totalPoints: score,
            totalStars: totalStars,
            wordsCompleted: currentWordIndex,
            totalMistakes: totalMistakes
        )
        self.result = gameResult
        return gameResult
    }
    
    /// Show result screen with current result
    func showResultScreen() {
        _ = calculateResult()
        showResult = true
    }
    
    // MARK: - Difficulty Helpers
    
    /// Get spawn interval based on difficulty (for games with spawning elements)
    var spawnInterval: TimeInterval {
        switch difficulty {
        case .easy: return 1.2
        case .medium: return 0.9
        case .hard: return 0.6
        }
    }
    
    /// Get movement speed based on difficulty
    var movementSpeed: Double {
        switch difficulty {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }
}

