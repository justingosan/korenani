import SwiftUI
import Foundation

/**
 * A SwiftUI view that renders Markdown text using AttributedString.
 * 
 * This component supports basic Markdown formatting including:
 * - Headers (# ## ###)
 * - Bold (**text**)
 * - Italic (*text*)
 * - Code (`code`)
 * - Lists (- item)
 * - Links [text](url)
 */
struct MarkdownText: View {
    let markdown: String
    
    var body: some View {
        if #available(macOS 12.0, *) {
            // Use native Markdown support in macOS 12+
            Text(try! AttributedString(markdown: markdown, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            // Fallback for older macOS versions - simple text parsing
            Text(parseMarkdownFallback(markdown))
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    /**
     * Simple Markdown parser fallback for older macOS versions.
     * Handles basic formatting by converting Markdown to plain text.
     */
    private func parseMarkdownFallback(_ text: String) -> String {
        var result = text
        
        // Remove Markdown syntax for basic formatting
        // Bold: **text** -> text
        result = result.replacingOccurrences(of: #"\*\*(.*?)\*\*"#, with: "$1", options: .regularExpression)
        
        // Italic: *text* -> text  
        result = result.replacingOccurrences(of: #"\*(.*?)\*"#, with: "$1", options: .regularExpression)
        
        // Code: `code` -> code
        result = result.replacingOccurrences(of: #"`(.*?)`"#, with: "$1", options: .regularExpression)
        
        // Headers: # Header -> Header
        result = result.replacingOccurrences(of: #"^#{1,6}\s*(.*)$"#, with: "$1", options: .regularExpression)
        
        // Links: [text](url) -> text
        result = result.replacingOccurrences(of: #"\[(.*?)\]\(.*?\)"#, with: "$1", options: .regularExpression)
        
        return result
    }
}

/**
 * A more advanced Markdown text view that provides custom styling for different elements.
 * This version offers more control over the appearance of Markdown elements.
 */
struct StyledMarkdownText: View {
    let markdown: String
    let font: Font
    let foregroundColor: Color
    
    init(_ markdown: String, font: Font = .body, foregroundColor: Color = .primary) {
        self.markdown = markdown
        self.font = font
        self.foregroundColor = foregroundColor
    }
    
    var body: some View {
        if #available(macOS 12.0, *) {
            Text(attributedMarkdown)
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        } else {
            Text(parseMarkdownFallback(markdown))
                .font(font)
                .foregroundColor(foregroundColor)
                .textSelection(.enabled)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    @available(macOS 12.0, *)
    private var attributedMarkdown: AttributedString {
        do {
            var attributedString = try AttributedString(
                markdown: markdown,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            )
            
            // Apply custom styling
            let range = attributedString.startIndex..<attributedString.endIndex
            attributedString[range].font = font.weight(.regular)
            attributedString[range].foregroundColor = foregroundColor
            
            return attributedString
        } catch {
            // Fallback to plain text if Markdown parsing fails
            return AttributedString(markdown)
        }
    }
    
    private func parseMarkdownFallback(_ text: String) -> String {
        var result = text
        
        // Remove Markdown syntax for basic formatting
        result = result.replacingOccurrences(of: #"\*\*(.*?)\*\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\*(.*?)\*"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"`(.*?)`"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"^#{1,6}\s*(.*)$"#, with: "$1", options: .regularExpression)
        result = result.replacingOccurrences(of: #"\[(.*?)\]\(.*?\)"#, with: "$1", options: .regularExpression)
        
        return result
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        MarkdownText(markdown: "# Header 1\n\nThis is **bold** text and this is *italic* text.\n\nHere's some `code` and a [link](https://example.com).\n\n- List item 1\n- List item 2")
        
        Divider()
        
        StyledMarkdownText(
            "## Styled Markdown\n\nThis uses **custom styling** with *different* colors.",
            font: .title3,
            foregroundColor: .blue
        )
    }
    .padding()
}
