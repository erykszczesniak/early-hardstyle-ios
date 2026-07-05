import AVFAudio

/// Thin wrapper over the app's audio session. `.playback` + the `audio`
/// background mode is what lets playback continue when the app is backgrounded
/// (best effort for an embedded web player — see the README note).
enum AudioSession {
    /// Configures and activates the playback session. Called when playback
    /// starts (not at launch, so merely opening the app doesn't interrupt
    /// other audio).
    static func activatePlayback() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .moviePlayback)
        try? session.setActive(true)
    }
}
