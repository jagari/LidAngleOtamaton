import Foundation

// MARK: - Note

struct Note: Equatable {
    let name: String
    let frequency: Double
}

// MARK: - Scale

enum Scale: String, CaseIterable, Identifiable {
    case pentatonic = "Pentatonic"
    case major = "Major"
    case minor = "Minor"
    case chromatic = "Chromatic"

    var id: String { rawValue }

    var notes: [Note] {
        switch self {
        case .pentatonic:
            return [
                Note(name: "C4",  frequency: 261.63),
                Note(name: "D4",  frequency: 293.66),
                Note(name: "E4",  frequency: 329.63),
                Note(name: "G4",  frequency: 392.00),
                Note(name: "A4",  frequency: 440.00),
                Note(name: "C5",  frequency: 523.25),
                Note(name: "D5",  frequency: 587.33),
                Note(name: "E5",  frequency: 659.25),
                Note(name: "G5",  frequency: 783.99),
                Note(name: "A5",  frequency: 880.00)
            ]
        case .major:
            return [
                Note(name: "C4",  frequency: 261.63),
                Note(name: "D4",  frequency: 293.66),
                Note(name: "E4",  frequency: 329.63),
                Note(name: "F4",  frequency: 349.23),
                Note(name: "G4",  frequency: 392.00),
                Note(name: "A4",  frequency: 440.00),
                Note(name: "B4",  frequency: 493.88),
                Note(name: "C5",  frequency: 523.25),
                Note(name: "D5",  frequency: 587.33),
                Note(name: "E5",  frequency: 659.25),
                Note(name: "F5",  frequency: 698.46),
                Note(name: "G5",  frequency: 783.99),
                Note(name: "A5",  frequency: 880.00),
                Note(name: "B5",  frequency: 987.77)
            ]
        case .minor:
            return [
                Note(name: "C4",  frequency: 261.63),
                Note(name: "D4",  frequency: 293.66),
                Note(name: "Eb4", frequency: 311.13),
                Note(name: "F4",  frequency: 349.23),
                Note(name: "G4",  frequency: 392.00),
                Note(name: "Ab4", frequency: 415.30),
                Note(name: "Bb4", frequency: 466.16),
                Note(name: "C5",  frequency: 523.25),
                Note(name: "D5",  frequency: 587.33),
                Note(name: "Eb5", frequency: 622.25),
                Note(name: "F5",  frequency: 698.46),
                Note(name: "G5",  frequency: 783.99),
                Note(name: "Ab5", frequency: 830.61),
                Note(name: "Bb5", frequency: 932.33)
            ]
        case .chromatic:
            return [
                Note(name: "C4",  frequency: 261.63),
                Note(name: "C#4", frequency: 277.18),
                Note(name: "D4",  frequency: 293.66),
                Note(name: "D#4", frequency: 311.13),
                Note(name: "E4",  frequency: 329.63),
                Note(name: "F4",  frequency: 349.23),
                Note(name: "F#4", frequency: 369.99),
                Note(name: "G4",  frequency: 392.00),
                Note(name: "G#4", frequency: 415.30),
                Note(name: "A4",  frequency: 440.00),
                Note(name: "A#4", frequency: 466.16),
                Note(name: "B4",  frequency: 493.88),
                Note(name: "C5",  frequency: 523.25)
            ]
        }
    }

    /// Returns the note corresponding to the given normalised angle (0.0 – 1.0).
    func note(forAngle angle: Double) -> Note {
        let notes = self.notes
        let index = Int(angle * Double(notes.count))
        return notes[min(max(index, 0), notes.count - 1)]
    }
}
