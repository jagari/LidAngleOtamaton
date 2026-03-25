import Foundation
#if canImport(CoreMotion) && !os(macOS)
import CoreMotion
#endif

/// Monitors the MacBook lid angle using CoreMotion.
///
/// The reported `lidAngle` is a value in [0, 1] where
/// 0 ≈ lid closed / flat and 1 ≈ lid fully open (≈ 180°).
///
/// If the device motion sensor is unavailable (e.g. on unsupported hardware)
/// `isMotionAvailable` is `false` and the angle stays at its initial value so
/// the user can control it manually via the UI slider.
final class LidAngleMonitor: ObservableObject {
    /// Normalised lid angle in [0, 1].
    @Published var lidAngle: Double = 0.5
    /// Raw pitch in radians (for debug display).
    @Published var rawPitch: Double = 0.0
    /// Whether CoreMotion data is available on this Mac.
    @Published var isMotionAvailable: Bool = false

#if canImport(CoreMotion) && !os(macOS)
    private let motionManager = CMMotionManager()
#endif
    private let updateInterval: TimeInterval = 1.0 / 30.0

    init() { startMonitoring() }

    // MARK: - Monitoring

    func startMonitoring() {
#if canImport(CoreMotion) && !os(macOS)
        if motionManager.isDeviceMotionAvailable {
            startDeviceMotion()
        } else if motionManager.isAccelerometerAvailable {
            startAccelerometer()
        }
        // If neither is available, isMotionAvailable stays false and the UI
        // will prompt the user to use the manual slider.
#else
        // CoreMotion lid sensing is not available on macOS in this package build.
        isMotionAvailable = false
#endif
    }

#if canImport(CoreMotion) && !os(macOS)
    private func startDeviceMotion() {
        isMotionAvailable = true
        motionManager.deviceMotionUpdateInterval = updateInterval
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let pitch = motion.attitude.pitch   // radians, −π/2 … +π/2
            self.rawPitch = pitch
            // Map −π/2 … +π/2 → 0 … 1
            self.lidAngle = ((pitch + .pi / 2) / .pi).clamped(to: 0...1)
        }
    }

    private func startAccelerometer() {
        isMotionAvailable = true
        motionManager.accelerometerUpdateInterval = updateInterval
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self, let data else { return }
            let ax = data.acceleration.x
            let ay = data.acceleration.y
            let az = data.acceleration.z
            // Pitch = rotation around the x-axis.  atan2(ay, √(ax²+az²)) gives the
            // angle between the horizontal plane and the acceleration vector, which
            // approximates the chassis tilt (and therefore the lid angle).
            let pitch = atan2(ay, sqrt(ax * ax + az * az))
            self.rawPitch = pitch
            self.lidAngle = ((pitch + .pi / 2) / .pi).clamped(to: 0...1)
        }
    }
#endif

    func stopMonitoring() {
#if canImport(CoreMotion) && !os(macOS)
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
#endif
    }

    deinit { stopMonitoring() }
}

// MARK: - Comparable helpers

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
