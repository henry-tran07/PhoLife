@preconcurrency import AVFoundation

/// Three-layer audio manager for PhoLife.
///
/// - **Music** — looping background music with dual-player crossfade.
/// - **Ambient** — looping ambient soundscape with dual-player crossfade.
/// - **SFX** — fire-and-forget pool of up to 8 one-shot players.
///
/// All access is `@MainActor`; `Timer` callbacks run on the main RunLoop,
/// so everything stays on the main actor without isolation issues.
@Observable
@MainActor
final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    // MARK: - Volume Targets

    private let musicVolume: Float = 0.4
    private let ambientVolume: Float = 0.3
    private let sfxVolume: Float = 0.7

    // MARK: - Music Players (dual for crossfade)

    private var musicPlayerA: AVAudioPlayer?
    private var musicPlayerB: AVAudioPlayer?
    /// `true` when player A is the *active* (audible) music player.
    private var musicActiveIsA: Bool = true

    // MARK: - Ambient Players (dual for crossfade)

    private var ambientPlayerA: AVAudioPlayer?
    private var ambientPlayerB: AVAudioPlayer?
    /// `true` when player A is the *active* (audible) ambient player.
    private var ambientActiveIsA: Bool = true

    // MARK: - SFX Pool

    private var sfxPlayers: [AVAudioPlayer] = []
    private let sfxPoolSize = 8

    // MARK: - Active Fade Timers

    private var musicFadeTimer: Timer?
    private var ambientFadeTimer: Timer?

    // MARK: - Init

    private init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {
            print("[AudioManager] Audio session setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - File Loading

    /// Attempts to locate an audio file in the bundle, trying .m4a, .mp3,
    /// and .caf extensions in order. Returns `nil` (never crashes) if the
    /// file is not found.
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

    /// A simple reference-type box so that a mutable counter can be
    /// captured in a `@Sendable` closure without triggering the
    /// "mutation of captured var in concurrently-executing code" warning.
    private final class StepCounter: @unchecked Sendable {
        var value: Int = 0
    }

    // MARK: - Crossfade Utility

    /// Drives a volume crossfade using a repeating `Timer`.
    ///
    /// - Parameters:
    ///   - outPlayer: The player being faded *out* (volume → 0, then stopped).
    ///   - inPlayer: The player being faded *in* (volume → `targetVolume`).
    ///   - targetVolume: Final volume for the incoming player.
    ///   - duration: Total crossfade time in seconds.
    ///   - onComplete: Called once the fade finishes. Use this to nil-out
    ///     the old player reference.
    /// - Returns: The `Timer` driving the fade, so the caller can invalidate
    ///   it if a new fade is requested before this one completes.
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

        // Start the incoming player at zero volume.
        inPlayer?.volume = 0
        inPlayer?.play()

        // Snapshot the outgoing player's starting volume so we can
        // decrement it proportionally.
        let outStartVolume = outPlayer?.volume ?? 0
        let outVolumeStep = outStartVolume / Float(steps)

        // Use nonisolated(unsafe) to satisfy strict concurrency for
        // players captured in the @Sendable Timer closure. This is safe
        // because the Timer fires on the main RunLoop (same as @MainActor).
        nonisolated(unsafe) let unsafeInPlayer = inPlayer
        nonisolated(unsafe) let unsafeOutPlayer = outPlayer

        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            // Timer fires on the main RunLoop, which is MainActor-safe.
            counter.value += 1
            let step = counter.value

            let done = step >= steps
            if done || self == nil {
                timer.invalidate()
            }

            MainActor.assumeIsolated {
                guard self != nil else { return }

                // Fade in
                let newVolume = min(volumeStep * Float(step), targetVolume)
                unsafeInPlayer?.volume = newVolume

                // Fade out
                let oldVolume = max(outStartVolume - outVolumeStep * Float(step), 0)
                unsafeOutPlayer?.volume = oldVolume

                if done {
                    // Ensure final volumes are exact.
                    unsafeInPlayer?.volume = targetVolume
                    unsafeOutPlayer?.stop()
                    unsafeOutPlayer?.volume = 0
                    onComplete()
                }
            }
        }

        return timer
    }

    /// Simple fade-out for a single player.
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

    // MARK: - Music

    /// Begin playing a looping music track, cross-fading from any
    /// currently playing music over `fadeDuration` seconds.
    func playMusic(_ filename: String, fadeDuration: TimeInterval = 1.0) {
        guard let newPlayer = loadPlayer(for: filename) else { return }

        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0

        // Cancel any in-progress music fade.
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

        // Flip active flag *before* the fade starts so subsequent calls
        // know which player is incoming.
        musicActiveIsA.toggle()

        musicFadeTimer = crossfade(
            from: outPlayer,
            to: newPlayer,
            targetVolume: musicVolume,
            duration: fadeDuration,
            onComplete: { [weak self] in
                guard let self else { return }
                // Nil out the old player to free memory.
                if self.musicActiveIsA {
                    self.musicPlayerB = nil
                } else {
                    self.musicPlayerA = nil
                }
                self.musicFadeTimer = nil
            }
        )
    }

    /// Fade out the current music track.
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

    // MARK: - Ambient

    /// Begin playing a looping ambient layer, cross-fading from any
    /// currently playing ambient track over `fadeDuration` seconds.
    func playAmbient(_ filename: String, fadeDuration: TimeInterval = 0.5) {
        guard let newPlayer = loadPlayer(for: filename) else { return }

        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0

        ambientFadeTimer?.invalidate()
        ambientFadeTimer = nil

        let outPlayer: AVAudioPlayer?
        if ambientActiveIsA {
            outPlayer = ambientPlayerA
            ambientPlayerB = newPlayer
        } else {
            outPlayer = ambientPlayerB
            ambientPlayerA = newPlayer
        }

        ambientActiveIsA.toggle()

        ambientFadeTimer = crossfade(
            from: outPlayer,
            to: newPlayer,
            targetVolume: ambientVolume,
            duration: fadeDuration,
            onComplete: { [weak self] in
                guard let self else { return }
                if self.ambientActiveIsA {
                    self.ambientPlayerB = nil
                } else {
                    self.ambientPlayerA = nil
                }
                self.ambientFadeTimer = nil
            }
        )
    }

    /// Fade out the current ambient layer.
    func stopAmbient(fadeDuration: TimeInterval = 0.5) {
        ambientFadeTimer?.invalidate()
        ambientFadeTimer = nil

        let activePlayer = ambientActiveIsA ? ambientPlayerA : ambientPlayerB

        ambientFadeTimer = fadeOut(player: activePlayer, duration: fadeDuration) { [weak self] in
            guard let self else { return }
            self.ambientPlayerA = nil
            self.ambientPlayerB = nil
            self.ambientFadeTimer = nil
        }
    }

    // MARK: - Sound Effects

    /// Fire-and-forget a short one-shot sound effect.
    ///
    /// Uses a pool of up to 8 players. If all are busy the oldest one is
    /// evicted and reused.
    func playSFX(_ filename: String) {
        guard let newPlayer = loadPlayer(for: filename) else { return }

        newPlayer.numberOfLoops = 0
        newPlayer.volume = sfxVolume

        // Try to find an idle slot.
        if let idleIndex = sfxPlayers.firstIndex(where: { !$0.isPlaying }) {
            sfxPlayers[idleIndex] = newPlayer
            newPlayer.play()
            return
        }

        // Pool is full and all playing — evict the oldest (index 0).
        if sfxPlayers.count >= sfxPoolSize {
            sfxPlayers[0].stop()
            sfxPlayers.removeFirst()
        }

        sfxPlayers.append(newPlayer)
        newPlayer.play()
    }

    // MARK: - Global

    /// Fade out all three layers simultaneously.
    func stopAll(fadeDuration: TimeInterval = 0.5) {
        stopMusic(fadeDuration: fadeDuration)
        stopAmbient(fadeDuration: fadeDuration)

        // SFX don't get a fade — just stop them immediately.
        for player in sfxPlayers {
            player.stop()
        }
        sfxPlayers.removeAll()
    }
}
