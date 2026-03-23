# LidAngleOtamaton

Make your MacBook an exciting instrument by opening and closing your laptop's lid.

## How it works

LidAngle Otamaton reads the MacBook's built-in motion sensor (via **CoreMotion**) to
determine the lid angle in real time. As you open or close the lid the app maps the
angle (0 ° – 180 °) to a musical note and plays the tone through **AVAudioEngine**,
turning the hinge of your MacBook into a theremin-style instrument.

If the motion sensor is not available on your machine a **Manual angle slider** is
shown so you can still try out the instrument.

## Features

| Feature | Details |
|---------|---------|
| Lid-angle detection | CoreMotion `CMMotionManager` (device motion or raw accelerometer) |
| Audio synthesis | Real-time sine-wave oscillator via `AVAudioEngine` + `AVAudioSourceNode` |
| Scales | Pentatonic · Major · Minor · Chromatic |
| Visual feedback | Side-on MacBook silhouette rotates to show the current angle |
| Manual override | Slider replaces sensor when motion is unavailable |

## Requirements

- macOS 12 Monterey or later
- Swift 5.7 +

## Building

```bash
swift build -c release
.build/release/LidAngleOtamaton
```

Or open the package in Xcode and press ⌘R.

