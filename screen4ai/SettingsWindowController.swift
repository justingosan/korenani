import SwiftUI
import AppKit

/**
 * Window controller responsible for managing the settings window lifecycle.
 *
 * This class handles:
 * - Creating and displaying the settings window
 * - Ensuring only one settings window exists at a time
 * - Proper window cleanup and memory management
 * - Window positioning and configuration
 *
 * The controller uses the singleton pattern to ensure that multiple
 * requests to show settings reuse the same window instance.
 */
class SettingsWindowController {
    /// Reference to the current settings window, if one exists
    private var settingsWindow: NSWindow?
    
    /**
     * Shows the settings window, creating it if necessary.
     *
     * This method implements a singleton pattern for the settings window:
     * - If a settings window already exists, it brings it to the front
     * - If no window exists, it creates a new one with proper configuration
     *
     * The window is centered on the main screen and configured with
     * appropriate style masks for a settings interface.
     */
    func showSettings() {
        print("Show Settings action triggered")
        
        // If settings window already exists, bring it to front
        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new settings window
        guard let mainScreen = NSScreen.main else {
            print("Error: Could not get main screen.")
            return
        }
        
        let screenFrame = mainScreen.frame
        let windowWidth: CGFloat = 400
        let windowHeight: CGFloat = 350
        
        let windowX = (screenFrame.width - windowWidth) / 2
        let windowY = (screenFrame.height - windowHeight) / 2
        
        let windowRect = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        
        let settingsSwiftUIView = SettingsView()
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screen4AI Settings"
        window.contentView = NSHostingView(rootView: settingsSwiftUIView)
        window.isReleasedWhenClosed = false
        
        // Store the window reference
        settingsWindow = window
        
        // Set up notification observer for window closing
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            if let closingWindow = notification.object as? NSWindow,
               closingWindow === self?.settingsWindow {
                self?.handleSettingsWindowClosing()
            }
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    /**
     * Handles cleanup when the settings window is closed.
     *
     * This method:
     * 1. Removes the notification observer to prevent memory leaks
     * 2. Clears the window reference to allow proper deallocation
     * 3. Logs the window closure for debugging purposes
     */
    private func handleSettingsWindowClosing() {
        print("Settings window closed")
        
        // Remove the notification observer for settings window
        if let window = settingsWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        }
        
        settingsWindow = nil
    }
    
    /**
     * Cleanup method called when the controller is deallocated.
     *
     * Ensures that any remaining notification observers are properly
     * removed to prevent memory leaks or dangling references.
     */
    deinit {
        // Clean up any remaining observers
        if let window = settingsWindow {
            NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
        }
    }
}
