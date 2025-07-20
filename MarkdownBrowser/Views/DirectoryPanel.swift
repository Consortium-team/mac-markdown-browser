import SwiftUI

struct DirectoryPanel: View {
    @ObservedObject var fileSystemVM: FileSystemViewModel
    @ObservedObject var favoritesVM: FavoritesViewModel
    @State private var dividerPosition: CGFloat = 150
    
    var body: some View {
        VStack(spacing: 0) {
            // Favorites Section with resizable height
            FavoritesSection(
                favoritesVM: favoritesVM,
                fileSystemVM: fileSystemVM
            )
            .frame(height: dividerPosition)
            .frame(maxWidth: .infinity)
            
            // Draggable divider
            Rectangle()
                .fill(Color.clear)
                .frame(height: 6)
                .overlay(
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color.secondary.opacity(0.3))
                        .frame(height: 1)
                )
                .contentShape(Rectangle())
                .cursor(NSCursor.resizeUpDown)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let newPosition = dividerPosition + value.translation.height
                            // Constrain the divider position
                            dividerPosition = max(100, min(300, newPosition))
                        }
                )
            
            // Directory Browser
            DirectoryBrowser(fileSystemVM: fileSystemVM)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// Extension to set cursor
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
    
    /// Conditionally applies a modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

#Preview {
    DirectoryPanel(
        fileSystemVM: FileSystemViewModel(),
        favoritesVM: FavoritesViewModel()
    )
    .frame(width: 350, height: 700)
}