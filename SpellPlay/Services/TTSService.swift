//
//  TTSService.swift
//  WordCraft
//
//  Created on [Date]
//

import Foundation
import AVFoundation

@MainActor
class TTSService: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    private let synthesizer: AVSpeechSynthesizer
    private var currentUtterance: AVSpeechUtterance?
    
    @Published var isSpeaking = false
    @Published var isAvailable = true
    
    override init() {
        let synth = AVSpeechSynthesizer()
        self.synthesizer = synth
        super.init()
        checkAvailability()
        synth.delegate = self
    }
    
    private func checkAvailability() {
        // TTS is generally available on iOS devices
        isAvailable = true
    }
    
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
        synthesizer.speak(utterance)
        isSpeaking = true
        
        // Reset speaking state when done (approximate timing)
        Task {
            try? await Task.sleep(nanoseconds: UInt64(utterance.speechString.count * 100_000_000))
            if !synthesizer.isSpeaking {
                isSpeaking = false
            }
        }
    }
    
    func stopSpeaking() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        currentUtterance = nil
    }
}

// AVSpeechSynthesizerDelegate methods
extension TTSService {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
    
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            isSpeaking = false
        }
    }
}

