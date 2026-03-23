import AVFoundation
import Foundation

/// Sine-wave tone synthesiser backed by `AVAudioEngine`.
///
/// Call `start()` to begin playback and `stop()` to silence it.
/// Use `setFrequency(_:)` to change the pitch in real time without clicks.
final class AudioEngine: ObservableObject {
    @Published var isPlaying: Bool = false
    @Published var currentFrequency: Double = 261.63
    @Published var volume: Float = 0.7

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    // Audio state – accessed from both the main thread and the real-time render
    // thread, protected by a lock.  A lightweight os_unfair_lock keeps the
    // critical section very short so it is safe to acquire from the render thread.
    private var renderLock = os_unfair_lock_s()
    private var _phase: Double = 0.0
    private var _targetFrequency: Double = 261.63
    private var _renderVolume: Float = 0.7
    private var _sampleRate: Double = 44100.0

    init() { setupEngine() }

    // MARK: - Setup

    private func setupEngine() {
        let outputFormat = engine.outputNode.outputFormat(forBus: 0)
        _sampleRate = outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100.0

        guard let format = AVAudioFormat(
            standardFormatWithSampleRate: _sampleRate,
            channels: 2
        ) else { return }

        sourceNode = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)

            // Snapshot mutable parameters under the lock so the render thread
            // always sees a consistent pair of values.
            os_unfair_lock_lock(&self.renderLock)
            let freq   = self._targetFrequency
            let vol    = self._renderVolume
            var phase  = self._phase
            os_unfair_lock_unlock(&self.renderLock)

            let phaseStep = 2.0 * Double.pi * freq / self._sampleRate

            for frame in 0..<Int(frameCount) {
                let sample = Float(sin(phase)) * vol * 0.5
                phase += phaseStep
                if phase >= 2.0 * Double.pi { phase -= 2.0 * Double.pi }

                for buffer in ablPointer {
                    buffer.mData?.assumingMemoryBound(to: Float.self)[frame] = sample
                }
            }

            os_unfair_lock_lock(&self.renderLock)
            self._phase = phase
            os_unfair_lock_unlock(&self.renderLock)

            return noErr
        }

        guard let node = sourceNode else { return }
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0
    }

    // MARK: - Playback control

    func start() {
        guard !isPlaying else { return }
        do {
            try engine.start()
            engine.mainMixerNode.outputVolume = volume
            isPlaying = true
        } catch {
            print("AudioEngine failed to start: \(error)")
        }
    }

    func stop() {
        engine.mainMixerNode.outputVolume = 0
        engine.stop()
        isPlaying = false
    }

    // MARK: - Parameter control

    /// Thread-safe frequency update (call from the main thread).
    func setFrequency(_ frequency: Double) {
        os_unfair_lock_lock(&renderLock)
        _targetFrequency = frequency
        os_unfair_lock_unlock(&renderLock)
        DispatchQueue.main.async { self.currentFrequency = frequency }
    }

    func setVolume(_ vol: Float) {
        volume = vol
        os_unfair_lock_lock(&renderLock)
        _renderVolume = vol
        os_unfair_lock_unlock(&renderLock)
        if isPlaying { engine.mainMixerNode.outputVolume = vol }
    }
}
