import Foundation
import AppKit

/**
 * Manages audio playback for KoreNani application events.
 *
 * This class provides functionality to play system sounds or custom audio files
 * for various application events, particularly screenshot capture.
 *
 * The manager supports both system sounds (using NSSound) and can be extended
 * to support custom audio files if needed in the future.
 */
class SoundManager {
    /// Shared singleton instance for managing sounds throughout the app
    static let shared = SoundManager()
    
    /// Pre-loaded system sound for screenshot capture
    private var screenshotSound: NSSound?
    
    /**
     * Private initializer to ensure singleton pattern.
     *
     * Initializes and prepares the screenshot sound for immediate playback
     * when needed.
     */
    private init() {
        setupScreenshotSound()
    }
    
    /**
     * Sets up the screenshot sound effect.
     *
     * This method loads a system sound that will be played when a screenshot
     * is captured. It uses the "Grab" system sound which is the standard
     * macOS screenshot sound.
     *
     * If the system sound is not available, it falls back to creating a
     * custom brief click sound.
     */
    private func setupScreenshotSound() {
        // Use the system screenshot sound ("Grab" sound)
        if let sound = NSSound(named: "Grab") {
            screenshotSound = sound
            print("Screenshot sound loaded: Grab")
        } else {
            // Fallback: try to use a generic system sound
            if let sound = NSSound(named: "Glass") {
                screenshotSound = sound
                print("Screenshot sound loaded: Glass (fallback)")
            } else {
                print("Warning: No screenshot sound available")
            }
        }
    }
    
    /**
     * Plays the screenshot capture sound.
     *
     * This method plays the pre-loaded screenshot sound if available.
     * The sound playback is non-blocking and will not interfere with
     * the screenshot capture process.
     *
     * The method includes error handling to ensure that sound playback
     * failures don't affect the core screenshot functionality.
     */
    func playScreenshotSound() {
        guard let sound = screenshotSound else {
            print("No screenshot sound available to play")
            return
        }
        
        // Play the sound asynchronously to avoid blocking
        DispatchQueue.global(qos: .userInitiated).async {
            sound.play()
            print("Screenshot sound played")
        }
    }
    
    /**
     * Plays a custom sound from a file path.
     *
     * This method can be used to play custom audio files if needed in the future.
     * It provides flexibility for users to customize their screenshot sounds.
     *
     * - Parameter fileName: The name of the audio file (without extension)
     * - Parameter fileExtension: The file extension (e.g., "wav", "mp3")
     *
     * - Returns: Bool indicating whether the sound was successfully loaded and played
     */
    @discardableResult
    func playCustomSound(fileName: String, fileExtension: String = "wav") -> Bool {
        guard let soundPath = Bundle.main.path(forResource: fileName, ofType: fileExtension),
              let sound = NSSound(contentsOfFile: soundPath, byReference: false) else {
            print("Could not load custom sound: \(fileName).\(fileExtension)")
            return false
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            sound.play()
            print("Custom sound played: \(fileName)")
        }
        
        return true
    }
}
