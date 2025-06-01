import Foundation
import SwiftUI

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
        openAIAPIKey = "" // This will delete it from keychain
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
}
