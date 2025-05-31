import SwiftUI // For NSHostingView, ScreenshotView, MainActor
import AppKit
import ScreenCaptureKit
import CoreVideo
import Carbon

// SwiftUI View to display the screenshot
struct ScreenshotView: View {
    let image: NSImage

    var body: some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(minWidth: 100, minHeight: 100) // Ensure a minimum size
    }
}
// AppDelegate to handle application lifecycle and custom logic
class AppDelegate: NSObject, NSApplicationDelegate, SCStreamDelegate, SCStreamOutput {
    var screenshotWindows: [NSWindow] = []
    private var stream: SCStream?
    private var capturedImage: NSImage?
    private let sampleQueue = DispatchQueue(label: "com.screen4ai.SampleQueue", qos: .userInitiated)
    private var hotKeyRef: EventHotKeyRef?


    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Screen4AI App finished launching.")
        registerHotkey()
    }

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
    // Removed requestScreenCaptureAccess() as SCShareableContent.current will trigger prompt

    @objc func takeScreenshot() {
        print("Take Screenshot action triggered")
        Task {
            await captureScreen()
        }
    }

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
                await MainActor.run {
                    showScreenshotWindow(image: image)
                }
            } else {
                print("Failed to capture screenshot - no sample received")
            }
            
        } catch {
            print("Error during screenshot: \(error)")
        }
    }
    
    // SCStreamOutput delegate method
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
    
    // SCStreamDelegate methods
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        print("Stream stopped with error: \(error)")
    }

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

// Removed NSWindowDelegate extension - now using NotificationCenter instead