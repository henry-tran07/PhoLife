import Foundation

/// Stub audio manager for PhoLife.
///
/// All methods are intentionally empty and will be fleshed out once
/// audio assets (music, ambient, SFX) are added to the bundle.
/// The manager exposes three independent layers -- music, ambient,
/// and one-shot sound effects -- each with fade-in / fade-out support.
@Observable
@MainActor
final class AudioManager {

    // MARK: - Singleton

    static let shared = AudioManager()

    private init() {}

    // MARK: - Music

    /// Begin playing a looping music track, cross-fading from any
    /// currently playing music over `fadeDuration` seconds.
    func playMusic(_ filename: String, fadeDuration: TimeInterval = 1.0) {}

    /// Fade out the current music track.
    func stopMusic(fadeDuration: TimeInterval = 0.5) {}

    // MARK: - Ambient

    /// Begin playing a looping ambient layer, cross-fading from any
    /// currently playing ambient track over `fadeDuration` seconds.
    func playAmbient(_ filename: String, fadeDuration: TimeInterval = 0.5) {}

    /// Fade out the current ambient layer.
    func stopAmbient(fadeDuration: TimeInterval = 0.5) {}

    // MARK: - Sound Effects

    /// Fire-and-forget a short one-shot sound effect.
    func playSFX(_ filename: String) {}

    // MARK: - Global

    /// Fade out all three layers simultaneously.
    func stopAll(fadeDuration: TimeInterval = 0.5) {}
}
