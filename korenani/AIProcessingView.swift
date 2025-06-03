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
    /// Add this property
    let id: UUID

    /// Initialize the view with an image, optional window reference, and id
    init(image: NSImage, window: NSWindow?, id: UUID) {
        self.image = image
        self.window = window
        self.id = id
    }

    var body: some View {
        VStack(spacing: 0) {
            // Close button at the very top-right of the window
            HStack {
                Spacer(minLength: 0)
                Button(action: closeWindow) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Close")
            }
            .padding(.bottom, 4)

            // Main content area with aligned image and AI response
            HStack(alignment: .top, spacing: 10) {
                // Left side - Screenshot thumbnail
                VStack(spacing: 0) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 250)
                        .background(Color.black.opacity(0.02))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.gray.opacity(0.09), lineWidth: 0.7)
                        )
                }

                // Right side - AI streaming response area
                VStack(alignment: .leading, spacing: 0) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 5) {
                            if isProcessing {
                                HStack(spacing: 8) {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Analyzing screenshot...")
                                        .foregroundColor(.secondary)
                                        .font(.title3)
                                }
                            } else if aiResponse.isEmpty {
                                Text("AI analysis will appear here...")
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .font(.title3)
                            } else {
                                Text(aiResponse)
                                    .textSelection(.enabled)
                                    .font(.title3)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 2)
                    }
                    .frame(height: 200)
                    .padding(.vertical, 7)
                    .padding(.horizontal, 8)
                    .background(Color(.windowBackgroundColor).opacity(0.93))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.gray.opacity(0.12), lineWidth: 0.7)
                    )

                    HStack(spacing: 0) {
                        Spacer()
                        Button(action: copyAIResponse) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 18))
                                .foregroundColor(.primary)
                        }
                        .buttonStyle(.borderless)
                        .help("Copy AI Response")
                        .disabled(aiResponse.isEmpty)
                    }
                    .padding(.top, 2)
                }
                .frame(minWidth: 260)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
        )
        .alert("KoreNani", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            startAIAnalysis()
        }
        .onChange(of: id) {
            aiResponse = ""
            isProcessing = true
            startAIAnalysis()
        }
    }

    private func startAIAnalysis() {
        let prompt = "You are an excellent virtual assistant that understands what your boss wants when presenteted with an image. You answer very concisely. If it's a Japanese text, you translate it. If it's a quiz, you answer it one by one. You always give the correct answer per question if it is multiple choice. If it's instructions, you summarize it. If it's anything else, you describe it."
        let apiKey = SettingsManager.shared.openAIAPIKey
        if apiKey.isEmpty {
            alertMessage = "OpenAI API key not set in Settings."
            showingAlert = true
            isProcessing = false
            return
        }

        isProcessing = true
        aiResponse = ""

        // Convert NSImage to PNG base64
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            alertMessage = "Failed to process image data for AI analysis."
            showingAlert = true
            isProcessing = false
            return
        }
        let base64String = pngData.base64EncodedString()

        // Prepare the request
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Prepare the JSON body
        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(base64String)"]]
                    ]
                ]
            ],
            "max_tokens": 512,
            "stream": true
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let handler = OpenAIStreamHandler(
            onContent: { chunk in
                self.aiResponse += chunk
            },
            onFinish: {
                self.isProcessing = false
            }
        )
        let session = URLSession(configuration: .default, delegate: handler, delegateQueue: nil)
        let task = session.dataTask(with: request)
        task.resume()
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

// Streaming handler for OpenAI SSE
class OpenAIStreamHandler: NSObject, URLSessionDataDelegate {
    private var buffer = Data()
    private let onContent: (String) -> Void
    private let onFinish: () -> Void

    init(onContent: @escaping (String) -> Void, onFinish: @escaping () -> Void) {
        self.onContent = onContent
        self.onFinish = onFinish
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        while let range = buffer.range(of: "\n".data(using: .utf8)!) {
            let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
            buffer.removeSubrange(buffer.startIndex...range.lowerBound)
            if let line = String(data: lineData, encoding: .utf8), line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6))
                if jsonString == "[DONE]" { continue }
                if let jsonData = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let delta = choices.first?["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    DispatchQueue.main.async {
                        self.onContent(content)
                    }
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            self.onFinish()
        }
    }
}

// Preview provider
#Preview("AIProcessingView Preview") {
    AIProcessingView(
        image: NSImage(systemSymbolName: "photo", accessibilityDescription: "Preview") ?? NSImage(),
        window: nil,
        id: UUID()
    )
    .frame(width: 600, height: 250)
}
