# Sound Effects & Multi-Device Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add programmatic sound effects (synthesized via AVAudioEngine) for all 8 minigames and enable Mac support alongside iPad.

**Architecture:** Replace the file-based SFX/ambient loading in AudioManager with a new `SoundSynthesizer` service that generates audio in real-time using `AVAudioEngine` + `AVAudioSourceNode` for ambient loops and pre-rendered `AVAudioPCMBuffer` for one-shot SFX. Music layer stays file-based. Package.swift stays `.pad` only; Mac runs via "Designed for iPad."

**Tech Stack:** AVAudioEngine, AVAudioSourceNode, AVAudioPlayerNode, AVAudioPCMBuffer, Swift 6 strict concurrency

---

### Task 1: Create SoundSynthesizer — Engine Setup & SFX Buffer Generation

**Files:**
- Create: `PhoLife.swiftpm/Services/SoundSynthesizer.swift`

**Step 1: Create the SoundSynthesizer class with AVAudioEngine graph**

Create `PhoLife.swiftpm/Services/SoundSynthesizer.swift` with:

```swift
import AVFoundation

/// Programmatic audio synthesis engine for PhoLife.
///
/// Generates all SFX and ambient sounds in real-time — no audio files needed.
/// Uses AVAudioEngine with:
/// - A pool of AVAudioPlayerNode for one-shot SFX (pre-rendered buffers)
/// - An AVAudioSourceNode for continuous ambient loops (real-time callback)
@MainActor
final class SoundSynthesizer {

    static let shared = SoundSynthesizer()

    // MARK: - Engine

    private let engine = AVAudioEngine()
    private let sfxMixer = AVAudioMixerNode()
    private let ambientMixer = AVAudioMixerNode()

    // MARK: - SFX Pool

    private var sfxPlayers: [AVAudioPlayerNode] = []
    private let sfxPoolSize = 8

    // MARK: - Ambient

    private var ambientSourceNode: AVAudioSourceNode?
    private var ambientGenerator: AmbientGenerator?
    private var ambientFadeTarget: Float = 0
    private var ambientFadeCurrent: Float = 0
    private var ambientFadeTimer: Timer?

    // MARK: - Volume

    let sfxVolume: Float = 0.7
    let ambientVolume: Float = 0.3

    // MARK: - Pre-rendered SFX Buffers

    private var sfxBuffers: [String: AVAudioPCMBuffer] = [:]

    // MARK: - Format

    private let sampleRate: Double = 44100
    private lazy var format: AVAudioFormat = {
        AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
    }()

    // MARK: - Init

    private init() {
        setupEngine()
        generateAllSFXBuffers()
    }

    private func setupEngine() {
        engine.attach(sfxMixer)
        engine.attach(ambientMixer)

        engine.connect(sfxMixer, to: engine.mainMixerNode, format: format)
        engine.connect(ambientMixer, to: engine.mainMixerNode, format: format)

        sfxMixer.outputVolume = sfxVolume
        ambientMixer.outputVolume = 0 // Start silent, fade in when ambient starts

        // Create SFX player pool
        for _ in 0..<sfxPoolSize {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: sfxMixer, format: format)
            sfxPlayers.append(player)
        }

        do {
            try engine.start()
        } catch {
            print("[SoundSynthesizer] Engine start failed: \(error)")
        }
    }

    // MARK: - SFX Playback

    func playSFX(_ name: String) {
        guard let buffer = sfxBuffers[name] else {
            print("[SoundSynthesizer] No buffer for SFX: \(name)")
            return
        }

        // Find an idle player
        if let player = sfxPlayers.first(where: { !$0.isPlaying }) {
            player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
            player.play()
            return
        }

        // All busy — stop the first and reuse
        let player = sfxPlayers[0]
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        player.play()
    }

    // MARK: - Ambient Playback

    func startAmbient(_ name: String, fadeDuration: TimeInterval = 0.5) {
        stopAmbient(fadeDuration: 0.1)

        let generator = AmbientGenerator.make(name: name, sampleRate: sampleRate)
        ambientGenerator = generator

        let sr = sampleRate
        let sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, bufferList -> OSStatus in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(bufferList)
            guard let buf = ablPointer.first, let data = buf.mData else { return noErr }
            let floatPtr = data.assumingMemoryBound(to: Float.self)
            nonisolated(unsafe) let gen = generator
            for frame in 0..<Int(frameCount) {
                floatPtr[frame] = gen.nextSample(sampleRate: sr)
            }
            return noErr
        }

        ambientSourceNode = sourceNode
        engine.attach(sourceNode)
        engine.connect(sourceNode, to: ambientMixer, format: format)

        // Fade in
        fadeAmbient(to: ambientVolume, duration: fadeDuration)
    }

    func stopAmbient(fadeDuration: TimeInterval = 0.5) {
        fadeAmbient(to: 0, duration: fadeDuration) { [weak self] in
            guard let self else { return }
            if let node = self.ambientSourceNode {
                self.engine.detach(node)
                self.ambientSourceNode = nil
            }
            self.ambientGenerator = nil
        }
    }

    private func fadeAmbient(to target: Float, duration: TimeInterval, onComplete: (@MainActor () -> Void)? = nil) {
        ambientFadeTimer?.invalidate()

        if duration <= 0.05 {
            ambientMixer.outputVolume = target
            onComplete?()
            return
        }

        let startVolume = ambientMixer.outputVolume
        let interval: TimeInterval = 0.05
        let steps = max(Int(duration / interval), 1)
        let volumeStep = (target - startVolume) / Float(steps)
        var step = 0

        ambientFadeTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            step += 1
            let done = step >= steps
            if done { timer.invalidate() }

            MainActor.assumeIsolated {
                guard let self else { return }
                if done {
                    self.ambientMixer.outputVolume = target
                    onComplete?()
                } else {
                    self.ambientMixer.outputVolume = startVolume + volumeStep * Float(step)
                }
            }
        }
    }

    // MARK: - Stop All

    func stopAll() {
        stopAmbient(fadeDuration: 0.1)
        for player in sfxPlayers {
            player.stop()
        }
    }

    // MARK: - Buffer Generation

    private func generateAllSFXBuffers() {
        sfxBuffers["success-chime"] = generateSuccessChime()
        sfxBuffers["error-buzz"] = generateFailBuzz()
        sfxBuffers["star-reveal"] = generateStarReveal()
        sfxBuffers["button-tap"] = generateButtonTap()
        sfxBuffers["completion-fanfare"] = generateCompletionFanfare()
        sfxBuffers["sizzle"] = generateSizzle()
        sfxBuffers["toast-crackle"] = generateToastCrackle()
        sfxBuffers["pop"] = generatePop()
        sfxBuffers["simmer-entry"] = generateSimmerEntry()
        sfxBuffers["slice"] = generateSlice()
        sfxBuffers["pour"] = generatePour()
        sfxBuffers["place"] = generatePlace()
        sfxBuffers["card-flip"] = generateCardFlip()
        sfxBuffers["sparkle"] = generateSparkle()
    }

    private func makeBuffer(duration: Double) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        return AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
    }

    // MARK: - Synthesis Helpers

    /// Generate a sine wave sample at a given phase.
    private static func sine(_ phase: Double) -> Float {
        Float(sin(phase * 2.0 * .pi))
    }

    /// Generate white noise sample.
    private static func noise() -> Float {
        Float.random(in: -1...1)
    }

    /// Simple ADSR envelope (attack, decay, sustain level, release) normalized to duration.
    private static func envelope(
        t: Double, duration: Double,
        attack: Double = 0.01, decay: Double = 0.05,
        sustainLevel: Double = 0.7, release: Double = 0.1
    ) -> Float {
        let releaseStart = duration - release
        if t < attack {
            return Float(t / attack)
        } else if t < attack + decay {
            let decayProgress = (t - attack) / decay
            return Float(1.0 - (1.0 - sustainLevel) * decayProgress)
        } else if t < releaseStart {
            return Float(sustainLevel)
        } else {
            let releaseProgress = (t - releaseStart) / release
            return Float(sustainLevel * (1.0 - releaseProgress))
        }
    }

    // MARK: - Global SFX Generators

    /// Rising 3-note sine arpeggio C5-E5-G5, 0.4s
    private func generateSuccessChime() -> AVAudioPCMBuffer {
        let duration = 0.4
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        let freqs: [Double] = [523.25, 659.25, 783.99] // C5, E5, G5
        let noteLength = duration / 3.0

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let noteIndex = min(Int(t / noteLength), 2)
            let noteT = t - Double(noteIndex) * noteLength
            let freq = freqs[noteIndex]
            let phase = noteT * freq
            let env = Self.envelope(t: noteT, duration: noteLength, attack: 0.005, decay: 0.03, sustainLevel: 0.6, release: 0.05)
            let sample = Self.sine(phase) * env * 0.5
            // Add a soft harmonic
            let harmonic = Self.sine(phase * 2.0) * env * 0.15
            data[i] = sample + harmonic
        }
        return buffer
    }

    /// Low square wave 80Hz + noise burst, 0.2s
    private func generateFailBuzz() -> AVAudioPCMBuffer {
        let duration = 0.2
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let phase = t * 80.0
            let square = (fmod(phase, 1.0) < 0.5) ? Float(0.4) : Float(-0.4)
            let env = Self.envelope(t: t, duration: duration, attack: 0.005, decay: 0.02, sustainLevel: 0.8, release: 0.08)
            let noisePart = Self.noise() * 0.2 * env
            data[i] = (square + noisePart) * env
        }
        return buffer
    }

    /// Ascending bell tone with shimmer, 0.5s
    private func generateStarReveal() -> AVAudioPCMBuffer {
        let duration = 0.5
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            // Ascending pitch from A5 to E6
            let freq = 880.0 + (1318.5 - 880.0) * (t / duration)
            let phase = t * freq
            let env = Self.envelope(t: t, duration: duration, attack: 0.01, decay: 0.05, sustainLevel: 0.5, release: 0.2)
            let bell = Self.sine(phase) * 0.4
            let shimmer = Self.sine(phase * 3.0) * 0.1 * Float(sin(t * 30.0))
            data[i] = (bell + shimmer) * env
        }
        return buffer
    }

    /// Short click — filtered noise impulse, 0.05s
    private func generateButtonTap() -> AVAudioPCMBuffer {
        let duration = 0.05
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Float(max(0, 1.0 - t / duration))
            data[i] = Self.noise() * env * 0.5
        }
        return buffer
    }

    /// 4-note ascending major chord, 1.2s
    private func generateCompletionFanfare() -> AVAudioPCMBuffer {
        let duration = 1.2
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        // C5, E5, G5, C6 — staggered entry
        let notes: [(freq: Double, start: Double)] = [
            (523.25, 0.0), (659.25, 0.15), (783.99, 0.30), (1046.50, 0.45)
        ]

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            var sample: Float = 0
            for note in notes {
                let noteT = t - note.start
                guard noteT >= 0 else { continue }
                let noteDur = duration - note.start
                let env = Self.envelope(t: noteT, duration: noteDur, attack: 0.01, decay: 0.1, sustainLevel: 0.4, release: 0.3)
                sample += Self.sine(noteT * note.freq) * env * 0.2
                sample += Self.sine(noteT * note.freq * 2.0) * env * 0.05
            }
            data[i] = sample
        }
        return buffer
    }

    // MARK: - Minigame-Specific SFX Generators

    /// Burst of filtered noise — sizzle on tap (Char Aromatics)
    private func generateSizzle() -> AVAudioPCMBuffer {
        let duration = 0.3
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        var prevSample: Float = 0
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Self.envelope(t: t, duration: duration, attack: 0.005, decay: 0.05, sustainLevel: 0.5, release: 0.15)
            // Simple low-pass by averaging with previous sample
            let raw = Self.noise() * env * 0.6
            let filtered = (raw + prevSample) * 0.5
            prevSample = filtered
            data[i] = filtered
        }
        return buffer
    }

    /// Short snap/crackle (Toast Spices)
    private func generateToastCrackle() -> AVAudioPCMBuffer {
        let duration = 0.15
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Float(max(0, 1.0 - t / duration)) // Sharp linear decay
            let crack = Self.noise() * env * 0.7
            // Add a small pitched click at the start
            let click = (t < 0.005) ? Self.sine(t * 2000.0) * 0.3 : Float(0)
            data[i] = crack + click
        }
        return buffer
    }

    /// Quick pitched noise burst — bubble pop (Clean Bones)
    private func generatePop() -> AVAudioPCMBuffer {
        let duration = 0.1
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            // Descending pitch pop
            let freq = 800.0 - 600.0 * (t / duration)
            let env = Float(max(0, 1.0 - t / duration))
            let tone = Self.sine(t * freq) * 0.4
            let pop = Self.noise() * 0.2 * (t < 0.02 ? Float(1) : Float(0.1))
            data[i] = (tone + pop) * env
        }
        return buffer
    }

    /// Warm tone on zone entry (Simmer Broth)
    private func generateSimmerEntry() -> AVAudioPCMBuffer {
        let duration = 0.3
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Self.envelope(t: t, duration: duration, attack: 0.02, decay: 0.05, sustainLevel: 0.5, release: 0.15)
            // Warm low tone
            let fundamental = Self.sine(t * 330.0) * 0.4
            let second = Self.sine(t * 495.0) * 0.15
            data[i] = (fundamental + second) * env
        }
        return buffer
    }

    /// Sharp noise sweep — knife cut (Slice Beef)
    private func generateSlice() -> AVAudioPCMBuffer {
        let duration = 0.15
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        var prev: Float = 0
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Float(max(0, 1.0 - t / duration))
            // High-pass noise (subtract low-pass from raw)
            let raw = Self.noise()
            let lp = (raw + prev) * 0.5
            prev = lp
            let hp = (raw - lp) * env * 0.7
            // Pitched swoosh
            let freq = 3000.0 - 2000.0 * (t / duration)
            let swoosh = Self.sine(t * freq) * env * 0.15
            data[i] = hp + swoosh
        }
        return buffer
    }

    /// Filtered noise with pitch drop — liquid pour (Season Broth / Assemble Bowl)
    private func generatePour() -> AVAudioPCMBuffer {
        let duration = 0.4
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        var prev: Float = 0
        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Self.envelope(t: t, duration: duration, attack: 0.02, decay: 0.05, sustainLevel: 0.6, release: 0.2)
            // Bubbling noise — modulate the filter cutoff
            let modulation = Float(sin(t * 25.0)) * 0.3 + 0.7
            let raw = Self.noise() * env * modulation * 0.5
            let filtered = raw * 0.6 + prev * 0.4
            prev = filtered
            data[i] = filtered
        }
        return buffer
    }

    /// Soft thud + resonance — ingredient placement (Assemble Bowl)
    private func generatePlace() -> AVAudioPCMBuffer {
        let duration = 0.2
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Float(max(0, 1.0 - t / duration))
            // Low thud
            let thud = Self.sine(t * 120.0) * env * 0.5
            // Brief noise impact
            let impact = Self.noise() * (t < 0.015 ? Float(0.4) : Float(0))
            data[i] = thud + impact
        }
        return buffer
    }

    /// Short pitched click — card flip (Top It Off)
    private func generateCardFlip() -> AVAudioPCMBuffer {
        let duration = 0.08
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Float(max(0, 1.0 - t / duration))
            // Rising click
            let freq = 1200.0 + 800.0 * (t / duration)
            data[i] = Self.sine(t * freq) * env * 0.4
        }
        return buffer
    }

    /// High shimmer — sparkle effect (Clean Bones / Top It Off)
    private func generateSparkle() -> AVAudioPCMBuffer {
        let duration = 0.35
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        guard let data = buffer.floatChannelData?[0] else { return buffer }

        for i in 0..<frames {
            let t = Double(i) / sampleRate
            let env = Self.envelope(t: t, duration: duration, attack: 0.005, decay: 0.05, sustainLevel: 0.3, release: 0.2)
            // Multiple high-frequency sines for shimmer
            let s1 = Self.sine(t * 2637.0) * 0.2  // E7
            let s2 = Self.sine(t * 3520.0) * 0.15 // A7
            let s3 = Self.sine(t * 4186.0) * 0.1  // C8
            // Amplitude modulation for sparkle feel
            let mod = Float(sin(t * 40.0)) * 0.3 + 0.7
            data[i] = (s1 + s2 + s3) * env * mod
        }
        return buffer
    }
}

// MARK: - Ambient Generator Protocol & Implementations

/// Protocol for continuous ambient sound generation (called per-sample from audio thread).
/// Implementations MUST be thread-safe (called from audio render thread, not MainActor).
protocol AmbientGenerator: AnyObject, Sendable {
    func nextSample(sampleRate: Double) -> Float

    static func make(name: String, sampleRate: Double) -> AmbientGenerator
}

extension AmbientGenerator {
    static func make(name: String, sampleRate: Double) -> AmbientGenerator {
        switch name {
        case "char-fire":       return FireCrackleAmbient()
        case "toast-flame":     return FlameCrackleAmbient()
        case "clean-bubbles":   return BubblingWaterAmbient()
        case "simmer-boil":     return RollingBoilAmbient()
        case "slice-board":     return CuttingBoardAmbient()
        case "season-steam":    return GentleSteamAmbient()
        case "assemble-kitchen": return KitchenAmbient()
        case "topoff-air":      return LightAirAmbient()
        default:                return LightAirAmbient()
        }
    }
}

/// Crackling fire — filtered noise with random pop impulses
final class FireCrackleAmbient: AmbientGenerator, @unchecked Sendable {
    private var phase: Double = 0
    private var prev: Float = 0
    private var popCountdown: Int = 0

    func nextSample(sampleRate: Double) -> Float {
        phase += 1.0 / sampleRate

        // Base crackle: heavily filtered noise
        let raw = Float.random(in: -1...1)
        let filtered = raw * 0.15 + prev * 0.85
        prev = filtered

        // Random pops
        var pop: Float = 0
        if popCountdown <= 0 {
            popCountdown = Int.random(in: Int(sampleRate * 0.05)...Int(sampleRate * 0.3))
            pop = Float.random(in: 0.1...0.3)
        }
        popCountdown -= 1

        return filtered * 0.6 + pop
    }
}

/// Gentle flame crackle — softer than fire, lower frequency
final class FlameCrackleAmbient: AmbientGenerator, @unchecked Sendable {
    private var prev: Float = 0
    private var prev2: Float = 0

    func nextSample(sampleRate: Double) -> Float {
        let raw = Float.random(in: -1...1)
        // Double low-pass for softer sound
        let lp1 = raw * 0.1 + prev * 0.9
        prev = lp1
        let lp2 = lp1 * 0.2 + prev2 * 0.8
        prev2 = lp2
        return lp2 * 0.5
    }
}

/// Bubbling water — sine clusters with randomized timing
final class BubblingWaterAmbient: AmbientGenerator, @unchecked Sendable {
    private var phase: Double = 0
    private var bubblePhase: Double = 0
    private var bubbleFreq: Double = 300
    private var bubbleCountdown: Int = 0
    private var bubbleActive: Bool = false
    private var bubbleLife: Int = 0
    private var prev: Float = 0

    func nextSample(sampleRate: Double) -> Float {
        phase += 1.0 / sampleRate

        // Background water noise
        let raw = Float.random(in: -1...1)
        let water = raw * 0.05 + prev * 0.95
        prev = water

        // Bubble pops
        var bubble: Float = 0
        if bubbleActive {
            bubblePhase += bubbleFreq / sampleRate
            let env = Float(max(0, 1.0 - Double(bubbleLife) / (sampleRate * 0.06)))
            bubble = sin(Float(bubblePhase * 2.0 * .pi)) * env * 0.2
            bubbleLife += 1
            if env <= 0 { bubbleActive = false }
        } else {
            bubbleCountdown -= 1
            if bubbleCountdown <= 0 {
                bubbleActive = true
                bubbleLife = 0
                bubblePhase = 0
                bubbleFreq = Double.random(in: 250...500)
                bubbleCountdown = Int.random(in: Int(sampleRate * 0.04)...Int(sampleRate * 0.2))
            }
        }

        return water * 0.4 + bubble
    }
}

/// Rolling boil — deeper bubbling + steam hiss
final class RollingBoilAmbient: AmbientGenerator, @unchecked Sendable {
    private var phase: Double = 0
    private var bubblePhase: Double = 0
    private var bubbleFreq: Double = 180
    private var bubbleCountdown: Int = 0
    private var bubbleActive: Bool = false
    private var bubbleLife: Int = 0
    private var prev: Float = 0
    private var hisPrev: Float = 0

    func nextSample(sampleRate: Double) -> Float {
        phase += 1.0 / sampleRate

        // Steam hiss: high-pass noise
        let raw = Float.random(in: -1...1)
        let lp = raw * 0.05 + hisPrev * 0.95
        hisPrev = lp
        let hiss = (raw - lp) * 0.08

        // Deep bubbles
        let waterRaw = Float.random(in: -1...1)
        let water = waterRaw * 0.08 + prev * 0.92
        prev = water

        var bubble: Float = 0
        if bubbleActive {
            bubblePhase += bubbleFreq / sampleRate
            let env = Float(max(0, 1.0 - Double(bubbleLife) / (sampleRate * 0.08)))
            bubble = sin(Float(bubblePhase * 2.0 * .pi)) * env * 0.25
            bubbleLife += 1
            if env <= 0 { bubbleActive = false }
        } else {
            bubbleCountdown -= 1
            if bubbleCountdown <= 0 {
                bubbleActive = true
                bubbleLife = 0
                bubblePhase = 0
                bubbleFreq = Double.random(in: 120...300)
                bubbleCountdown = Int.random(in: Int(sampleRate * 0.02)...Int(sampleRate * 0.12))
            }
        }

        return water * 0.3 + bubble + hiss
    }
}

/// Subtle hum — cutting board ambience
final class CuttingBoardAmbient: AmbientGenerator, @unchecked Sendable {
    private var phase: Double = 0

    func nextSample(sampleRate: Double) -> Float {
        phase += 1.0 / sampleRate
        // Very quiet low hum with slight modulation
        let hum = sin(Float(phase * 60.0 * 2.0 * .pi)) * 0.05
        let mod = sin(Float(phase * 0.5 * 2.0 * .pi)) * 0.02 + 0.98
        return hum * mod + Float.random(in: -0.01...0.01)
    }
}

/// Gentle steam — soft filtered noise
final class GentleSteamAmbient: AmbientGenerator, @unchecked Sendable {
    private var prev: Float = 0
    private var prev2: Float = 0

    func nextSample(sampleRate: Double) -> Float {
        let raw = Float.random(in: -1...1)
        // Band-pass-like filtering
        let lp = raw * 0.08 + prev * 0.92
        prev = lp
        let hp = lp - prev2
        prev2 = lp * 0.99 + prev2 * 0.01
        return hp * 3.0 * 0.15
    }
}

/// Kitchen ambience — low warm hum + occasional subtle sounds
final class KitchenAmbient: AmbientGenerator, @unchecked Sendable {
    private var phase: Double = 0
    private var prev: Float = 0

    func nextSample(sampleRate: Double) -> Float {
        phase += 1.0 / sampleRate
        let hum = sin(Float(phase * 50.0 * 2.0 * .pi)) * 0.04
        let raw = Float.random(in: -1...1)
        let filtered = raw * 0.02 + prev * 0.98
        prev = filtered
        return hum + filtered * 0.3
    }
}

/// Light ambient air — very subtle
final class LightAirAmbient: AmbientGenerator, @unchecked Sendable {
    private var prev: Float = 0

    func nextSample(sampleRate: Double) -> Float {
        let raw = Float.random(in: -1...1)
        let filtered = raw * 0.03 + prev * 0.97
        prev = filtered
        return filtered * 0.2
    }
}
```

**Step 2: Build to verify compilation**

Run: Build via Xcode — expect 0 errors. The SoundSynthesizer is standalone with no external dependencies beyond AVFoundation.

**Step 3: Commit**

```bash
git add PhoLife.swiftpm/Services/SoundSynthesizer.swift
git commit -m "feat: add SoundSynthesizer with AVAudioEngine synthesis for all SFX and ambient sounds"
```

---

### Task 2: Rewire AudioManager to Use SoundSynthesizer

**Files:**
- Modify: `PhoLife.swiftpm/Services/AudioManager.swift`

**Step 1: Modify AudioManager to delegate SFX and ambient to SoundSynthesizer**

Changes to make:
1. Wrap `AVAudioSession` in `#if os(iOS)` for Mac compat
2. Modify `playSFX()` to route to `SoundSynthesizer.shared.playSFX()` instead of loading files
3. Modify `playAmbient()` to route to `SoundSynthesizer.shared.startAmbient()`
4. Modify `stopAmbient()` to route to `SoundSynthesizer.shared.stopAmbient()`
5. Modify `stopAll()` to also stop synthesizer

Replace the full `AudioManager.swift` with:

```swift
@preconcurrency import AVFoundation

/// Three-layer audio manager for PhoLife.
///
/// - **Music** — looping background music with dual-player crossfade (file-based).
/// - **Ambient** — looping ambient soundscape via SoundSynthesizer (programmatic).
/// - **SFX** — fire-and-forget via SoundSynthesizer (programmatic).
@Observable
@MainActor
final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Volume Targets

    private let musicVolume: Float = 0.4

    // MARK: - Music Players (dual for crossfade)

    private var musicPlayerA: AVAudioPlayer?
    private var musicPlayerB: AVAudioPlayer?
    private var musicActiveIsA: Bool = true

    // MARK: - Active Fade Timers

    private var musicFadeTimer: Timer?

    // MARK: - Init

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("[AudioManager] Audio session setup failed: \(error.localizedDescription)")
        }
        #endif
    }

    // MARK: - File Loading (Music only)

    private func loadPlayer(for filename: String) -> AVAudioPlayer? {
        let extensions = ["m4a", "mp3", "caf"]
        for ext in extensions {
            guard let url = Bundle.main.url(forResource: filename, withExtension: ext) else {
                continue
            }
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.prepareToPlay()
                return player
            } catch {
                print("[AudioManager] Failed to load \(filename).\(ext): \(error.localizedDescription)")
            }
        }
        print("[AudioManager] Audio file not found: \(filename) (tried m4a/mp3/caf)")
        return nil
    }

    // MARK: - Mutable Counter Box

    private final class StepCounter: @unchecked Sendable {
        var value: Int = 0
    }

    // MARK: - Crossfade Utility

    @discardableResult
    private func crossfade(
        from outPlayer: AVAudioPlayer?,
        to inPlayer: AVAudioPlayer?,
        targetVolume: Float,
        duration: TimeInterval,
        onComplete: @escaping @MainActor () -> Void
    ) -> Timer? {
        let interval: TimeInterval = 0.05
        let steps = max(Int(duration / interval), 1)
        let volumeStep = targetVolume / Float(steps)
        let counter = StepCounter()

        inPlayer?.volume = 0
        inPlayer?.play()

        let outStartVolume = outPlayer?.volume ?? 0
        let outVolumeStep = outStartVolume / Float(steps)

        nonisolated(unsafe) let unsafeInPlayer = inPlayer
        nonisolated(unsafe) let unsafeOutPlayer = outPlayer

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            counter.value += 1
            let step = counter.value
            let done = step >= steps
            if done || self == nil { timer.invalidate() }

            MainActor.assumeIsolated {
                guard self != nil else { return }
                let newVolume = min(volumeStep * Float(step), targetVolume)
                unsafeInPlayer?.volume = newVolume
                let oldVolume = max(outStartVolume - outVolumeStep * Float(step), 0)
                unsafeOutPlayer?.volume = oldVolume
                if done {
                    unsafeInPlayer?.volume = targetVolume
                    unsafeOutPlayer?.stop()
                    unsafeOutPlayer?.volume = 0
                    onComplete()
                }
            }
        }
        return timer
    }

    private func fadeOut(
        player: AVAudioPlayer?,
        duration: TimeInterval,
        onComplete: @escaping @MainActor () -> Void
    ) -> Timer? {
        guard let player, player.isPlaying else {
            onComplete()
            return nil
        }
        let interval: TimeInterval = 0.05
        let steps = max(Int(duration / interval), 1)
        let startVolume = player.volume
        let volumeStep = startVolume / Float(steps)
        let counter = StepCounter()

        nonisolated(unsafe) let unsafePlayer = player

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            counter.value += 1
            let step = counter.value
            let done = step >= steps
            if done { timer.invalidate() }

            MainActor.assumeIsolated {
                let newVolume = max(startVolume - volumeStep * Float(step), 0)
                unsafePlayer.volume = newVolume
                if done {
                    unsafePlayer.stop()
                    unsafePlayer.volume = 0
                    onComplete()
                }
            }
        }
        return timer
    }

    // MARK: - Music (file-based, unchanged)

    func playMusic(_ filename: String, fadeDuration: TimeInterval = 1.0) {
        guard let newPlayer = loadPlayer(for: filename) else { return }
        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0

        musicFadeTimer?.invalidate()
        musicFadeTimer = nil

        let outPlayer: AVAudioPlayer?
        if musicActiveIsA {
            outPlayer = musicPlayerA
            musicPlayerB = newPlayer
        } else {
            outPlayer = musicPlayerB
            musicPlayerA = newPlayer
        }
        musicActiveIsA.toggle()

        musicFadeTimer = crossfade(
            from: outPlayer,
            to: newPlayer,
            targetVolume: musicVolume,
            duration: fadeDuration,
            onComplete: { [weak self] in
                guard let self else { return }
                if self.musicActiveIsA {
                    self.musicPlayerB = nil
                } else {
                    self.musicPlayerA = nil
                }
                self.musicFadeTimer = nil
            }
        )
    }

    func stopMusic(fadeDuration: TimeInterval = 0.5) {
        musicFadeTimer?.invalidate()
        musicFadeTimer = nil
        let activePlayer = musicActiveIsA ? musicPlayerA : musicPlayerB
        musicFadeTimer = fadeOut(player: activePlayer, duration: fadeDuration) { [weak self] in
            guard let self else { return }
            self.musicPlayerA = nil
            self.musicPlayerB = nil
            self.musicFadeTimer = nil
        }
    }

    // MARK: - Ambient (delegated to SoundSynthesizer)

    func playAmbient(_ name: String, fadeDuration: TimeInterval = 0.5) {
        SoundSynthesizer.shared.startAmbient(name, fadeDuration: fadeDuration)
    }

    func stopAmbient(fadeDuration: TimeInterval = 0.5) {
        SoundSynthesizer.shared.stopAmbient(fadeDuration: fadeDuration)
    }

    // MARK: - Sound Effects (delegated to SoundSynthesizer)

    func playSFX(_ name: String) {
        SoundSynthesizer.shared.playSFX(name)
    }

    // MARK: - Global

    func stopAll(fadeDuration: TimeInterval = 0.5) {
        stopMusic(fadeDuration: fadeDuration)
        SoundSynthesizer.shared.stopAll()
    }
}
```

**Step 2: Build to verify compilation**

Run: Build via Xcode — expect 0 errors.

**Step 3: Commit**

```bash
git add PhoLife.swiftpm/Services/AudioManager.swift
git commit -m "refactor: rewire AudioManager to delegate SFX and ambient to SoundSynthesizer"
```

---

### Task 3: Wire Per-Minigame Ambient Sounds in MinigameContainerView

**Files:**
- Modify: `PhoLife.swiftpm/Features/Minigames/MinigameContainerView.swift:114-127`

**Step 1: Replace generic "kitchen-ambient" with per-minigame ambient names**

Change the `.onChange(of: phase)` block at line 114 to use minigame-specific ambient names:

Replace lines 114-127:
```swift
        .onChange(of: phase) { _, newPhase in
            // Update scene blur based on phase (blur when cards overlay)
            switch newPhase {
            case .intro:
                sceneBlur = 3
                AudioManager.shared.stopAmbient()
            case .playing:
                sceneBlur = 0
                AudioManager.shared.playAmbient("kitchen-ambient")
            case .scoreReveal:
                sceneBlur = 4
                AudioManager.shared.playSFX("star-reveal")
            }
        }
```

With:
```swift
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .intro:
                sceneBlur = 3
                AudioManager.shared.stopAmbient()
            case .playing:
                sceneBlur = 0
                AudioManager.shared.playAmbient(ambientName(for: gameState.currentMinigameIndex))
            case .scoreReveal:
                sceneBlur = 4
                AudioManager.shared.playSFX("star-reveal")
            }
        }
```

Also add this helper method inside the struct:

```swift
    private func ambientName(for minigameIndex: Int) -> String {
        switch minigameIndex {
        case 0: return "char-fire"
        case 1: return "toast-flame"
        case 2: return "clean-bubbles"
        case 3: return "simmer-boil"
        case 4: return "slice-board"
        case 5: return "season-steam"
        case 6: return "assemble-kitchen"
        case 7: return "topoff-air"
        default: return "topoff-air"
        }
    }
```

**Step 2: Build and run to verify ambient sounds play per minigame**

Run: Build via Xcode, navigate through minigames, verify each has a distinct ambient sound.

**Step 3: Commit**

```bash
git add PhoLife.swiftpm/Features/Minigames/MinigameContainerView.swift
git commit -m "feat: wire per-minigame ambient sounds in MinigameContainerView"
```

---

### Task 4: Update SFX Names in Minigame Scenes

**Files:**
- Modify: `PhoLife.swiftpm/Features/Minigames/Scenes/ToastSpicesScene.swift:711`
- Modify: `PhoLife.swiftpm/Features/Minigames/Scenes/SimmerBrothScene.swift:880`

**Step 1: Update ToastSpicesScene to use "toast-crackle" for action SFX**

At line 711, the scene calls `AudioManager.shared.playSFX("success-chime")` for a correct catch. This should play the action SFX first, then the success chime. Change:

```swift
AudioManager.shared.playSFX("success-chime")
```
to:
```swift
AudioManager.shared.playSFX("toast-crackle")
```

The existing success-chime call handles the "correct" feedback. But the toast-crackle is the **action** sound — so we want it on the catch event. The scene already plays success-chime elsewhere for the "correct" visual. Check: if line 711 is the ONLY success sound for correct catch, keep it as success-chime and add a separate toast-crackle call before it. If there's already a success-chime, replace the duplicate with toast-crackle.

**Step 2: Update SimmerBrothScene to use "simmer-entry"**

At line 880, change:
```swift
AudioManager.shared.playSFX("success-chime")
```
to:
```swift
AudioManager.shared.playSFX("simmer-entry")
```

This plays the warm tone when entering the simmering zone instead of the generic success chime.

**Step 3: Build and verify**

**Step 4: Commit**

```bash
git add PhoLife.swiftpm/Features/Minigames/Scenes/ToastSpicesScene.swift \
        PhoLife.swiftpm/Features/Minigames/Scenes/SimmerBrothScene.swift
git commit -m "feat: use minigame-specific SFX for Toast Spices and Simmer Broth"
```

---

### Task 5: Add Completion Fanfare

**Files:**
- Modify: `PhoLife.swiftpm/Features/Minigames/MinigameContainerView.swift`
- Modify: `PhoLife.swiftpm/ContentView.swift:50-61`

**Step 1: Add completion fanfare when transitioning to completion phase**

In `ContentView.swift`, in the `.onChange(of: gameState.currentPhase)` handler, add a fanfare SFX when entering completion:

Change the `.completion` case at line 59:
```swift
case .completion:
    AudioManager.shared.playMusic("background-music")
```
to:
```swift
case .completion:
    AudioManager.shared.playMusic("background-music")
    AudioManager.shared.playSFX("completion-fanfare")
```

**Step 2: Build and verify**

**Step 3: Commit**

```bash
git add PhoLife.swiftpm/ContentView.swift
git commit -m "feat: play completion fanfare when entering completion phase"
```

---

### Task 6: Update Package.swift for Mac Support

**Files:**
- Modify: `PhoLife.swiftpm/Package.swift:8-10`

**Step 1: Add macOS platform target**

The `.swiftpm` App Playground format uses `AppleProductTypes`. The `supportedDeviceFamilies` already has `.pad`. For Mac support via "Designed for iPad", we need to add `.mac` to the device families if the `AppleProductTypes` API supports it.

However, for `.swiftpm` App Playgrounds, Mac Catalyst / "Designed for iPad" support is typically automatic on Apple Silicon Macs when the app targets iPad. The key change is ensuring the build doesn't fail on macOS by:

1. Keeping `supportedDeviceFamilies: [.pad]` — Apple Silicon Macs run iPad apps natively
2. Adding `.macCatalyst("26.0")` to platforms if needed for explicit Mac builds

Check if `AppleProductTypes` supports `.mac` in device families. If not, the Mac support is automatic on Apple Silicon.

Update Package.swift platforms from:
```swift
platforms: [
    .iOS("26.0")
],
```
to:
```swift
platforms: [
    .iOS("26.0"),
    .macOS("26.0")
],
```

And add `.mac` to supported device families if the API supports it:
```swift
supportedDeviceFamilies: [
    .pad,
    .mac
],
```

If `.mac` is not available in `AppleProductTypes.DeviceFamily`, leave device families as `.pad` only — Mac will run it natively as an iPad app on Apple Silicon.

**Step 2: Build on iPad simulator to verify no regressions**

**Step 3: Commit**

```bash
git add PhoLife.swiftpm/Package.swift
git commit -m "feat: add Mac support in Package.swift"
```

---

### Task 7: Build, Test & Verify on All Targets

**Step 1: Build for iPad simulator**

Run: Build via Xcode targeting iPad Pro 13-inch (M5) simulator. Expect 0 errors.

**Step 2: Run on iPad simulator and verify:**
- Background music plays on launch
- Each minigame has distinct ambient sound that starts on play and stops on intro/score
- All SFX fire correctly (tap through each minigame)
- Star reveal sound plays on score card
- Completion fanfare plays on final screen
- No audio glitches, pops, or silence gaps

**Step 3: Build for Mac (if Mac target added) or verify "Designed for iPad" on Apple Silicon Mac**

**Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: address build and audio issues from testing"
```
