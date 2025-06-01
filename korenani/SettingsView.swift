import SwiftUI
import AppKit

/**
 * SwiftUI view that provides the settings interface for KoreNani.
 *
 * This view allows users to configure various aspects of the application including:
 * - Auto-start behavior at login
 * - Sound preferences for screenshot capture
 * - Save location for captured screenshots
 * - Current hotkey display
 *
 * The settings are presented in a clean, organized interface with clearly
 * separated sections for different categories of preferences.
 * Settings are automatically persisted through the SettingsManager.
 */
struct SettingsView: View {
    /// Observed settings manager for reactive UI updates
    @ObservedObject private var settings = SettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("KoreNani Settings")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.bottom, 10)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("General")
                    .font(.headline)
                
                Toggle("Start KoreNani at login", isOn: $settings.autoStartEnabled)
                
                Toggle("Play sound when taking screenshot", isOn: $settings.soundEnabled)
                
                HStack {
                    Text("Save screenshots to:")
                    Spacer()
                    Picker("Save Location", selection: $settings.saveLocation) {
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
                Text("OpenAI Integration")
                    .font(.headline)
                
                HStack {
                    Text("API Key:")
                    Spacer()
                }
                
                SecureField("Enter your OpenAI API key", text: $settings.openAIAPIKey)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .help("Your OpenAI API key will be stored securely in Keychain")
                
                if !settings.openAIAPIKey.isEmpty {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("API key configured")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("API key required for AI features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
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
        .frame(width: 400, height: 520)
    }
}

#Preview {
    SettingsView()
}
