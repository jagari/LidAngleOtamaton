import SwiftUI

/// Full lid-open angle in degrees (used for display and arc calculations).
private let maxLidAngleDegrees: Double = 180

struct ContentView: View {
    @StateObject private var lidMonitor = LidAngleMonitor()
    @StateObject private var audioEngine = AudioEngine()

    @State private var selectedScale: Scale = .pentatonic
    @State private var useManualControl: Bool = false
    @State private var manualAngle: Double = 0.5

    // MARK: - Derived state

    private var activeAngle: Double {
        useManualControl ? manualAngle : lidMonitor.lidAngle
    }

    private var currentNote: Note {
        selectedScale.note(forAngle: activeAngle)
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 20) {
            headerView
            Divider()
            lidVisualisation
            noteDisplay
            Divider()
            controlsPanel
        }
        .padding(24)
        .frame(minWidth: 440, minHeight: 620)
        .onChange(of: activeAngle) { newAngle in
            let note = selectedScale.note(forAngle: newAngle)
            audioEngine.setFrequency(note.frequency)
        }
        .onChange(of: selectedScale) { newScale in
            let note = newScale.note(forAngle: activeAngle)
            audioEngine.setFrequency(note.frequency)
        }
        .onAppear {
            audioEngine.setFrequency(currentNote.frequency)
            // Show manual slider automatically when motion is unavailable.
            if !lidMonitor.isMotionAvailable {
                useManualControl = true
            }
        }
    }

    // MARK: - Sub-views

    private var headerView: some View {
        VStack(spacing: 4) {
            Text("LidAngle Otamaton")
                .font(.largeTitle.bold())
            Text("Use your MacBook lid angle as a musical instrument")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var lidVisualisation: some View {
        LidAngleView(angle: activeAngle)
            .frame(height: 180)
    }

    private var noteDisplay: some View {
        VStack(spacing: 6) {
            Text(currentNote.name)
                .font(.system(size: 56, weight: .bold, design: .rounded))
                .foregroundColor(.accentColor)
                .animation(.spring(response: 0.2), value: currentNote.name)
            Text(String(format: "%.1f Hz  •  %.0f°", currentNote.frequency, activeAngle * maxLidAngleDegrees))
                .font(.callout)
                .foregroundColor(.secondary)
        }
    }

    private var controlsPanel: some View {
        VStack(spacing: 16) {
            // Scale picker
            Picker("Scale", selection: $selectedScale) {
                ForEach(Scale.allCases) { scale in
                    Text(scale.rawValue).tag(scale)
                }
            }
            .pickerStyle(.segmented)

            // Manual angle override
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Toggle("Manual angle control", isOn: $useManualControl)
                    Spacer()
                    if !lidMonitor.isMotionAvailable {
                        Label("Motion unavailable", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                if useManualControl {
                    HStack(spacing: 8) {
                        Text("0°").font(.caption).foregroundColor(.secondary)
                        Slider(value: $manualAngle)
                    Text("\(Int(maxLidAngleDegrees))°").font(.caption).foregroundColor(.secondary)
                    }
                }
            }

            // Volume
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill").foregroundColor(.secondary)
                Slider(
                    value: Binding(
                        get: { Double(audioEngine.volume) },
                        set: { audioEngine.setVolume(Float($0)) }
                    )
                )
                Image(systemName: "speaker.wave.3.fill").foregroundColor(.secondary)
            }

            // Play / Stop
            Button(action: togglePlayback) {
                Label(
                    audioEngine.isPlaying ? "Stop" : "Play",
                    systemImage: audioEngine.isPlaying ? "stop.circle.fill" : "play.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .font(.title3.weight(.semibold))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(audioEngine.isPlaying ? .red : .accentColor)
        }
    }

    // MARK: - Actions

    private func togglePlayback() {
        audioEngine.isPlaying ? audioEngine.stop() : audioEngine.start()
    }
}

// MARK: - Lid angle visualisation

/// Draws a side-on MacBook silhouette that rotates to reflect the current lid angle.
struct LidAngleView: View {
    /// Normalised angle: 0 = closed, 1 = fully open (≈ 180°).
    let angle: Double

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let hingeX = w * 0.5
            let baseY  = h * 0.82
            let armLen = min(w, h) * 0.6

            // Keyboard base
            Path { p in
                p.move(to:    CGPoint(x: hingeX - armLen * 0.5, y: baseY))
                p.addLine(to: CGPoint(x: hingeX + armLen * 0.5, y: baseY))
            }
            .stroke(Color.secondary, style: StrokeStyle(lineWidth: 10, lineCap: .round))

            // Lid — rotates from left-flat (closed) to right-flat (fully open)
            let lidRad  = angle * Double.pi
            let lidEndX = hingeX + armLen * cos(lidRad)
            let lidEndY = baseY  - armLen * sin(lidRad)

            Path { p in
                p.move(to:    CGPoint(x: hingeX, y: baseY))
                p.addLine(to: CGPoint(x: lidEndX, y: lidEndY))
            }
            .stroke(
                LinearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.5)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 7, lineCap: .round)
            )

            // Arc showing the current angle
            Path { p in
                p.addArc(
                    center:     CGPoint(x: hingeX, y: baseY),
                    radius:     armLen * 0.28,
                    startAngle: .degrees(0),
                    endAngle:   .degrees(-angle * maxLidAngleDegrees),
                    clockwise:  true
                )
            }
            .stroke(Color.accentColor.opacity(0.35), lineWidth: 2)

            // Hinge dot
            Circle()
                .fill(Color.accentColor)
                .frame(width: 14, height: 14)
                .position(x: hingeX, y: baseY)

            // Angle label
            Text("\(Int(angle * maxLidAngleDegrees))°")
                .font(.caption.monospacedDigit())
                .foregroundColor(.accentColor)
                .position(
                    x: hingeX + armLen * 0.32 * cos(lidRad / 2),
                    y: baseY  - armLen * 0.32 * sin(lidRad / 2) - 8
                )
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
