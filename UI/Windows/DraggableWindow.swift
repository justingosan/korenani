import AppKit
import Foundation

/**
 * Custom NSWindow subclass that supports dragging and position persistence.
 * This window is designed for the AI processing interface and provides:
 * - Full window dragging capability
 * - Position saving and restoration
 * - Proper close button handling
 */
class DraggableWindow: NSWindow {
    
    /// Key for storing window position in UserDefaults
    private static let positionKey = "AIProcessingWindowPosition"
    
    /// Track mouse down location for dragging (in screen coordinates)
    private var mouseDownLocationInScreen: NSPoint = .zero
    private var windowOriginAtMouseDown: NSPoint = .zero
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        setupWindow()
    }
    
    private func setupWindow() {
        // Configure window for floating appearance
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.hasShadow = false // SwiftUI view will handle shadow
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.isReleasedWhenClosed = false
        
        // Load saved position if available
        loadSavedPosition()
    }
    
    // Override to prevent window from becoming key/main
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    override func mouseDown(with event: NSEvent) {
        // Store the mouse location in screen coordinates and window origin for dragging
        mouseDownLocationInScreen = NSEvent.mouseLocation
        windowOriginAtMouseDown = self.frame.origin
        super.mouseDown(with: event)
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Calculate the new window position based on mouse movement in screen coordinates
        let currentLocationInScreen = NSEvent.mouseLocation
        let deltaX = currentLocationInScreen.x - mouseDownLocationInScreen.x
        let deltaY = currentLocationInScreen.y - mouseDownLocationInScreen.y
        
        let newOrigin = NSPoint(
            x: windowOriginAtMouseDown.x + deltaX,
            y: windowOriginAtMouseDown.y + deltaY
        )
        
        self.setFrameOrigin(newOrigin)
        super.mouseDragged(with: event)
    }
    
    override func mouseUp(with event: NSEvent) {
        // Save the new position when dragging ends
        savePosition()
        super.mouseUp(with: event)
    }
    
    /**
     * Saves the current window position to UserDefaults.
     */
    private func savePosition() {
        let origin = self.frame.origin
        let positionData = [
            "x": origin.x,
            "y": origin.y
        ]
        UserDefaults.standard.set(positionData, forKey: Self.positionKey)
    }
    
    /**
     * Loads and applies the saved window position from UserDefaults.
     */
    private func loadSavedPosition() {
        guard let positionData = UserDefaults.standard.dictionary(forKey: Self.positionKey),
              let x = positionData["x"] as? CGFloat,
              let y = positionData["y"] as? CGFloat else {
            return
        }
        
        // Ensure the position is still valid (screen might have changed)
        let savedOrigin = NSPoint(x: x, y: y)
        if isPositionValid(savedOrigin) {
            self.setFrameOrigin(savedOrigin)
        }
    }
    
    /**
     * Checks if a window position is valid (within screen bounds).
     */
    private func isPositionValid(_ origin: NSPoint) -> Bool {
        guard let screen = NSScreen.main else { return false }
        
        let screenFrame = screen.visibleFrame
        let windowFrame = NSRect(origin: origin, size: self.frame.size)
        
        // Check if at least part of the window is visible on screen
        return screenFrame.intersects(windowFrame)
    }
    
    /**
     * Positions the window at the default location (bottom center of screen).
     */
    func setDefaultPosition() {
        guard let mainScreen = NSScreen.main else { return }
        
        let screenFrame = mainScreen.frame
        let windowSize = self.frame.size
        
        // Position at bottom center of screen
        let windowX = (screenFrame.width - windowSize.width) / 2
        let windowY: CGFloat = 100 // Distance from bottom of screen
        
        self.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        savePosition()
    }
    
    override func close() {
        // Save position before closing
        savePosition()
        super.close()
    }
}
