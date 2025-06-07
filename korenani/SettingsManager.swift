import Foundation
import SwiftUI
import ScreenCaptureKit
import ServiceManagement
import Carbon

/**
 * Represents the status of a required permission
 */
struct PermissionStatus {
    let name: String
    let isGranted: Bool
    let description: String
    let helpURL: String?
}

/**
 * Centralized settings manager for KoreNani application preferences.
 *
 * This class handles persistence and management of user settings using UserDefaults
 * for general preferences and Keychain for sensitive data like API keys.
 * It provides a shared instance and publishes changes to allow SwiftUI views
 * to react to settings updates.
 *
 * Supported settings:
 * - Auto-start at login behavior
 * - Sound preferences for screenshot capture
 * - Save location for captured screenshots
 * - OpenAI API key (stored securely in Keychain)
 */
class SettingsManager: ObservableObject {
    /// Shared singleton instance for accessing settings throughout the app
    static let shared = SettingsManager()
    
    /// Keys for storing settings in UserDefaults
    private enum SettingsKeys {
        static let autoStartEnabled = "autoStartEnabled"
        static let soundEnabled = "soundEnabled"
        static let saveLocation = "saveLocation"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let hideDockIcon = "hideDockIcon"
        static let aiPrompt = "aiPrompt"
        // Note: openAIAPIKey is now stored in Keychain, not UserDefaults
    }
    
    /// Whether the app should automatically start when the user logs in
    @Published var autoStartEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoStartEnabled, forKey: SettingsKeys.autoStartEnabled)
        }
    }
    
    /// Whether to play a sound when taking a screenshot
    @Published var soundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEnabled, forKey: SettingsKeys.soundEnabled)
        }
    }
    
    /// The location where screenshots should be saved
    @Published var saveLocation: String {
        didSet {
            UserDefaults.standard.set(saveLocation, forKey: SettingsKeys.saveLocation)
        }
    }
    
    /// The OpenAI API key for AI processing features (stored securely in Keychain)
    @Published var openAIAPIKey: String {
        didSet {
            if openAIAPIKey.isEmpty {
                // If the key is empty, delete it from keychain
                _ = KeychainManager.shared.deleteOpenAIAPIKey()
            } else {
                // Store the key securely in keychain
                if !KeychainManager.shared.storeOpenAIAPIKey(openAIAPIKey) {
                    print("SettingsManager: Failed to store OpenAI API key in keychain")
                }
            }
        }
    }
    
    /// The key code for the screenshot hotkey
    @Published var hotkeyKeyCode: UInt16 {
        didSet {
            UserDefaults.standard.set(hotkeyKeyCode, forKey: SettingsKeys.hotkeyKeyCode)
            // Notify that hotkey changed so AppDelegate can re-register
            NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
        }
    }
    
    /// The modifier flags for the screenshot hotkey
    @Published var hotkeyModifiers: UInt32 {
        didSet {
            UserDefaults.standard.set(hotkeyModifiers, forKey: SettingsKeys.hotkeyModifiers)
            // Notify that hotkey changed so AppDelegate can re-register
            NotificationCenter.default.post(name: .hotkeyChanged, object: nil)
        }
    }
    
    /// Whether the app's dock icon should be hidden
    @Published var hideDockIcon: Bool {
        didSet {
            UserDefaults.standard.set(hideDockIcon, forKey: SettingsKeys.hideDockIcon)
            // Apply the change immediately
            applyDockIconVisibility()
        }
    }
    
    /// The AI prompt template for analyzing screenshots
    @Published var aiPrompt: String {
        didSet {
            UserDefaults.standard.set(aiPrompt, forKey: SettingsKeys.aiPrompt)
        }
    }
    
    /**
     * Private initializer to ensure singleton pattern.
     *
     * Loads existing settings from UserDefaults or sets default values
     * if no settings have been saved previously. API key is loaded from Keychain.
     */
    private init() {
        // Load existing settings or set defaults
        self.autoStartEnabled = UserDefaults.standard.object(forKey: SettingsKeys.autoStartEnabled) as? Bool ?? true
        self.soundEnabled = UserDefaults.standard.object(forKey: SettingsKeys.soundEnabled) as? Bool ?? false
        self.saveLocation = UserDefaults.standard.string(forKey: SettingsKeys.saveLocation) ?? "Desktop"
        
        // Load hotkey settings or set defaults (Cmd+6 for full screen)
        self.hotkeyKeyCode = UInt16(UserDefaults.standard.object(forKey: SettingsKeys.hotkeyKeyCode) as? Int ?? 22) // 22 is key code for '6'
        self.hotkeyModifiers = UInt32(UserDefaults.standard.object(forKey: SettingsKeys.hotkeyModifiers) as? Int ?? 256) // 256 is cmdKey
        
        // Load dock icon visibility setting or default to showing (false = show icon)
        self.hideDockIcon = UserDefaults.standard.bool(forKey: SettingsKeys.hideDockIcon)
        
        // Load AI prompt or set default
        self.aiPrompt = UserDefaults.standard.string(forKey: SettingsKeys.aiPrompt) ?? "What do you see in this screenshot? Please describe the content and any notable elements."
        
        // Load OpenAI API key from Keychain (secure storage)
        self.openAIAPIKey = KeychainManager.shared.retrieveOpenAIAPIKey() ?? ""
        
        // Migration: Check if there's an old API key in UserDefaults and migrate it
        migrateAPIKeyFromUserDefaults()
    }
    
    /**
     * Resets all settings to their default values.
     *
     * This method can be used to provide a "reset to defaults" functionality
     * in the settings interface.
     */
    func resetToDefaults() {
        autoStartEnabled = true
        soundEnabled = false
        saveLocation = "Desktop"
        hotkeyKeyCode = 22 // '6' key
        hotkeyModifiers = 256 // Cmd key
        openAIAPIKey = "" // This will delete it from keychain
    }
    
    /**
     * Gets a human-readable string representation of the current hotkey.
     *
     * - Returns: String like "⌘ + 6" representing the current hotkey
     */
    func getHotkeyDisplayString() -> String {
        var modifierString = ""
        
        // Convert modifier flags to symbols
        if hotkeyModifiers & UInt32(controlKey) != 0 { modifierString += "⌃ + " }
        if hotkeyModifiers & UInt32(optionKey) != 0 { modifierString += "⌥ + " }
        if hotkeyModifiers & UInt32(shiftKey) != 0 { modifierString += "⇧ + " }
        if hotkeyModifiers & UInt32(cmdKey) != 0 { modifierString += "⌘ + " }
        
        // Convert key code to character
        let keyString = keyCodeToString(hotkeyKeyCode)
        
        return modifierString + keyString
    }
    
    /**
     * Converts a key code to its string representation.
     *
     * - Parameter keyCode: The key code to convert
     * - Returns: String representation of the key
     */
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyCodeMap: [UInt16: String] = [
            18: "1", 19: "2", 20: "3", 21: "4", 23: "5", 22: "6", 26: "7", 28: "8", 25: "9", 29: "0",
            0: "A", 11: "B", 8: "C", 2: "D", 14: "E", 3: "F", 5: "G", 4: "H", 34: "I", 38: "J",
            40: "K", 37: "L", 46: "M", 45: "N", 31: "O", 35: "P", 12: "Q", 15: "R", 1: "S", 17: "T",
            32: "U", 9: "V", 13: "W", 7: "X", 16: "Y", 6: "Z",
            49: "Space", 36: "Return", 53: "Escape", 51: "Delete", 117: "Forward Delete",
            123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        
        return keyCodeMap[keyCode] ?? "Unknown"
    }
    
    /**
     * Migrates the OpenAI API key from UserDefaults to Keychain if it exists.
     *
     * This is a one-time migration function to move existing API keys to secure storage.
     */
    private func migrateAPIKeyFromUserDefaults() {
        // Check if there's an old API key in UserDefaults
        if let oldAPIKey = UserDefaults.standard.string(forKey: "openAIAPIKey"), 
           !oldAPIKey.isEmpty,
           !KeychainManager.shared.hasOpenAIAPIKey() {
            
            print("SettingsManager: Migrating API key from UserDefaults to Keychain")
            
            // Store it in Keychain
            if KeychainManager.shared.storeOpenAIAPIKey(oldAPIKey) {
                // Successfully migrated, remove from UserDefaults
                UserDefaults.standard.removeObject(forKey: "openAIAPIKey")
                print("SettingsManager: Successfully migrated API key to Keychain")
                
                // Update our property to reflect the migrated key
                self.openAIAPIKey = oldAPIKey
            } else {
                print("SettingsManager: Failed to migrate API key to Keychain")
            }
        }
    }
    
    /**
     * Checks the status of all required permissions for the app to function properly.
     *
     * - Returns: Array of PermissionStatus objects representing each required permission
     */
    func checkPermissions() -> [PermissionStatus] {
        var permissions: [PermissionStatus] = []
        
        // Screen Capture Permission
        let screenCaptureGranted = checkScreenCapturePermission()
        permissions.append(PermissionStatus(
            name: "Screen Recording",
            isGranted: screenCaptureGranted,
            description: "Required to capture screenshots of windows and screen content",
            helpURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        ))
        
        // Accessibility Permission (required for hotkeys)
        let accessibilityGranted = checkAccessibilityPermission()
        permissions.append(PermissionStatus(
            name: "Accessibility",
            isGranted: accessibilityGranted,
            description: "Required for global hotkey functionality",
            helpURL: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ))
        
        return permissions
    }
    
    /**
     * Checks if screen capture permission is granted.
     *
     * - Returns: Boolean indicating if screen recording permission is available
     */
    private func checkScreenCapturePermission() -> Bool {
        if #available(macOS 11.0, *) {
            // For macOS 11+, we can check if we can get shareable content
            let semaphore = DispatchSemaphore(value: 0)
            var hasPermission = false
            
            Task {
                do {
                    _ = try await SCShareableContent.current
                    hasPermission = true
                } catch {
                    hasPermission = false
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            return hasPermission
        } else {
            // For older macOS versions, assume permission is granted
            return true
        }
    }
    
    /**
     * Checks if accessibility permission is granted.
     * 
     * - Returns: Boolean indicating if accessibility permission is available
     */
    private func checkAccessibilityPermission() -> Bool {
        // Check if the application has accessibility permissions
        // This is needed for global hotkey registration
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: false]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    

    
    /**
     * Requests screen capture permission by attempting to access shareable content.
     */
    func requestScreenCapturePermission() {
        if #available(macOS 11.0, *) {
            Task {
                do {
                    _ = try await SCShareableContent.current
                } catch {
                    print("Screen capture permission denied: \(error)")
                }
            }
        }
    }
    
    /**
     * Opens the System Preferences to the appropriate privacy settings.
     *
     * - Parameter permissionType: The type of permission to open settings for
     */
    func openSystemPreferences(for permission: PermissionStatus) {
        if let urlString = permission.helpURL,
           let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /**
     * Applies the dock icon visibility setting by updating the activation policy.
     */
    private func applyDockIconVisibility() {
        // Get the shared application instance
        let app = NSApplication.shared
        
        // Set the activation policy based on the setting
        if hideDockIcon {
            // Hide the dock icon by setting the app as an accessory
            app.setActivationPolicy(.accessory)
        } else {
            // Show the dock icon by setting the app as a regular application
            app.setActivationPolicy(.regular)
        }
        
        // Don't activate the app to keep it in the background
    }
}
