import Foundation
import SwiftUI
import Combine

/// View model for managing favorite directories with drag-and-drop, keyboard shortcuts, and persistence
class FavoritesViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var favorites: [FavoriteDirectory] = []
    @Published var selectedFavorite: FavoriteDirectory?
    @Published var isDraggingOverFavorites: Bool = false
    @Published var draggedItemIndex: Int?
    
    // MARK: - Private Properties
    
    private let preferences = UserPreferences.shared
    private let fileSystemService: FileSystemService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(fileSystemService: FileSystemService = FileSystemService()) {
        self.fileSystemService = fileSystemService
        setupBindings()
        loadFavorites()
    }
    
    // MARK: - Public Methods
    
    /// Add a new favorite directory
    /// - Parameters:
    ///   - url: Directory URL to add
    ///   - name: Optional custom name for the favorite
    func addFavorite(_ url: URL, name: String? = nil) {
        // Check if already exists
        guard !favorites.contains(where: { $0.url == url }) else { return }
        
        // Use UserPreferences to handle bookmark creation
        preferences.addFavoriteDirectory(url, name: name)
    }
    
    /// Remove a favorite directory
    /// - Parameter favorite: Favorite to remove
    func removeFavorite(_ favorite: FavoriteDirectory) {
        preferences.removeFavoriteDirectory(favorite)
    }
    
    /// Rename a favorite directory
    /// - Parameters:
    ///   - favorite: Favorite to rename
    ///   - newName: New display name
    func renameFavorite(_ favorite: FavoriteDirectory, to newName: String) {
        guard favorites.firstIndex(where: { $0.id == favorite.id }) != nil else { return }
        
        var updatedFavorite = favorite
        updatedFavorite.name = newName
        
        // Update in preferences
        var updatedFavorites = preferences.favoriteDirectories
        if let prefIndex = updatedFavorites.firstIndex(where: { $0.id == favorite.id }) {
            updatedFavorites[prefIndex] = updatedFavorite
            preferences.favoriteDirectories = updatedFavorites
        }
    }
    
    /// Reorder favorites
    /// - Parameters:
    ///   - source: Source indices
    ///   - destination: Destination index
    func reorderFavorites(from source: IndexSet, to destination: Int) {
        preferences.reorderFavoriteDirectories(from: source, to: destination)
    }
    
    /// Navigate to a favorite directory
    /// - Parameter favorite: Favorite to navigate to
    /// - Returns: The resolved URL if successful
    @discardableResult
    func navigateToFavorite(_ favorite: FavoriteDirectory) -> URL? {
        if let url = resolveFavoriteURL(favorite) {
            selectedFavorite = favorite
            return url
        }
        return nil
    }
    
    /// Navigate to favorite by keyboard shortcut
    /// - Parameter number: Shortcut number (1-9)
    /// - Returns: The resolved URL if successful
    @discardableResult
    func navigateToFavoriteByShortcut(_ number: Int) -> URL? {
        guard number >= 1 && number <= 9 else { return nil }
        
        if let favorite = favorites.first(where: { $0.keyboardShortcut == number }) {
            return navigateToFavorite(favorite)
        }
        return nil
    }
    
    /// Check if a URL can be accepted as a favorite
    /// - Parameter url: URL to check
    /// - Returns: True if the URL is a directory that can be favorited
    func canAcceptURL(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }
    
    /// Handle drop of URLs
    /// - Parameters:
    ///   - urls: URLs being dropped
    ///   - index: Optional index to insert at
    func handleDrop(of urls: [URL], at index: Int? = nil) {
        for url in urls {
            if canAcceptURL(url) {
                addFavorite(url)
            }
        }
    }
    
    /// Resolve a favorite's URL from its bookmark
    /// - Parameter favorite: Favorite to resolve
    /// - Returns: Resolved URL or nil
    func resolveFavoriteURL(_ favorite: FavoriteDirectory) -> URL? {
        return fileSystemService.resolveBookmark(favorite.bookmarkData)
    }
    
    /// Check if a favorite is still accessible
    /// - Parameter favorite: Favorite to check
    /// - Returns: True if accessible
    func isFavoriteAccessible(_ favorite: FavoriteDirectory) -> Bool {
        guard let url = resolveFavoriteURL(favorite) else { return false }
        defer { fileSystemService.stopAccessingSecurityScopedResource(url) }
        return fileSystemService.isAccessible(url)
    }
    
    /// Update keyboard shortcut for a favorite
    /// - Parameters:
    ///   - favorite: Favorite to update
    ///   - shortcut: New shortcut number (1-9) or nil to remove
    func updateKeyboardShortcut(for favorite: FavoriteDirectory, to shortcut: Int?) {
        guard let index = favorites.firstIndex(where: { $0.id == favorite.id }) else { return }
        
        // If setting a shortcut, ensure it's not already in use
        if let shortcut = shortcut {
            guard shortcut >= 1 && shortcut <= 9 else { return }
            
            // Remove shortcut from any other favorite
            for (idx, fav) in favorites.enumerated() where fav.keyboardShortcut == shortcut && idx != index {
                var updatedFav = fav
                updatedFav.keyboardShortcut = nil
                updateFavoriteInPreferences(updatedFav)
            }
        }
        
        var updatedFavorite = favorite
        updatedFavorite.keyboardShortcut = shortcut
        updateFavoriteInPreferences(updatedFavorite)
    }
    
    /// Get the next available keyboard shortcut
    /// - Returns: Next available shortcut number (1-9) or nil if all are taken
    func getNextAvailableShortcut() -> Int? {
        let usedShortcuts = Set(favorites.compactMap { $0.keyboardShortcut })
        for i in 1...9 {
            if !usedShortcuts.contains(i) {
                return i
            }
        }
        return nil
    }
    
    // MARK: - Context Menu Actions
    
    /// Get context menu items for a favorite
    /// - Parameter favorite: Favorite to get menu for
    /// - Returns: Context menu configuration
    func getContextMenuItems(for favorite: FavoriteDirectory) -> [ContextMenuItem] {
        var items: [ContextMenuItem] = []
        
        // Rename
        items.append(ContextMenuItem(
            title: "Rename",
            systemImage: "pencil",
            action: .rename(favorite)
        ))
        
        // Keyboard shortcut
        if let shortcut = favorite.keyboardShortcut {
            items.append(ContextMenuItem(
                title: "Remove Shortcut (⌘\(shortcut))",
                systemImage: "keyboard.badge.slash",
                action: .removeShortcut(favorite)
            ))
        } else if let nextShortcut = getNextAvailableShortcut() {
            items.append(ContextMenuItem(
                title: "Add Shortcut (⌘\(nextShortcut))",
                systemImage: "keyboard",
                action: .addShortcut(favorite, nextShortcut)
            ))
        }
        
        // Show in Finder
        items.append(ContextMenuItem(
            title: "Show in Finder",
            systemImage: "folder",
            action: .showInFinder(favorite)
        ))
        
        // Separator
        items.append(ContextMenuItem(
            title: "",
            systemImage: "",
            action: .separator
        ))
        
        // Remove
        items.append(ContextMenuItem(
            title: "Remove from Favorites",
            systemImage: "star.slash",
            action: .remove(favorite)
        ))
        
        return items
    }
    
    /// Show favorite in Finder
    /// - Parameter favorite: Favorite to show
    func showInFinder(_ favorite: FavoriteDirectory) {
        if let url = resolveFavoriteURL(favorite) {
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: url.path)
            fileSystemService.stopAccessingSecurityScopedResource(url)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // Subscribe to UserPreferences favorites changes
        preferences.$favoriteDirectories
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favorites in
                self?.favorites = favorites
            }
            .store(in: &cancellables)
    }
    
    private func loadFavorites() {
        favorites = preferences.favoriteDirectories
    }
    
    private func updateFavoriteInPreferences(_ favorite: FavoriteDirectory) {
        var updatedFavorites = preferences.favoriteDirectories
        if let index = updatedFavorites.firstIndex(where: { $0.id == favorite.id }) {
            updatedFavorites[index] = favorite
            preferences.favoriteDirectories = updatedFavorites
        }
    }
}

// MARK: - Supporting Types

struct ContextMenuItem {
    let title: String
    let systemImage: String
    let action: ContextMenuAction
}

enum ContextMenuAction {
    case rename(FavoriteDirectory)
    case remove(FavoriteDirectory)
    case showInFinder(FavoriteDirectory)
    case addShortcut(FavoriteDirectory, Int)
    case removeShortcut(FavoriteDirectory)
    case separator
}

// MARK: - Drag and Drop Support

extension FavoritesViewModel {
    
    /// Start dragging a favorite
    /// - Parameter index: Index of the favorite being dragged
    func startDragging(at index: Int) {
        draggedItemIndex = index
    }
    
    /// End dragging
    func endDragging() {
        draggedItemIndex = nil
        isDraggingOverFavorites = false
    }
    
    /// Handle drag over favorites area
    /// - Parameter isOver: Whether dragging over favorites
    func setDraggingOver(_ isOver: Bool) {
        isDraggingOverFavorites = isOver
    }
    
    /// Get the index to insert a dropped item
    /// - Parameter location: Drop location
    /// - Returns: Index to insert at
    func getDropIndex(at location: CGPoint, in geometry: GeometryProxy) -> Int {
        let itemHeight: CGFloat = 30 // Approximate height of a favorite item
        let index = Int(location.y / itemHeight)
        return min(max(0, index), favorites.count)
    }
}