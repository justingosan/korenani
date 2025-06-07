# KoreNani

A macOS menu bar utility for capturing screenshots and processing them with AI.

## Features
- Menu bar icon with quick screenshot actions
- **Cmd+6** captures the entire display
- **Cmd+7** lets you select an area of the screen
- Floating window shows the screenshot with an AI processing view
- Settings window to configure hotkey and other options

## Building
A GitHub Actions workflow (`.github/workflows/macos-build.yml`) builds the app on each push or pull request using `xcodebuild`.
