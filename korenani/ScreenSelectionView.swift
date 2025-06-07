import SwiftUI
import ScreenCaptureKit

/**
 * SwiftUI view that provides a full-screen overlay for selecting a region to capture.
 *
 * This view allows users to click and drag to select a rectangular area of the screen
 * that they want to capture. It displays a semi-transparent overlay with a selection
 * rectangle that can be dragged and resized.
 */
struct ScreenSelectionView: View {
    let display: SCDisplay
    let onSelection: (CGRect) -> Void
    
    @State private var startPoint: CGPoint = .zero
    @State private var endPoint: CGPoint = .zero
    @State private var isDragging = false
    @State private var showInstructions = true
    @State private var globalKeyMonitor: Any?
    @State private var localKeyMonitor: Any?
    
    var selectionRect: CGRect {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                // Instructions
                if showInstructions && !isDragging {
                    VStack(spacing: 16) {
                        Text("Select area to capture")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Click and drag to select an area. Screenshot will be taken automatically when you release the mouse.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("Press Escape to cancel")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.7))
                    )
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
                
                // Selection rectangle
                if isDragging && selectionRect.width > 0 && selectionRect.height > 0 {
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .background(
                            Rectangle()
                                .fill(Color.clear)
                        )
                        .frame(width: selectionRect.width, height: selectionRect.height)
                        .position(
                            x: selectionRect.minX + selectionRect.width / 2,
                            y: selectionRect.minY + selectionRect.height / 2
                        )
                    
                    // Selection info
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Selection: \(Int(selectionRect.width)) × \(Int(selectionRect.height))")
                            .font(.caption)
                            .fontWeight(.medium)
                        Text("Position: (\(Int(selectionRect.minX)), \(Int(selectionRect.minY)))")
                            .font(.caption2)
                    }
                    .foregroundColor(.white)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.8))
                    )
                    .position(
                        x: selectionRect.maxX - 60,
                        y: selectionRect.minY - 30
                    )
                }
            }
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { value in
                    if !isDragging {
                        // Start of drag
                        startPoint = value.startLocation
                        isDragging = true
                        showInstructions = false
                    }
                    endPoint = value.location
                }
                .onEnded { value in
                    // End of drag - automatically take screenshot if selection is valid
                    if selectionRect.width > 10 && selectionRect.height > 10 {
                        // Automatically trigger screenshot capture
                        onSelection(selectionRect)
                    } else {
                        // Reset if selection is too small
                        resetSelection()
                    }
                }
        )
        .onAppear {
            // Monitor escape key globally in case another window is focused
            globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // Escape key
                    onSelection(.zero) // Signal cancellation
                }
            }

            // Also monitor locally while the overlay window is key
            localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 {
                    onSelection(.zero)
                    return nil // Consume event
                }
                return event
            }
        }
        .onDisappear {
            // Clean up key monitors
            if let monitor = globalKeyMonitor {
                NSEvent.removeMonitor(monitor)
                globalKeyMonitor = nil
            }
            if let monitor = localKeyMonitor {
                NSEvent.removeMonitor(monitor)
                localKeyMonitor = nil
            }
        }
    }
    
    private func resetSelection() {
        startPoint = .zero
        endPoint = .zero
        isDragging = false
        showInstructions = true
    }
}

