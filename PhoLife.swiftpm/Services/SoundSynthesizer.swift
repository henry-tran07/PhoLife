@preconcurrency import AVFoundation

/// Programmatic SFX generator using AVAudioEngine.
///
/// Pre-generates all sound effects as PCM buffers at init time,
/// then plays them on demand through a shared audio engine.
@MainActor
final class SoundSynthesizer {

    // MARK: - Singleton

    static let shared = SoundSynthesizer()

    // MARK: - Audio Engine

    private let audioEngine = AVAudioEngine()
    private let mixerNode = AVAudioMixerNode()
    private var cachedBuffers: [String: AVAudioPCMBuffer] = [:]

    private let sampleRate: Double = 44100
    private lazy var audioFormat = AVAudioFormat(
        standardFormatWithSampleRate: sampleRate, channels: 1
    )!

    // MARK: - Player Node Pool

    private let poolSize = 10
    private var playerNodes: [AVAudioPlayerNode] = []
    private var nextNodeIndex: Int = 0

    // MARK: - Init

    private init() {
        setupEngine()
        generateAll()
    }

    private func setupEngine() {
        audioEngine.attach(mixerNode)
        audioEngine.connect(mixerNode, to: audioEngine.mainMixerNode, format: audioFormat)

        for _ in 0..<poolSize {
            let node = AVAudioPlayerNode()
            audioEngine.attach(node)
            audioEngine.connect(node, to: mixerNode, format: audioFormat)
            playerNodes.append(node)
        }

        do {
            try audioEngine.start()
        } catch {
            print("[SoundSynthesizer] Engine start failed: \(error)")
        }
    }

    private func generateAll() {
        cachedBuffers["button-tap"] = generateButtonTap()
        cachedBuffers["success-chime"] = generateSuccessChime()
        cachedBuffers["error-buzz"] = generateErrorBuzz()
        cachedBuffers["slice"] = generateSlice()
        cachedBuffers["swipe"] = generateSwipe()
        cachedBuffers["pop"] = generatePop()
        cachedBuffers["sparkle"] = generateSparkle()
        cachedBuffers["card-flip"] = generateCardFlip()
        cachedBuffers["star-reveal"] = generateStarReveal()
        cachedBuffers["text-blip-0"] = generateTextBlip(frequency: 380)
        cachedBuffers["text-blip-1"] = generateTextBlip(frequency: 440)
        cachedBuffers["text-blip-2"] = generateTextBlip(frequency: 500)
    }

    // MARK: - Public API

    func hasSound(_ name: String) -> Bool {
        cachedBuffers[name] != nil
    }

    func playTextBlip() {
        let variant = Int.random(in: 0...2)
        play("text-blip-\(variant)", volume: 0.5)
    }

    func play(_ name: String, volume: Float = 1.0) {
        guard let buffer = cachedBuffers[name] else { return }

        if !audioEngine.isRunning {
            do { try audioEngine.start() } catch { return }
        }

        // Find an idle node, or fall back to round-robin reuse
        var node: AVAudioPlayerNode?
        for playerNode in playerNodes where !playerNode.isPlaying {
            node = playerNode
            break
        }
        if node == nil {
            node = playerNodes[nextNodeIndex]
            node?.stop()
            nextNodeIndex = (nextNodeIndex + 1) % poolSize
        }

        guard let playerNode = node else { return }
        playerNode.volume = volume
        playerNode.scheduleBuffer(buffer, at: nil, options: .interrupts)
        playerNode.play()
    }

    // MARK: - Buffer Helper

    private func makeBuffer(duration: TimeInterval) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        return AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: frameCount)!
    }

    // MARK: - Generators

    /// Short sine click at ~800Hz with fast decay (~50ms)
    private func generateButtonTap() -> AVAudioPCMBuffer {
        let duration = 0.05
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        let freq: Float = 800
        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let envelope = max(0, 1.0 - t / Float(duration))
            data[i] = sin(2 * .pi * freq * t) * envelope * 0.5
        }
        return buffer
    }

    /// Ascending two-tone (C5 → E5) sine wave (~200ms)
    private func generateSuccessChime() -> AVAudioPCMBuffer {
        let duration = 0.2
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        let freqC5: Float = 523.25
        let freqE5: Float = 659.25
        let halfFrames = frames / 2

        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let freq = i < halfFrames ? freqC5 : freqE5
            let localT = i < halfFrames ? t : t - Float(halfFrames) / Float(sampleRate)
            let attack = min(localT / 0.005, 1.0)
            let decay = max(0, 1.0 - localT / 0.1)
            let envelope = attack * decay
            data[i] = sin(2 * .pi * freq * t) * envelope * 0.5
        }
        return buffer
    }

    /// Low square wave at ~150Hz (~250ms)
    private func generateErrorBuzz() -> AVAudioPCMBuffer {
        let duration = 0.25
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        let freq: Float = 150
        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let envelope = max(0, 1.0 - t / Float(duration))
            // Square wave via odd harmonics
            var sample: Float = 0
            for h in stride(from: 1, through: 7, by: 2) {
                sample += sin(2 * .pi * freq * Float(h) * t) / Float(h)
            }
            data[i] = sample * envelope * 0.3
        }
        return buffer
    }

    /// Fruit-ninja swoosh — filtered noise with pitch sweep down (~150ms)
    private func generateSlice() -> AVAudioPCMBuffer {
        let duration = 0.15
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        var lowPass: Float = 0
        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let progress = t / Float(duration)
            let noise = Float.random(in: -1...1)
            let cutoff: Float = 0.3 * (1.0 - progress) + 0.02
            lowPass += cutoff * (noise - lowPass)
            let envelope = min(t / 0.005, 1.0) * max(0, 1.0 - progress * 0.8)
            data[i] = lowPass * envelope * 0.7
        }
        return buffer
    }

    /// Breathy noise sweep variant (~120ms)
    private func generateSwipe() -> AVAudioPCMBuffer {
        let duration = 0.12
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        var lowPass: Float = 0
        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let progress = t / Float(duration)
            let noise = Float.random(in: -1...1)
            let cutoff: Float = 0.25 * (1.0 - progress * 0.7) + 0.03
            lowPass += cutoff * (noise - lowPass)
            let envelope = sin(.pi * progress)
            data[i] = lowPass * envelope * 0.6
        }
        return buffer
    }

    /// Quick sine burst with rapid pitch drop 400→100Hz (~80ms)
    private func generatePop() -> AVAudioPCMBuffer {
        let duration = 0.08
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        var phase: Float = 0
        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let progress = t / Float(duration)
            let freq: Float = 400 - 300 * progress
            let envelope = max(0, 1.0 - progress * 1.2)
            phase += 2 * .pi * freq / Float(sampleRate)
            data[i] = sin(phase) * envelope * 0.5
        }
        return buffer
    }

    /// Multiple staggered high sine tones (shimmer) (~400ms)
    private func generateSparkle() -> AVAudioPCMBuffer {
        let duration = 0.4
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        for i in 0..<frames { data[i] = 0 }

        let tones: [(freq: Float, start: Float, dur: Float)] = [
            (1200, 0.00, 0.15),
            (1800, 0.05, 0.15),
            (2400, 0.10, 0.15),
            (1500, 0.15, 0.15),
            (2000, 0.20, 0.15),
            (2800, 0.25, 0.15),
        ]

        for tone in tones {
            let startFrame = Int(tone.start * Float(sampleRate))
            let toneFrames = Int(tone.dur * Float(sampleRate))
            for j in 0..<toneFrames {
                let idx = startFrame + j
                guard idx < frames else { break }
                let t = Float(j) / Float(sampleRate)
                let envelope = min(t / 0.003, 1.0) * max(0, 1.0 - t / tone.dur)
                data[idx] += sin(2 * .pi * tone.freq * t) * envelope * 0.15
            }
        }
        return buffer
    }

    /// Quick filtered noise whoosh (~100ms)
    private func generateCardFlip() -> AVAudioPCMBuffer {
        let duration = 0.1
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        var lowPass: Float = 0
        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let progress = t / Float(duration)
            let noise = Float.random(in: -1...1)
            let cutoff: Float = 0.2 * (1.0 - progress) + 0.05
            lowPass += cutoff * (noise - lowPass)
            let envelope = sin(.pi * progress)
            data[i] = lowPass * envelope * 0.5
        }
        return buffer
    }

    /// Short sine blip for dialogue text (~30ms)
    private func generateTextBlip(frequency: Float) -> AVAudioPCMBuffer {
        let duration = 0.03
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        for i in 0..<frames {
            let t = Float(i) / Float(sampleRate)
            let attack = min(t / 0.002, 1.0)
            let decay = max(0, 1.0 - t / Float(duration))
            let envelope = attack * decay
            data[i] = sin(2 * .pi * frequency * t) * envelope * 0.3
        }
        return buffer
    }

    /// Ascending multi-harmonic chime with shimmer (~500ms)
    private func generateStarReveal() -> AVAudioPCMBuffer {
        let duration = 0.5
        let buffer = makeBuffer(duration: duration)
        let frames = Int(sampleRate * duration)
        buffer.frameLength = AVAudioFrameCount(frames)
        let data = buffer.floatChannelData![0]

        for i in 0..<frames { data[i] = 0 }

        // Ascending chime: C5, E5, G5, C6
        let baseFreqs: [Float] = [523.25, 659.25, 783.99, 1046.5]

        for (index, freq) in baseFreqs.enumerated() {
            let startTime = Float(index) * 0.08
            let startFrame = Int(startTime * Float(sampleRate))
            let toneFrames = frames - startFrame

            for j in 0..<toneFrames {
                let idx = startFrame + j
                guard idx < frames else { break }
                let t = Float(j) / Float(sampleRate)
                let attack = min(t / 0.005, 1.0)
                let decay = max(0, 1.0 - t / 0.35)
                let envelope = attack * decay

                var sample = sin(2 * .pi * freq * t) * 0.3
                sample += sin(2 * .pi * freq * 2.0 * t) * 0.15
                sample += sin(2 * .pi * freq * 3.0 * t) * 0.05

                data[idx] += sample * envelope
            }
        }

        // Shimmer overlay
        let shimmerFreqs: [Float] = [3000, 3500, 4000]
        for (i, freq) in shimmerFreqs.enumerated() {
            let startFrame = Int(Float(i) * 0.12 * Float(sampleRate))
            let shimmerDur = Int(0.15 * Float(sampleRate))
            for j in 0..<shimmerDur {
                let idx = startFrame + j
                guard idx < frames else { break }
                let t = Float(j) / Float(sampleRate)
                let envelope = min(t / 0.002, 1.0) * max(0, 1.0 - t / 0.15)
                data[idx] += sin(2 * .pi * freq * t) * envelope * 0.06
            }
        }

        return buffer
    }
}
