import Foundation
import Security

/**
 * Manages secure storage and retrieval of sensitive data using the macOS Keychain.
 *
 * This class provides a secure way to store sensitive information like API keys,
 * passwords, and tokens using the system keychain instead of UserDefaults.
 * 
 * The keychain provides encryption and secure access control, making it the
 * recommended approach for storing credentials and other sensitive data.
 */
class KeychainManager {
    /// Shared singleton instance
    static let shared = KeychainManager()
    
    /// Service identifier for keychain items
    private let service = "com.thikingpandas.korenani"
    
    private init() {}
    
    /**
     * Stores a value securely in the keychain.
     *
     * - Parameters:
     *   - key: The key to store the value under
     *   - value: The string value to store
     * - Returns: Boolean indicating success or failure
     */
    func store(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("KeychainManager: Failed to convert value to data")
            return false
        }
        
        // First, try to delete any existing item
        delete(key: key)
        
        // Create the keychain query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            print("KeychainManager: Successfully stored \(key)")
            return true
        } else {
            print("KeychainManager: Failed to store \(key), status: \(status)")
            return false
        }
    }
    
    /**
     * Retrieves a value securely from the keychain.
     *
     * - Parameter key: The key to retrieve the value for
     * - Returns: The stored string value, or nil if not found
     */
    func retrieve(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8) {
            print("KeychainManager: Successfully retrieved \(key)")
            return value
        } else if status == errSecItemNotFound {
            print("KeychainManager: Item not found for \(key)")
            return nil
        } else {
            print("KeychainManager: Failed to retrieve \(key), status: \(status)")
            return nil
        }
    }
    
    /**
     * Deletes a value from the keychain.
     *
     * - Parameter key: The key to delete
     * - Returns: Boolean indicating success or failure
     */
    @discardableResult
    func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status == errSecSuccess || status == errSecItemNotFound {
            print("KeychainManager: Successfully deleted \(key)")
            return true
        } else {
            print("KeychainManager: Failed to delete \(key), status: \(status)")
            return false
        }
    }
    
    /**
     * Updates an existing value in the keychain.
     *
     * - Parameters:
     *   - key: The key to update
     *   - value: The new string value
     * - Returns: Boolean indicating success or failure
     */
    func update(key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            print("KeychainManager: Failed to convert value to data")
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let updates: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, updates as CFDictionary)
        
        if status == errSecSuccess {
            print("KeychainManager: Successfully updated \(key)")
            return true
        } else if status == errSecItemNotFound {
            // Item doesn't exist, so store it instead
            return store(key: key, value: value)
        } else {
            print("KeychainManager: Failed to update \(key), status: \(status)")
            return false
        }
    }
    
    /**
     * Checks if a key exists in the keychain.
     *
     * - Parameter key: The key to check
     * - Returns: Boolean indicating if the key exists
     */
    func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}

// MARK: - Convenience Extensions for KoreNani
extension KeychainManager {
    /// Keys for KoreNani specific data
    enum KoreNaniKeys {
        static let openAIAPIKey = "openai_api_key"
    }
    
    /// Store OpenAI API Key securely
    func storeOpenAIAPIKey(_ key: String) -> Bool {
        return store(key: KoreNaniKeys.openAIAPIKey, value: key)
    }
    
    /// Retrieve OpenAI API Key securely
    func retrieveOpenAIAPIKey() -> String? {
        return retrieve(key: KoreNaniKeys.openAIAPIKey)
    }
    
    /// Delete OpenAI API Key
    func deleteOpenAIAPIKey() -> Bool {
        return delete(key: KoreNaniKeys.openAIAPIKey)
    }
    
    /// Check if OpenAI API Key exists
    func hasOpenAIAPIKey() -> Bool {
        return exists(key: KoreNaniKeys.openAIAPIKey)
    }
}
