import AVFoundation
import Foundation

/// Text-to-Speech service that manages speech synthesis
/// Uses @Observable for efficient SwiftUI observation
@Observable
@MainActor
final class TTSService: NSObject, AVSpeechSynthesizerDelegate {
    private let synthesizer: AVSpeechSynthesizer
    private var currentUtterance: AVSpeechUtterance?

    /// Whether speech is currently in progress
    var isSpeaking = false

    /// Whether TTS is available on this device
    var isAvailable = true

    override init() {
        let synth = AVSpeechSynthesizer()
        synthesizer = synth
        super.init()
        checkAvailability()
        synth.delegate = self
    }

    private func checkAvailability() {
        // TTS is generally available on iOS devices
        isAvailable = true
    }

    /// Speak the given text with optional rate and pitch adjustments
    /// - Parameters:
    ///   - text: The text to speak
    ///   - rate: Speech rate (default is AVSpeechUtteranceDefaultSpeechRate)
    ///   - pitch: Pitch multiplier (default is 1.0)
    func speak(_ text: String, rate: Float = AVSpeechUtteranceDefaultSpeechRate, pitch: Float = 1.0) {
        guard isAvailable else { return }

        stopSpeaking()

        let utterance = AVSpeechUtterance(string: text)

        // Use a child-friendly voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }

        // Clamp rate to valid range and set it
        let clampedRate = max(AVSpeechUtteranceMinimumSpeechRate, min(AVSpeechUtteranceMaximumSpeechRate, rate))
        utterance.rate = clampedRate
        utterance.pitchMultiplier = pitch
        utterance.volume = 1.0

        currentUtterance = utterance
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    /// Stop any ongoing speech immediately
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
    }
}

// MARK: - AVSpeechSynthesizerDelegate

extension TTSService {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
