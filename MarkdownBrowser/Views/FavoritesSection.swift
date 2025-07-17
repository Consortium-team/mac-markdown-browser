import SwiftUI
import UniformTypeIdentifiers

/// SwiftUI view for displaying and managing favorite directories
struct FavoritesSection: View {
    @ObservedObject var favoritesVM: FavoritesViewModel
    @ObservedObject var fileSystemVM: FileSystemViewModel
    
    @State private var expandedState: Bool = true
    @State private var renamingFavorite: FavoriteDirectory?
    @State private var renameText: String = ""
    @State private var hoveredFavorite: FavoriteDirectory?
    @State private var dropTargetIndex: Int?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section Header
            HStack {
                Image(systemName: expandedState ? "chevron.down" : "chevron.right")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .frame(width: 16)
                
                Text("FAVORITES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedState.toggle()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            
            if expandedState {
                // Favorites List
                VStack(spacing: 0) {
                    if favoritesVM.favorites.isEmpty {
                        EmptyFavoritesView()
                            .padding(.horizontal, 12)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(Array(favoritesVM.favorites.enumerated()), id: \.element.id) { index, favorite in
                            FavoriteRow(
                                favorite: favorite,
                                isSelected: favoritesVM.selectedFavorite?.id == favorite.id,
                                isRenaming: renamingFavorite?.id == favorite.id,
                                renameText: $renameText,
                                onTap: {
                                    handleFavoriteTap(favorite)
                                },
                                onRename: {
                                    startRenaming(favorite)
                                },
                                onCommitRename: {
                                    commitRename()
                                },
                                onCancelRename: {
                                    cancelRename()
                                }
                            )
                            .onHover { isHovered in
                                hoveredFavorite = isHovered ? favorite : nil
                            }
                            .contextMenu {
                                favoriteContextMenu(for: favorite)
                            }
                            .overlay(
                                Group {
                                    if dropTargetIndex == index {
                                        Rectangle()
                                            .fill(Color.accentColor)
                                            .frame(height: 2)
                                            .offset(y: -15)
                                    }
                                }
                            )
                        }
                        
                        // Drop target at the end
                        if dropTargetIndex == favoritesVM.favorites.count {
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(height: 2)
                                .padding(.horizontal, 12)
                        }
                    }
                }
                .onDrop(of: [.fileURL], delegate: FavoritesDropDelegate(
                    favoritesVM: favoritesVM,
                    dropTargetIndex: $dropTargetIndex
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(favoritesVM.isDraggingOverFavorites ? Color.accentColor.opacity(0.1) : Color.clear)
        )
    }
    
    // MARK: - Helper Methods
    
    private func handleFavoriteTap(_ favorite: FavoriteDirectory) {
        if let url = favoritesVM.navigateToFavorite(favorite) {
            Task {
                await fileSystemVM.navigateToDirectory(url)
            }
        } else {
            // Show error - favorite is not accessible
            showFavoriteNotAccessibleAlert(favorite)
        }
    }
    
    private func startRenaming(_ favorite: FavoriteDirectory) {
        renamingFavorite = favorite
        renameText = favorite.name
    }
    
    private func commitRename() {
        if let favorite = renamingFavorite, !renameText.isEmpty {
            favoritesVM.renameFavorite(favorite, to: renameText)
        }
        cancelRename()
    }
    
    private func cancelRename() {
        renamingFavorite = nil
        renameText = ""
    }
    
    private func showFavoriteNotAccessibleAlert(_ favorite: FavoriteDirectory) {
        let alert = NSAlert()
        alert.messageText = "Favorite Not Accessible"
        alert.informativeText = "The favorite '\(favorite.displayName)' could not be accessed. It may have been moved or deleted."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Remove from Favorites")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            favoritesVM.removeFavorite(favorite)
        }
    }
    
    // MARK: - Context Menu
    
    @ViewBuilder
    private func favoriteContextMenu(for favorite: FavoriteDirectory) -> some View {
        let menuItems = favoritesVM.getContextMenuItems(for: favorite)
        
        ForEach(Array(menuItems.enumerated()), id: \.offset) { _, item in
            switch item.action {
            case .separator:
                Divider()
            case .rename:
                Button(action: { startRenaming(favorite) }) {
                    Label(item.title, systemImage: item.systemImage)
                }
            case .remove:
                Button(action: { favoritesVM.removeFavorite(favorite) }) {
                    Label(item.title, systemImage: item.systemImage)
                }
            case .showInFinder:
                Button(action: { favoritesVM.showInFinder(favorite) }) {
                    Label(item.title, systemImage: item.systemImage)
                }
            case .addShortcut(_, let shortcut):
                Button(action: { favoritesVM.updateKeyboardShortcut(for: favorite, to: shortcut) }) {
                    Label(item.title, systemImage: item.systemImage)
                }
            case .removeShortcut:
                Button(action: { favoritesVM.updateKeyboardShortcut(for: favorite, to: nil) }) {
                    Label(item.title, systemImage: item.systemImage)
                }
            }
        }
    }
}

// MARK: - FavoriteRow

struct FavoriteRow: View {
    let favorite: FavoriteDirectory
    let isSelected: Bool
    let isRenaming: Bool
    @Binding var renameText: String
    let onTap: () -> Void
    let onRename: () -> Void
    let onCommitRename: () -> Void
    let onCancelRename: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "folder")
                .font(.system(size: 14))
                .foregroundColor(isSelected ? .white : .accentColor)
            
            if isRenaming {
                TextField("Name", text: $renameText, onCommit: onCommitRename)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13))
                    .onExitCommand(perform: onCancelRename)
            } else {
                Text(favorite.displayName)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            
            Spacer()
            
            if let shortcut = favorite.keyboardShortcut {
                Text("⌘\(shortcut)")
                    .font(.system(size: 11))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.accentColor : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !isRenaming {
                onTap()
            }
        }
        .onDoubleClick {
            if !isRenaming {
                onRename()
            }
        }
    }
}

// MARK: - EmptyFavoritesView

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.slash")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No Favorites")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            
            Text("Drag folders here or right-click to add favorites")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Drop Delegate

struct FavoritesDropDelegate: DropDelegate {
    let favoritesVM: FavoritesViewModel
    @Binding var dropTargetIndex: Int?
    
    func validateDrop(info: DropInfo) -> Bool {
        return info.hasItemsConforming(to: [.fileURL])
    }
    
    func dropEntered(info: DropInfo) {
        favoritesVM.setDraggingOver(true)
    }
    
    func dropExited(info: DropInfo) {
        favoritesVM.setDraggingOver(false)
        dropTargetIndex = nil
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Calculate drop index based on location
        // This would need the geometry of the favorites list
        return DropProposal(operation: .copy)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        favoritesVM.setDraggingOver(false)
        dropTargetIndex = nil
        
        let providers = info.itemProviders(for: [.fileURL])
        var urls: [URL] = []
        
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
                if let data = item as? Data,
                   let url = URL(dataRepresentation: data, relativeTo: nil) {
                    urls.append(url)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            favoritesVM.handleDrop(of: urls)
        }
        
        return true
    }
}

// MARK: - Keyboard Shortcuts

struct FavoritesKeyboardShortcuts: View {
    let favoritesVM: FavoritesViewModel
    let fileSystemVM: FileSystemViewModel
    
    var body: some View {
        ForEach(1...9, id: \.self) { number in
            EmptyView()
                .keyboardShortcut(KeyEquivalent(Character("\(number)")), modifiers: .command)
                .onTapGesture {} // Required for keyboard shortcut to work
                .task {
                    // Set up the action for this shortcut
                    if let url = favoritesVM.navigateToFavoriteByShortcut(number) {
                        await fileSystemVM.navigateToDirectory(url)
                    }
                }
        }
    }
}

// MARK: - View Extension for Double Click

extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.onTapGesture(count: 2, perform: action)
    }
}