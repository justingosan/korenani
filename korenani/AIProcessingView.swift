import SwiftUI
import AppKit
import Foundation
import OpenAI

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
                    .frame(height: 150)
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 8)
        )
        .alert("KoreNani", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            startAIAnalysis()
        }
    }

    private func startAIAnalysis() {
        let prompt = "Describe in detail the contents of this image. Summarize any text, translate it to English if not in English, and explain any relevant context or meaning. If known, identify the language and subject. Respond comprehensively, as if explaining to a beginner."
        let apiKey = SettingsManager.shared.openAIAPIKey
        if apiKey.isEmpty {
            alertMessage = "OpenAI API key not set in Settings."
            showingAlert = true
            isProcessing = false
            return
        }

        isProcessing = true
        aiResponse = ""

        let openAI = OpenAI(apiToken: apiKey)

        
        let query = ChatQuery(messages: [.init(role: .user, content: prompt)!], model: .gpt4, maxTokens: 256, temperature: 0.6)

        openAI.chats(query: query) { result in
            DispatchQueue.main.async {
                print("AI analysis in progress...")
                isProcessing = false
                switch result {
                case .success(let chatResult):
                        print("chatResult:", chatResult)
                    let content = chatResult.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    if content.isEmpty {
                        alertMessage = "AI request succeeded but response was empty."
                        showingAlert = true
                    } else {
                        aiResponse = content
                    }
                case .failure(let error):
                    alertMessage = "AI request failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }

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

    private func copyScreenshot() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
        alertMessage = "Screenshot copied to clipboard"
        showingAlert = true
    }

    private func copyAIResponse() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(aiResponse, forType: .string)
        alertMessage = "AI response copied to clipboard"
        showingAlert = true
    }

    private func closeWindow() {
        window?.close()
    }
}

// Preview provider
#Preview("AIProcessingView Preview") {
    AIProcessingView(
        image: NSImage(systemSymbolName: "photo", accessibilityDescription: "Preview") ?? NSImage(),
        window: nil
    )
    .frame(width: 600, height: 250)
}
