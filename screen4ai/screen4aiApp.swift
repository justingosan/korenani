import SwiftUI
import AppKit

/**
 * Main entry point for the Screen4AI macOS application.
 *
 * This SwiftUI App creates a menu bar application that provides screen capture
 * functionality through a simple menu interface. The app uses an AppDelegate
 * to handle the core screenshot functionality and window management.
 *
 * Features:
 * - Menu bar presence with camera icon
 * - Screenshot capture via menu or global hotkey (Cmd+6)
 * - Settings interface
 * - Clean application quit functionality
 */
@main
struct screen4aiApp: App {
    /// Connect the AppDelegate to the SwiftUI App lifecycle for handling screenshot logic
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Screen4AI", systemImage: "camera.on.rectangle.fill") {
            Button("Take Screenshot") {
                appDelegate.takeScreenshot()
            }
            Divider()
            Button("Settings") {
                appDelegate.showSettings()
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
