import SwiftUI

@main
struct LidAngleOtamatonApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {
                Link(
                    "About LidAngle Otamaton",
                    destination: URL(string: "https://github.com/jagari/LidAngleOtamaton")!
                )
            }
        }
    }
}
