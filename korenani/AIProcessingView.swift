import SwiftUI
import AppKit
import Foundation

/**
 * SwiftUI view that displays a captured screenshot with AI processing capability.
 *
 * This view is designed to appear as a floating window at the bottom of the screen and provides:
 * - Screenshot thumbnail on the left
 * - AI response streaming area on the right
 * - Custom close button
 * - Borderless floating appearance
 */
struct AIProcessingView: View {
    /// The screenshot image to display
    let image: NSImage
    /// Reference to the window for close functionality
    weak var window: NSWindow?
    /// Current AI processing state
    @State private var isProcessing = false
    /// AI response text that streams in
    @State private var aiResponse = ""
    /// Alert state for showing messages
    @State private var showingAlert = false
    /// Alert message content
    @State private var alertMessage = ""
    
    /// Initialize the view with an image and optional window reference
    init(image: NSImage, window: NSWindow?) {
        self.image = image
        self.window = window
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Close button at the very top-right of the window
            HStack {
                Spacer()
                
                Button(action: closeWindow) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Close")
            }
            .padding(.bottom, 12)
            
            // Main content area with aligned image and AI response
            HStack(alignment: .top, spacing: 15) {
                // Left side - Screenshot thumbnail
                VStack {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 150)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
                
                // Right side - AI streaming response area
                VStack(alignment: .leading, spacing: 0) {
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
                    .frame(height: 150) // Match the image height for better alignment
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Action buttons for AI response (only copy functionality)
                    HStack {
                        Spacer()
                        Button(action: copyAIResponse) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 14))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy AI Response")
                        .disabled(aiResponse.isEmpty)
                    }
                    .padding(.top, 5)
                }
                .frame(minWidth: 320)
            }
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
     * Saves the screenshot to the user's preferred location.
     */
    private func saveScreenshot() {
        let saveLocation = "Desktop" // Default to Desktop for now
        
        // Determine the directory path
        let directoryPath: String
        
        switch saveLocation {
        case "Desktop":
            directoryPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
        case "Pictures":
            directoryPath = NSSearchPathForDirectoriesInDomains(.picturesDirectory, .userDomainMask, true)[0]
        case "Downloads":
            directoryPath = NSSearchPathForDirectoriesInDomains(.downloadsDirectory, .userDomainMask, true)[0]
        default:
            directoryPath = NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
        }
        
        // Create a unique filename with timestamp
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = dateFormatter.string(from: Date())
        let filename = "KoreNani_Screenshot_\(timestamp).png"
        let filePath = URL(fileURLWithPath: directoryPath).appendingPathComponent(filename)
        
        // Save the image as PNG
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
     * Copies the AI response text to the clipboard.
     */
    private func copyAIResponse() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(aiResponse, forType: .string)
        
        alertMessage = "AI response copied to clipboard"
        showingAlert = true
    }
    
    /**
     * Closes the AI processing window.
     */
    private func closeWindow() {
        window?.close()
    }
}

#Preview {
    if let image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Preview") {
        AIProcessingView(image: image, window: nil)
            .frame(width: 600, height: 250)
    }
}
