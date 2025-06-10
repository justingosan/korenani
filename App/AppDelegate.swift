import SwiftUI // For NSHostingView, ScreenshotView, MainActor
import AppKit
import ScreenCaptureKit
import CoreVideo
import Carbon
import Foundation
import CoreGraphics

// Internal modules
// Note: These imports are for VS Code linting - in Xcode they are not required
// since all files are part of the same module, but we include them for clarity
// and to avoid VS Code errors
@_exported import struct Foundation.URL
@_exported import class AppKit.NSImage

/**
 * SwiftUI view that displays a captured screenshot image with AI processing capabilities.
 *
 * This view presents the screenshot thumbnail on the left and AI processing interface on the right.
 * It's designed to appear at the bottom of the screen and provides buttons for common actions
 * like saving and copying the image, as well as AI analysis functionality.
 */
struct ScreenshotView: View {
    /// The screenshot image to display
    let image: NSImage
    /// Current AI processing state
    @State private var isProcessing = false
    /// AI response text
    @State private var aiResponse = ""
    /// Alert state for showing confirmation messages
    @State private var showingAlert = false
    /// Alert message content
    @State private var alertMessage = ""
    /// User prompt for AI processing
    @State private var userPrompt = "What do you see in this screenshot?"

    var body: some View {
        HStack(spacing: 15) {
            // Left side - Screenshot thumbnail
            VStack {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 200, height: 150)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)

                // Action buttons for screenshot
                HStack(spacing: 10) {
                    Button(action: saveScreenshot) {
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("Save Screenshot")

                    Button(action: copyScreenshot) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.borderless)
                    .help("Copy Screenshot")
                }
            }

            // Right side - AI streaming response area
            VStack(alignment: .leading, spacing: 10) {
                // Header with title and close button
                HStack {
                    Text("AI Analysis")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: closeWindow) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.borderless)
                    .help("Close")
                }

                // AI response streaming area
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if isProcessing {
                            HStack(spacing: 8) {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Analyzing screenshot...")
                                    .foregroundColor(.secondary)
                                    .font(.subheadline)
                            }
                        } else if aiResponse.isEmpty {
                            Text("AI analysis will appear here...")
                                .foregroundColor(.secondary)
                                .italic()
                                .font(.subheadline)
                        } else {
                            Text(aiResponse)
                                .textSelection(.enabled)
                                .font(.system(.body, design: .default))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                }
                .frame(height: 120)
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
            }
            .frame(minWidth: 320)
        }
        .padding(20)
        .background(
            // Floating window background with subtle shadow
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        )
        .onAppear {
            // Start AI processing immediately when view appears
            startAIAnalysis()
        }
        .alert("KoreNani", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    /**
     * Starts AI analysis of the screenshot with simulated streaming.
     * This will be replaced with actual OpenAI API integration.
     */
    private func startAIAnalysis() {
        isProcessing = true
        aiResponse = ""

        // Simulate streaming response
        let fullResponse = "I can see this is a screenshot of what appears to be a code editor or development environment. The interface shows various panels and likely contains programming code or text. This type of screenshot is commonly captured when developers want to share their work, document a bug, or get help with their code. The layout suggests it could be an IDE like VS Code, Xcode, or similar development tools."

        let words = fullResponse.components(separatedBy: " ")
        var currentText = ""

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false

            // Simulate streaming by adding words progressively
            for (index, word) in words.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                    currentText += (index == 0 ? "" : " ") + word
                    aiResponse = currentText
                }
            }
        }
    }

    /**
     * Processes the screenshot with AI using OpenAI API.
     * For now, this is a placeholder that simulates processing.
     */
    private func processWithAI() {
        startAIAnalysis()
    }

    /**
     * Saves the screenshot to the user's preferred location.
     */
    private func saveScreenshot() {
        let tempDir = NSTemporaryDirectory()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "KoreNani_Screenshot_\(timestamp).png"
        let filePath = URL(fileURLWithPath: tempDir).appendingPathComponent(filename)

        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: filePath)
                alertMessage = "Screenshot saved to \(filePath.path)"
                showingAlert = true
            } catch {
                alertMessage = "Failed to save screenshot: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            alertMessage = "Failed to process image data"
            showingAlert = true
        }
    }

    /**
     * Copies the screenshot to the clipboard.
     */
    private func copyScreenshot() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])

        alertMessage = "Screenshot copied to clipboard"
        showingAlert = true
    }

    /**
     * Closes the screenshot window.
     */
    private func closeWindow() {
        if let window = NSApp.keyWindow {
            window.close()
        }
    }
}

/**
 * Main application delegate that handles the KoreNani macOS application lifecycle.
 *
 * This class is responsible for:
 * - Managing global hotkey registration for screenshot capture
 * - Handling screen capture operations using ScreenCaptureKit
 * - Managing screenshot display windows
 * - Coordinating with the settings window controller
 *
 * The app registers Cmd+6 as a global hotkey to trigger screenshot capture.
 */
class AppDelegate: NSObject, NSApplicationDelegate, SCStreamDelegate, SCStreamOutput {
    /// The single floating screenshot window (if open)
    var floatingWindow: NSWindow?
    /// Controller for managing the settings window
    private let settingsController = SettingsWindowController()
    /// Current screen capture stream
    private var stream: SCStream?
    /// The most recently captured screenshot image
    private var capturedImage: NSImage?
    /// Dispatch queue for handling screen capture samples
    private let sampleQueue = DispatchQueue(label: "com.korenani.SampleQueue", qos: .userInitiated)
    /// Reference to the registered global hotkey for window capture
    private var hotKeyRef: EventHotKeyRef?
    /// Reference to the registered global hotkey for screen selection
    private var selectionHotKeyRef: EventHotKeyRef?
    /// Store the previously active application to restore focus after closing
    private var previousApp: NSRunningApplication?

    /**
     * Called when the application finishes launching.
     *
     * This method sets up the initial application state by registering
     * the global hotkey for screenshot capture and listening for hotkey changes.
     *
     * - Parameter notification: The application launch notification
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("KoreNani App finished launching.")

        // Apply saved dock icon visibility setting
        if SettingsManager.shared.hideDockIcon {
            NSApplication.shared.setActivationPolicy(.accessory)
        }

        registerHotkey()
        registerSelectionHotkey()

        // Listen for hotkey changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hotkeyChanged),
            name: .hotkeyChanged,
            object: nil
        )
    }

    /**
     * Called when the hotkey configuration changes.
     * Re-registers the hotkey with the new settings.
     */
    @objc private func hotkeyChanged() {
        unregisterHotkey()
        unregisterSelectionHotkey()
        registerHotkey()
        registerSelectionHotkey()
    }

    /**
     * Unregisters the current global hotkey.
     */
    private func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
            print("Unregistered previous hotkey")
        }
    }

    /**
     * Unregisters the screen selection global hotkey.
     */
    private func unregisterSelectionHotkey() {
        if let selectionHotKeyRef = selectionHotKeyRef {
            UnregisterEventHotKey(selectionHotKeyRef)
            self.selectionHotKeyRef = nil
            print("Unregistered previous selection hotkey")
        }
    }

    /**
     * Registers the global hotkey for triggering screenshot capture.
     *
     * This method uses Carbon framework APIs to register a system-wide hotkey
     * that will trigger the screenshot functionality even when the app is
     * running in the background.
     *
     * The hotkey combination is loaded from SettingsManager and calls `takeScreenshot()`
     * when pressed.
     */
    func registerHotkey() {
        let settings = SettingsManager.shared

        // Register global hotkey with user-configured settings
        let hotKeyID = EventHotKeyID(signature: OSType(0x73637234), id: 1) // 'scr4'
        let keyCode = UInt32(settings.hotkeyKeyCode)
        let modifiers = settings.hotkeyModifiers

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            // Cast userData back to AppDelegate
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            appDelegate.takeScreenshot()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if status == noErr {
            print("Successfully registered hotkey: \(settings.getHotkeyDisplayString())")
        } else {
            print("Failed to register hotkey, status: \(status)")
        }
    }

    /**
     * Registers the global hotkey for triggering screen selection capture (Cmd+7).
     *
     * This method uses Carbon framework APIs to register Cmd+7 as a system-wide hotkey
     * that will trigger the screen selection functionality.
     */
    func registerSelectionHotkey() {
        // Register Cmd+7 for screen selection
        let hotKeyID = EventHotKeyID(signature: OSType(0x73637235), id: 2) // 'scr5'
        let keyCode = UInt32(26) // Key code for '7'
        let modifiers = UInt32(cmdKey)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))

        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            // Cast userData back to AppDelegate
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            appDelegate.takeSelectionScreenshot()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)

        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &selectionHotKeyRef)

        if status == noErr {
            print("Successfully registered selection hotkey: Cmd+7")
        } else {
            print("Failed to register selection hotkey, status: \(status)")
        }
    }
    /**
     * Initiates a screenshot capture operation or closes the window if app is focused.
     *
     * This method is called when the user triggers a screenshot through
     * the global hotkey or menu bar. It checks if the app's window is currently
     * focused and either:
     * - Closes the window if the app is in focus
     * - Takes a screenshot if the app is in the background
     *
     * The method is marked with `@objc` to make it compatible with
     * Objective-C runtime for hotkey event handling.
     */
    @objc func takeScreenshot() {
        print("Take Screenshot action triggered")

        // Check if our floating window is currently open
        if let window = floatingWindow, window.isVisible {
            // Window is open - close it and restore focus to previous app
            print("KoreNani window is open - closing it")
            window.close()
            
            // Restore focus to the previously active application
            if let prevApp = previousApp {
                print("Restoring focus to: \(prevApp.localizedName ?? "Unknown App")")
                prevApp.activate()
            }
            return
        }

        // Store the current frontmost app before we show our window
        previousApp = NSWorkspace.shared.frontmostApplication

        // No window open - proceed with screenshot capture
        print("Taking screenshot")
        
        // Play screenshot sound if enabled in settings
        if SettingsManager.shared.soundEnabled {
            SoundManager.shared.playScreenshotSound()
        }

        Task {
            await captureScreen()
        }
    }

    /**
     * Initiates a screen selection capture operation.
     *
     * This method allows users to select a specific area of the screen to capture
     * by creating a selection overlay window.
     */
    @objc func takeSelectionScreenshot() {
        print("Take Selection Screenshot action triggered")

        // Check if our floating window is currently open
        if let window = floatingWindow, window.isVisible {
            // Window is open - close it and restore focus to previous app
            print("KoreNani window is open - closing it")
            window.close()
            
            // Restore focus to the previously active application
            if let prevApp = previousApp {
                print("Restoring focus to: \(prevApp.localizedName ?? "Unknown App")")
                prevApp.activate()
            }
            return
        }

        // Store the current frontmost app before we show our selection
        previousApp = NSWorkspace.shared.frontmostApplication

        // Play screenshot sound if enabled in settings
        if SettingsManager.shared.soundEnabled {
            SoundManager.shared.playScreenshotSound()
        }

        Task {
            await captureScreenSelection()
        }
    }

    /**
     * Shows the settings window.
     *
     * This method delegates to the settings window controller to display
     * the application preferences interface.
     */
    @objc func showSettings() {
        settingsController.showSettings()
    }

    /**
     * Performs the actual screen capture operation using ScreenCaptureKit.
     *
     * This async method:
     * 1. Obtains shareable content from the system (windows and displays)
     * 2. Finds the current active window
     * 3. Configures a screen capture stream for that window
     * 4. Starts capturing and waits for a sample
     * 5. Stops the capture and displays the result
     *
     * The method automatically handles screen recording permissions by using
     * `SCShareableContent.current`, which triggers the system permission dialog
     * if needed.
     *
     * - Note: The capture waits up to 5 seconds for a sample before timing out.
     */
    func captureScreen() async {
        if let image = captureFrontmostWindow() {
            print("Screenshot captured successfully. Size: \(image.size)")
            _ = autoSaveScreenshot(image)
            await MainActor.run {
                self.showScreenshotWindow(image: image)
            }
        } else {
            print("Failed to capture screenshot")
        }
    }

    /**
     * Performs screen selection capture using ScreenCaptureKit.
     *
     * This async method:
     * 1. Creates a full-screen overlay for selection
     * 2. Allows user to drag and select a region
     * 3. Captures only the selected area
     * 4. Shows the result in the screenshot window
     */
    func captureScreenSelection() async {
        do {
            let content = try await SCShareableContent.current
            
            guard let mainDisplay = content.displays.first else {
                print("No display found")
                return
            }

            print("Starting screen selection capture")

            // Create and show selection overlay
            await MainActor.run {
                showSelectionOverlay(display: mainDisplay)
            }

        } catch {
            print("Error during screen selection: \(error)")
        }
    }

    /**
     * SCStreamOutput delegate method called when a new screen sample is available.
     *
     * This method processes the captured screen data and converts it to an NSImage
     * that can be displayed in the screenshot window.
     *
     * - Parameters:
     *   - stream: The SCStream that captured the sample
     *   - sampleBuffer: The captured screen data as a CMSampleBuffer
     *   - type: The type of stream output (should be .screen)
     */
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        guard type == .screen else { return }

        guard let cvPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Could not get pixel buffer")
            return
        }

        let ciImage = CIImage(cvPixelBuffer: cvPixelBuffer)
        let rep = NSCIImageRep(ciImage: ciImage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)

        capturedImage = nsImage
        print("Sample received and image created")
    }

    /**
     * SCStreamDelegate method called when the stream stops with an error.
     *
     * This method handles any errors that occur during screen capture streaming.
     *
     * - Parameters:
     *   - stream: The SCStream that stopped
     *   - error: The error that caused the stream to stop
     */
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
    }

    /**
     * Creates and displays a new borderless floating window with the captured screenshot and AI processing.
     *
     * This method:
     * 1. Creates a borderless window positioned at the bottom of screen
     * 2. Uses AIProcessingView with floating appearance
     * 3. Sets up window lifecycle management with notification observers
     * 4. Tracks the window for proper cleanup
     * 5. Provides AI processing interface alongside screenshot actions
     *
     * The window appears as a floating panel at the bottom of the screen.
     *
     * - Parameter image: The captured screenshot image to display
     */
    func showScreenshotWindow(image: NSImage) {
        guard let mainScreen = NSScreen.main else {
            print("Error: Could not get main screen.")
            return
        }
        let screenFrame = mainScreen.frame
        let windowWidth: CGFloat = 600
        let windowHeight: CGFloat = 250
        let windowX = (screenFrame.width - windowWidth) / 2
        let windowY: CGFloat = 100
        let windowRect = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        let newId = UUID()

        if let window = floatingWindow, let hostingView = window.contentView as? NSHostingView<AIProcessingView> {
            hostingView.rootView = AIProcessingView(image: image, window: window, id: newId)
            window.orderFront(nil)
            return
        }

        // Create draggable window for floating appearance with position persistence
        let window = DraggableWindow(
            contentRect: windowRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let updatedView = AIProcessingView(image: image, window: window, id: newId)
        window.contentView = NSHostingView(rootView: updatedView)
        window.isReleasedWhenClosed = false
        window.setDefaultPosition()
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        floatingWindow = window
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            self?.floatingWindow = nil
        }
    }

    /**
     * Finds the currently active window from the available shareable windows.
     *
     * This method searches through the provided windows to find the one that
     * is currently in focus (active). It excludes windows that are not on screen
     * or are not capturable.
     *
     * - Parameter windows: Array of shareable windows from ScreenCaptureKit
     * - Returns: The currently active window, or nil if none found
     */
    private func getCurrentActiveWindow(from windows: [SCWindow]) -> SCWindow? {
        // Get the frontmost application
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return nil
        }

        // Find windows belonging to the frontmost application
        let frontmostWindows = windows.filter { window in
            guard let windowApp = window.owningApplication else { return false }
            return windowApp.processID == frontmostApp.processIdentifier &&
                   window.isOnScreen &&
                   window.frame.width > 0 &&
                   window.frame.height > 0
        }

        // Sort by window layer (higher layer = more on top) and take the first one
        let activeWindow = frontmostWindows.max { $0.windowLayer < $1.windowLayer }

        if let window = activeWindow {
            print("Found active window: \(window.title ?? "Untitled") (PID: \(window.owningApplication?.processID ?? 0))")
        } else {
            print("No capturable window found for frontmost app: \(frontmostApp.localizedName ?? "Unknown")")
        }

        return activeWindow
    }

    /**
     * Called when the application will terminate.
     * Cleans up hotkey registration and observers.
     */
    /// Reference to the selection overlay window to prevent deallocation
    private var selectionOverlayWindow: NSWindow?

    /**
     * Shows a full-screen selection overlay for the user to select a region.
     */
    func showSelectionOverlay(display: SCDisplay) {
        guard let mainScreen = NSScreen.main else {
            print("Error: Could not get main screen.")
            return
        }
        
        let screenFrame = mainScreen.frame
        
        let overlayWindow = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        overlayWindow.level = .screenSaver
        overlayWindow.backgroundColor = NSColor.clear
        overlayWindow.isOpaque = false
        overlayWindow.ignoresMouseEvents = false
        overlayWindow.acceptsMouseMovedEvents = true
        overlayWindow.isReleasedWhenClosed = false
        
        // Store reference to prevent deallocation
        selectionOverlayWindow = overlayWindow
        
        let selectionView = ScreenSelectionView(display: display) { [weak self] selectedRect in
            self?.selectionOverlayWindow?.close()
            self?.selectionOverlayWindow = nil
            if selectedRect != .zero {
                Task {
                    await self?.captureSelectedRegion(display: display, rect: selectedRect)
                }
            } else {
                print("Screen selection cancelled by user")
            }
        }
        
        overlayWindow.contentView = NSHostingView(rootView: selectionView)
        overlayWindow.makeKeyAndOrderFront(nil)
        
        // Set up window close observer
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: overlayWindow,
            queue: .main
        ) { [weak self] _ in
            self?.selectionOverlayWindow = nil
        }
    }

    /**
     * Captures the selected region of the screen.
     */
    func captureSelectedRegion(display: SCDisplay, rect: CGRect) async {
        do {
            // Capture the full display first
            let config = SCStreamConfiguration()
            config.width = Int(display.width)
            config.height = Int(display.height)
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false

            let filter = SCContentFilter(display: display, excludingWindows: [])

            // Reset captured image
            capturedImage = nil

            stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
            try await stream?.startCapture()

            print("Stream started for full display capture, waiting for sample...")

            // Wait for a sample with timeout
            for _ in 0..<50 { // 5 second timeout
                if capturedImage != nil {
                    break
                }
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }

            try await stream?.stopCapture()
            stream = nil

            if let image = capturedImage {
                // Crop the image to the selected region
                let croppedImage = cropImage(image, to: rect, display: display)
                print("Selected region captured successfully. Original: \(image.size), Cropped: \(croppedImage.size)")

                // Auto-save the screenshot
                _ = autoSaveScreenshot(croppedImage)

                // Show the screenshot window
                Task { @MainActor in
                    self.showScreenshotWindow(image: croppedImage)
                }
            } else {
                print("Failed to capture selected region - no sample received")
            }

        } catch {
            print("Error during selected region capture: \(error)")
        }
    }

    /**
     * Crops an image to the specified rectangle.
     */
    func cropImage(_ image: NSImage, to rect: CGRect, display: SCDisplay) -> NSImage {
        // Validate inputs
        guard rect.width > 0 && rect.height > 0 && 
              image.size.width > 0 && image.size.height > 0 &&
              display.width > 0 && display.height > 0 else {
            print("Invalid crop parameters")
            return image
        }
        
        // The rect is in screen coordinates, we need to convert to image coordinates
        let scaleX = image.size.width / CGFloat(display.width)
        let scaleY = image.size.height / CGFloat(display.height)
        
        // Convert to image coordinates (note: NSImage coordinates start from bottom-left)
        let imageRect = CGRect(
            x: max(0, rect.origin.x * scaleX),
            y: max(0, (CGFloat(display.height) - rect.origin.y - rect.height) * scaleY),
            width: min(rect.width * scaleX, image.size.width),
            height: min(rect.height * scaleY, image.size.height)
        )
        
        // Create a new image with the cropped size
        let croppedImage = NSImage(size: CGSize(width: rect.width, height: rect.height))
        
        croppedImage.lockFocus()
        defer { croppedImage.unlockFocus() }
        
        // Draw the source image portion to the new image
        let sourceRect = NSRect(
            x: imageRect.origin.x,
            y: imageRect.origin.y,
            width: imageRect.width,
            height: imageRect.height
        )
        let destRect = NSRect(x: 0, y: 0, width: rect.width, height: rect.height)
        
        image.draw(in: destRect, from: sourceRect, operation: .copy, fraction: 1.0)
        
        return croppedImage
    }

    /**
     * Captures the frontmost window using CoreGraphics.
     *
     * - Returns: The captured window image or nil on failure.
     */
    private func captureFrontmostWindow() -> NSImage? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("No frontmost application found")
            return nil
        }

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            print("Failed to get window list")
            return nil
        }

        var chosenID: CGWindowID?
        var chosenBounds = CGRect.zero
        var highestLayer = Int.min

        for info in infoList {
            guard let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  pid == frontmostApp.processIdentifier,
                  let layer = info[kCGWindowLayer as String] as? Int,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let windowID = info[kCGWindowNumber as String] as? CGWindowID
            else { continue }

            if layer >= highestLayer,
               let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary),
               bounds.width > 0, bounds.height > 0 {
                highestLayer = layer
                chosenID = windowID
                chosenBounds = bounds
            }
        }

        guard let finalID = chosenID else {
            print("No active window for PID: \(frontmostApp.processIdentifier)")
            return nil
        }

        guard let cgImage = CGWindowListCreateImage(chosenBounds, [.optionIncludingWindow], finalID, [.boundsIgnoreFraming, .bestResolution]) else {
            print("Failed to capture window image")
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        let image = NSImage(cgImage: cgImage, size: size)
        return image
    }

    func applicationWillTerminate(_ notification: Notification) {
        unregisterHotkey()
        unregisterSelectionHotkey()
        selectionOverlayWindow?.close()
        selectionOverlayWindow = nil
        NotificationCenter.default.removeObserver(self)
    }

    /**
     * Cleanup method called when the delegate is deallocated.
     */
    deinit {
        unregisterHotkey()
        unregisterSelectionHotkey()
        selectionOverlayWindow?.close()
        selectionOverlayWindow = nil
        NotificationCenter.default.removeObserver(self)
    }

    /**
     * Automatically saves the screenshot to the user's preferred location.
     *
     * - Parameter image: The screenshot image to save
     * - Returns: The URL where the image was saved
     */
    private func autoSaveScreenshot(_ image: NSImage) -> URL? {
        let tempDir = NSTemporaryDirectory()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "KoreNani_\(timestamp).png"
        let filePath = URL(fileURLWithPath: tempDir).appendingPathComponent(filename)

        if let tiffData = image.tiffRepresentation,
           let bitmapImage = NSBitmapImageRep(data: tiffData),
           let pngData = bitmapImage.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: filePath)
                print("Screenshot saved to \(filePath.path)")
                return filePath
            } catch {
                print("Failed to save screenshot: \(error.localizedDescription)")
                return nil
            }
        } else {
            print("Failed to process image data")
            return nil
        }
    }

    // Add this helper function near the top-level of AppDelegate
    func resizedImage(_ image: NSImage, maxDimension: CGFloat) -> NSImage {
        let aspectRatio = image.size.width / image.size.height
        var newSize: NSSize
        if aspectRatio > 1 {
            newSize = NSSize(width: maxDimension, height: maxDimension / aspectRatio)
        } else {
            newSize = NSSize(width: maxDimension * aspectRatio, height: maxDimension)
        }
        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize), from: .zero, operation: .copy, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }
}
