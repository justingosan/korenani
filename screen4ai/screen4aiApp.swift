import SwiftUI
import AppKit

@main
struct screen4aiApp: App {
    // Connect the AppDelegate (now in AppDelegate.swift) to the SwiftUI App lifecycle
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Screen4AI", systemImage: "camera.on.rectangle.fill") {
            Button("Take Screenshot") {
                appDelegate.takeScreenshot()
            }
            Divider()
            Button("Quit Screen4AI") {
                NSApplication.shared.terminate(nil) // NSApplication is part of AppKit, but this usage is common in SwiftUI apps for quitting.
                                                    // If this causes an issue, we might need to import AppKit here too, or call quit via AppDelegate.
            }
        }
        // Note: No WindowGroup here for a main window. Windows are created on demand.
    }
}
