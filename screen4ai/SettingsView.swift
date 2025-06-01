import SwiftUI
import AppKit

/**
 * SwiftUI view that provides the settings interface for Screen4AI.
 *
 * This view allows users to configure various aspects of the application including:
 * - Auto-start behavior at login
 * - Sound preferences for screenshot capture
 * - Save location for captured screenshots
 * - Current hotkey display
 *
 * The settings are presented in a clean, organized interface with clearly
 * separated sections for different categories of preferences.
 */
struct SettingsView: View {
    /// Whether the app should automatically start when the user logs in
    @State private var autoStartEnabled = true
    /// Whether to play a sound when taking a screenshot
    @State private var soundEnabled = false
    /// The location where screenshots should be saved
    @State private var saveLocation = "Desktop"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Screen4AI Settings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("General")
                    .font(.headline)
                
                Toggle("Start Screen4AI at login", isOn: $autoStartEnabled)
                
                Toggle("Play sound when taking screenshot", isOn: $soundEnabled)
                
                HStack {
                    Text("Save screenshots to:")
                    Spacer()
                    Picker("Save Location", selection: $saveLocation) {
                        Text("Desktop").tag("Desktop")
                        Text("Pictures").tag("Pictures")
                        Text("Downloads").tag("Downloads")
                        Text("Custom...").tag("Custom")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 120)
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Hotkey")
                    .font(.headline)
                
                HStack {
                    Text("Current hotkey:")
                    Spacer()
                    Text("⌘ + 6")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(4)
                        .font(.system(.body, design: .monospaced))
                }
                
                Text("Click to change hotkey")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack {
                Spacer()
                Button("Close") {
                    // Close the settings window
                    if let window = NSApp.keyWindow {
                        window.close()
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 400, height: 350)
    }
}

#Preview {
    SettingsView()
}
