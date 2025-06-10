# KoreNani

> 🖼️ **Intelligent Screenshot Capture for macOS**

KoreNani is a modern macOS application that combines powerful screenshot capture with AI-powered analysis. Capture any window with a simple hotkey and get instant insights powered by OpenAI's vision models.

![KoreNani Demo](https://via.placeholder.com/800x400/1a1a1a/ffffff?text=KoreNani+Demo+Screenshot)

## ✨ Features

- **🎯 Smart Window Capture** - Capture the active window with a customizable hotkey (default: `⌘6`)
- **🤖 AI-Powered Analysis** - Get instant analysis of your screenshots using OpenAI's GPT-4o vision model
- **⚡ Real-time Streaming** - Watch AI responses stream in real-time as they're generated
- **🔧 Highly Customizable** - Personalize AI prompts, hotkeys, and app behavior
- **🔒 Privacy-First** - API keys stored securely in macOS Keychain
- **🎨 Modern Interface** - Clean, native SwiftUI interface that feels at home on macOS
- **🔄 Auto-start Support** - Optionally start with macOS login
- **🔇 Background Mode** - Run silently in the background with optional dock hiding

## 🚀 Quick Start

### Prerequisites

- macOS 14.0 or later
- OpenAI API key (for AI features)

### Installation

1. Download the latest release from [GitHub Releases](https://github.com/yourusername/korenani/releases)
2. Move KoreNani.app to your Applications folder
3. Launch KoreNani and grant necessary permissions
4. Add your OpenAI API key in Settings

### Basic Usage

1. **Take a Screenshot**: Press `⌘6` (or your custom hotkey) while any window is active
2. **View AI Analysis**: The floating window shows your screenshot with streaming AI analysis
3. **Customize Settings**: Click the camera icon in your menu bar → Settings

## 🛠️ Configuration

### AI Prompt Customization

KoreNani allows you to customize the AI prompt template to get the type of analysis you want:

- **Code Analysis**: "Analyze this code screenshot and explain what it does"
- **UI Review**: "Describe the user interface and suggest improvements"
- **Bug Detection**: "Look for potential issues or bugs in this screenshot"
- **General Analysis**: "What do you see in this screenshot?" (default)

### Hotkey Setup

- Default hotkey: `⌘6`
- Fully customizable through Settings
- Supports modifier combinations (⌘, ⌃, ⌥, ⇧)

### Permissions Required

KoreNani requires the following macOS permissions:
- **Screen Recording**: To capture window screenshots
- **Accessibility**: For global hotkey functionality

## 🏗️ Development

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/korenani.git
cd korenani

# Open in Xcode
open korenani.xcodeproj
```

### Requirements

- Xcode 15.0+
- Swift 5.9+
- macOS 14.0+ deployment target

### Dependencies

- [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess) - Secure keychain storage

## 🔧 Architecture

KoreNani is built with modern Swift practices:

- **SwiftUI** - Modern, declarative UI framework
- **ScreenCaptureKit** - High-performance screen capture
- **Combine** - Reactive programming for settings management
- **KeychainAccess** - Secure API key storage
- **Carbon** - Global hotkey registration

### Project Structure

```
KoreNani/
├── App/                    # Application entry point
├── Core/                   # Core functionality
│   ├── Managers/          # Settings, sound, keychain managers
│   └── Models/            # Data models
├── Features/              # Feature modules
│   ├── AIProcessing/      # AI analysis functionality
│   ├── ScreenCapture/     # Screenshot capture
│   └── Settings/          # Settings interface
└── UI/                    # Reusable UI components
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Quick Contributing Steps

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [SwiftUI](https://developer.apple.com/xcode/swiftui/) and [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
- AI analysis powered by [OpenAI](https://openai.com/)
- Secure storage with [KeychainAccess](https://github.com/kishikawakatsumi/KeychainAccess)

## 📞 Support

- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/yourusername/korenani/issues)
- 💡 **Feature Requests**: [GitHub Discussions](https://github.com/yourusername/korenani/discussions)
- 📧 **Contact**: [your.email@example.com](mailto:your.email@example.com)

---

<p align="center">
  Made with ❤️ for the macOS community
</p>
