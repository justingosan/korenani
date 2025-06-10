import SwiftUI
import AppKit
import Carbon

/**
 * Individual row component for displaying permission status in the settings.
 *
 * Shows the permission name, status icon, description, and action button if needed.
 */
struct PermissionRow: View {
    let permission: PermissionStatus
    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: permission.isGranted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundColor(permission.isGranted ? .green : .orange)
                    .font(.system(size: 16))

                Text(permission.name)
                    .fontWeight(.medium)

                Spacer()

                if !permission.isGranted {
                    Button("Open System Settings") {
                        SettingsManager.shared.openSystemPreferences(for: permission)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else {
                    Button("System Settings") {
                        SettingsManager.shared.openSystemPreferences(for: permission)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }

            Text(permission.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 24) // Align with text after icon

            if !permission.isGranted {
                Text("Required for app functionality")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.leading, 24)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(
                    permission.isGranted ?
                        (isHovered ? NSColor.systemGreen.withAlphaComponent(0.1) : NSColor.systemGreen.withAlphaComponent(0.05)) :
                        (isHovered ? NSColor.systemOrange.withAlphaComponent(0.1) : NSColor.systemOrange.withAlphaComponent(0.05))
                ))
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

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

    /// State for hotkey recording
    @State private var isRecordingHotkey = false
    @State private var recordedKeyCode: UInt16?
    @State private var recordedModifiers: UInt32?

    var body: some View {
        ScrollView {
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

                Toggle("Hide dock icon", isOn: $settings.hideDockIcon)
                    .help("When enabled, KoreNani will run in the background without a dock icon")

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

                VStack(alignment: .leading, spacing: 8) {
                    Text("AI Prompt Template")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    TextEditor(text: $settings.aiPrompt)
                        .frame(height: 80)
                        .padding(8) // Adding inner margin
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .help("Customize the prompt that will be sent to AI when analyzing screenshots")

                    Text("This prompt will be used when analyzing screenshots with AI. You can customize it to get the type of analysis you want.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Permissions")
                    .font(.headline)

                Text("KoreNani requires the following permissions to function properly:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(settings.checkPermissions(), id: \.name) { permission in
                    PermissionRow(permission: permission)
                }

                Button("Refresh Permission Status") {
                    // This is for UI reactivity - it will trigger a refresh of the permission checks
                    settings.objectWillChange.send()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .padding(.top, 4)
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("Hotkeys")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Window capture:")
                        Spacer()
                        Text(settings.getHotkeyDisplayString())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                            .font(.system(.body, design: .monospaced))
                            .onTapGesture {
                                startRecording()
                            }
                            .help("Click to change hotkey")
                            .contentShape(Rectangle()) // Makes the entire area clickable
                    }


                }

                if isRecordingHotkey {
                    VStack(spacing: 12) {
                        Text("Press any key combination for window capture hotkey...")
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.orange, lineWidth: 2)
                                    .background(Color.orange.opacity(0.1).cornerRadius(8))
                            )

                        HStack {
                            Button("Cancel") {
                                stopRecording(save: false)
                            }
                            .buttonStyle(.bordered)

                            Spacer()
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    VStack(spacing: 8) {
                        HStack {
                            Button("Reset to Default (⌘6)") {
                                settings.hotkeyKeyCode = 22 // Key code for '6'
                                settings.hotkeyModifiers = 256 // Cmd key
                            }
                            .buttonStyle(.bordered)
                        }


                    }
                    .padding(.vertical, 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("• Window capture: Captures the currently active window")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Note: Hotkeys require accessibility permission to work properly")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
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
        }
        .frame(width: 400)
        .frame(minHeight: 650)
        .onAppear {
            // Start listening for key events when the view appears
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if self.isRecordingHotkey {
                    self.handleKeyEvent(event)
                    return nil // Consume the event
                }
                return event // Pass through other events
            }
        }
    }

    private func startRecording() {
        isRecordingHotkey = true
        recordedKeyCode = nil
        recordedModifiers = nil
        // Make the window key to capture events
        NSApp.keyWindow?.makeKey()
    }

    private func stopRecording(save: Bool = false) {
        isRecordingHotkey = false
        if save, let keyCode = recordedKeyCode, let modifiers = recordedModifiers {
            settings.hotkeyKeyCode = keyCode
            settings.hotkeyModifiers = modifiers
            print("New hotkey saved: \(keyCode), \(modifiers)")
        } else {
            print("Hotkey recording cancelled or no key pressed")
        }
        recordedKeyCode = nil
        recordedModifiers = nil
    }

    private func handleKeyEvent(_ event: NSEvent) {
        guard isRecordingHotkey else { return }

        // Ignore modifier-only key presses for now, decide if we want to allow this
        if event.modifierFlags.isDisjoint(with: .deviceIndependentFlagsMask) && event.keyCode < 128 {
             // This means it's a character key without just modifiers
        } else if !event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty && event.charactersIgnoringModifiers == nil {
            // This means it's only a modifier key or combination of modifier keys
            // We might want to allow this, or require a non-modifier key.
            // For now, let's just store it if it's not empty.
            if event.keyCode >= 0 { // Ensure there's some key data
                 // Storing modifier-only presses might be complex for display/registration.
                 // Let's require a non-modifier key for now.
                 print("Modifier-only key press detected, ignoring for now.")
                 return
            }
        }


        // Capture key code and modifiers
        // We need to filter out the modifier flags from the key code if it's a modifier key itself
        let keyCode = event.keyCode
        var carbonModifiers = UInt32(0)

        if event.modifierFlags.contains(.command) {
            carbonModifiers |= UInt32(cmdKey)
        }
        if event.modifierFlags.contains(.option) {
            carbonModifiers |= UInt32(optionKey)
        }
        if event.modifierFlags.contains(.control) {
            carbonModifiers |= UInt32(controlKey)
        }
        if event.modifierFlags.contains(.shift) {
            carbonModifiers |= UInt32(shiftKey)
        }
        // Also consider capsLock if needed, though less common for hotkeys
        // if event.modifierFlags.contains(.capsLock) {
        //     carbonModifiers |= UInt32(alphaLock)
        // }


        // Ensure at least one non-modifier key is pressed OR a modifier is part of the combo
        // This logic might need refinement based on desired behavior for modifier-only hotkeys
        let isModifierKeyItself = [kVK_Command, kVK_Shift, kVK_Option, kVK_Control, kVK_CapsLock].contains(Int(keyCode))

        if !isModifierKeyItself || carbonModifiers != 0 {
            recordedKeyCode = keyCode
            recordedModifiers = carbonModifiers
            print("Recorded: keyCode=\(keyCode), modifiers=\(carbonModifiers)")
            // Automatically stop recording and save after a valid combination
            stopRecording(save: true)
        } else {
            print("Detected modifier key press without other keys or modifiers. Please press a combination.")
            // Optionally, provide feedback to the user here
        }
    }

    // Extension to make accessibility checks available directly
    private func checkAccessibilityPermission() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

#Preview {
    SettingsView()
}
