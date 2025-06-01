import SwiftUI // For NSHostingView, ScreenshotView, MainActor
import AppKit
import ScreenCaptureKit
import CoreVideo
import Carbon

/**
 * SwiftUI view that displays a captured screenshot image.
 *
 * This view presents the screenshot in a resizable container that maintains
 * the original aspect ratio while ensuring a minimum display size.
 */
struct ScreenshotView: View {
    /// The screenshot image to display
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(minWidth: 100, minHeight: 100) // Ensure a minimum size
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
    /// Array of currently open screenshot windows
    var screenshotWindows: [NSWindow] = []
    /// Controller for managing the settings window
    private let settingsController = SettingsWindowController()
    /// Current screen capture stream
    private var stream: SCStream?
    /// The most recently captured screenshot image
    private var capturedImage: NSImage?
    /// Dispatch queue for handling screen capture samples
    private let sampleQueue = DispatchQueue(label: "com.korenani.SampleQueue", qos: .userInitiated)
    /// Reference to the registered global hotkey
    private var hotKeyRef: EventHotKeyRef?


    /**
     * Called when the application finishes launching.
     *
     * This method sets up the initial application state by registering
     * the global hotkey for screenshot capture.
     *
     * - Parameter notification: The application launch notification
     */
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("KoreNani App finished launching.")
        registerHotkey()
    }

    /**
     * Registers the global hotkey (Cmd+6) for triggering screenshot capture.
     *
     * This method uses Carbon framework APIs to register a system-wide hotkey
     * that will trigger the screenshot functionality even when the app is
     * running in the background.
     *
     * The hotkey combination is Command + 6, which calls `takeScreenshot()`
     * when pressed.
     */
    func registerHotkey() {
        // Register Cmd+6 global hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x73637234), id: 1) // 'scr4'
        let keyCode = UInt32(kVK_ANSI_6) // Key code for '6'
        let modifiers = UInt32(cmdKey) // Command key modifier
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            // Cast userData back to AppDelegate
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            appDelegate.takeScreenshot()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
            print("Successfully registered Cmd+6 hotkey")
        } else {
            print("Failed to register hotkey, status: \(status)")
        }
    }
    /**
     * Initiates a screenshot capture operation.
     *
     * This method is called when the user triggers a screenshot through
     * the global hotkey or menu bar. It launches an asynchronous screen
     * capture operation and plays a sound if enabled in settings.
     *
     * The method is marked with `@objc` to make it compatible with
     * Objective-C runtime for hotkey event handling.
     */
    @objc func takeScreenshot() {
        print("Take Screenshot action triggered")
        
        // Play screenshot sound if enabled in settings
        if SettingsManager.shared.soundEnabled {
            SoundManager.shared.playScreenshotSound()
        }
        
        Task {
            await captureScreen()
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
     * 1. Obtains shareable content from the system (displays)
     * 2. Configures a screen capture stream
     * 3. Starts capturing and waits for a sample
     * 4. Stops the capture and displays the result
     *
     * The method automatically handles screen recording permissions by using
     * `SCShareableContent.current`, which triggers the system permission dialog
     * if needed.
     *
     * - Note: The capture waits up to 5 seconds for a sample before timing out.
     */
    func captureScreen() async {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                print("No display found")
                return
            }
            
            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height
            config.pixelFormat = kCVPixelFormatType_32BGRA
            config.showsCursor = false
            
            let filter = SCContentFilter(display: display, excludingWindows: [])
            
            // Reset captured image
            capturedImage = nil
            
            stream = SCStream(filter: filter, configuration: config, delegate: self)
            try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: sampleQueue)
            try await stream?.startCapture()
            
            print("Stream started, waiting for sample...")
            
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
                print("Screenshot captured successfully. Size: \(image.size)")
                Task { @MainActor in
                    self.showScreenshotWindow(image: image)
                }
            } else {
                print("Failed to capture screenshot - no sample received")
            }
            
        } catch {
            print("Error during screenshot: \(error)")
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
     * Creates and displays a new window containing the captured screenshot.
     *
     * This method:
     * 1. Calculates appropriate window dimensions based on the image aspect ratio
     * 2. Creates a new NSWindow with the screenshot content
     * 3. Sets up window lifecycle management with notification observers
     * 4. Tracks the window for proper cleanup
     *
     * The window is positioned centered horizontally and near the top of the screen.
     * Each screenshot gets a unique window title based on the capture timestamp.
     *
     * - Parameter image: The captured screenshot image to display
     */
    func showScreenshotWindow(image: NSImage) {
        guard let mainScreen = NSScreen.main else {
            print("Error: Could not get main screen.")
            return
        }
        let screenFrame = mainScreen.frame
        let windowHeight: CGFloat = 300
        
        let aspectRatio = image.size.width / image.size.height
        let windowWidth = windowHeight * aspectRatio

        let windowX = (screenFrame.width - windowWidth) / 2
        let windowY: CGFloat = 50

        let windowRect = NSRect(x: windowX, y: windowY, width: windowWidth, height: windowHeight)
        
        let screenshotSwiftUIView = ScreenshotView(image: image)
        
        let window = NSWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Screenshot \(Date().timeIntervalSince1970)"
        window.contentView = NSHostingView(rootView: screenshotSwiftUIView)
        window.isReleasedWhenClosed = false // Changed to false to prevent automatic deallocation
        
        // Create a window controller to manage the window lifecycle
        let windowController = NSWindowController(window: window)
        windowController.showWindow(nil)
        
        // Store both window and controller to keep them alive
        screenshotWindows.append(window)
        
        // Set up notification observer for window closing instead of delegate
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: window,
            queue: .main
        ) { [weak self] notification in
            if let closingWindow = notification.object as? NSWindow {
                self?.handleWindowClosing(closingWindow)
            }
        }

        NSApp.activate(ignoringOtherApps: true)
    }
    
    /**
     * Handles cleanup when a screenshot window is closed.
     *
     * This method:
     * 1. Removes the window from the tracking array
     * 2. Removes the notification observer to prevent memory leaks
     * 3. Logs the current number of remaining windows
     *
     * - Parameter window: The window that is being closed
     */
    private func handleWindowClosing(_ window: NSWindow) {
        // Remove from our tracking array
        if let index = screenshotWindows.firstIndex(where: { $0 === window }) {
            screenshotWindows.remove(at: index)
            print("Screenshot window closed. Remaining: \(screenshotWindows.count)")
        }
        
        // Remove the notification observer
        NotificationCenter.default.removeObserver(self, name: NSWindow.willCloseNotification, object: window)
    }
}
