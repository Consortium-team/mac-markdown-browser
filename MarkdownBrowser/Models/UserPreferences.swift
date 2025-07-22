import Foundation
import SwiftUI

/// Manages user preferences and application settings
class UserPreferences: ObservableObject {
    static let shared = UserPreferences()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Favorite Directories
    @Published var favoriteDirectories: [FavoriteDirectory] = [] {
        didSet {
            saveFavoriteDirectories()
        }
    }
    
    // MARK: - Theme Settings
    @Published var selectedTheme: AppTheme = .system {
        didSet {
            userDefaults.set(selectedTheme.rawValue, forKey: UserPreferencesKeys.selectedTheme)
        }
    }
    
    // MARK: - Window State
    @Published var windowFrame: CGRect = CGRect(x: 100, y: 100, width: 1000, height: 700) {
        didSet {
            saveWindowFrame()
        }
    }
    
    @Published var leftPaneWidth: CGFloat = 300 {
        didSet {
            userDefaults.set(leftPaneWidth, forKey: UserPreferencesKeys.leftPaneWidth)
        }
    }
    
    // MARK: - File Filtering
    @Published var showHiddenFiles: Bool = true {
        didSet {
            userDefaults.set(showHiddenFiles, forKey: UserPreferencesKeys.showHiddenFiles)
        }
    }
    
    @Published var fileExtensionFilter: Set<String> = ["md", "markdown", "txt"] {
        didSet {
            let array = Array(fileExtensionFilter)
            userDefaults.set(array, forKey: UserPreferencesKeys.fileExtensionFilter)
        }
    }
    
    // MARK: - Editor Settings
    @Published var editorFontSize: CGFloat = 14 {
        didSet {
            userDefaults.set(editorFontSize, forKey: UserPreferencesKeys.editorFontSize)
        }
    }
    
    @Published var editorFontFamily: String = "SF Mono" {
        didSet {
            userDefaults.set(editorFontFamily, forKey: UserPreferencesKeys.editorFontFamily)
        }
    }
    
    @Published var enableSyntaxHighlighting: Bool = true {
        didSet {
            userDefaults.set(enableSyntaxHighlighting, forKey: UserPreferencesKeys.enableSyntaxHighlighting)
        }
    }
    
    @Published var enableScrollSync: Bool = true {
        didSet {
            userDefaults.set(enableScrollSync, forKey: UserPreferencesKeys.enableScrollSync)
        }
    }
    
    // MARK: - Preview Settings
    @Published var previewTheme: PreviewTheme = .github {
        didSet {
            userDefaults.set(previewTheme.rawValue, forKey: UserPreferencesKeys.previewTheme)
        }
    }
    
    @Published var enableMermaidDiagrams: Bool = true {
        didSet {
            userDefaults.set(enableMermaidDiagrams, forKey: UserPreferencesKeys.enableMermaidDiagrams)
        }
    }
    
    // MARK: - Session Restoration
    @Published var lastOpenedDirectory: URL? {
        didSet {
            saveLastOpenedDirectory()
        }
    }
    
    @Published var lastOpenedFile: URL? {
        didSet {
            saveLastOpenedFile()
        }
    }
    
    internal init() {
        loadPreferences()
    }
    
    // MARK: - Loading and Saving
    private func loadPreferences() {
        loadFavoriteDirectories()
        loadThemeSettings()
        loadWindowState()
        loadFileFiltering()
        loadEditorSettings()
        loadPreviewSettings()
        loadSessionState()
    }
    
    private func loadFavoriteDirectories() {
        if let data = userDefaults.data(forKey: UserPreferencesKeys.favoriteDirectories),
           let favorites = try? JSONDecoder().decode([FavoriteDirectory].self, from: data) {
            favoriteDirectories = favorites
        }
    }
    
    private func saveFavoriteDirectories() {
        if let data = try? JSONEncoder().encode(favoriteDirectories) {
            userDefaults.set(data, forKey: UserPreferencesKeys.favoriteDirectories)
        }
    }
    
    private func loadThemeSettings() {
        if let themeRawValue = userDefaults.object(forKey: UserPreferencesKeys.selectedTheme) as? String,
           let theme = AppTheme(rawValue: themeRawValue) {
            selectedTheme = theme
        }
    }
    
    private func loadWindowState() {
        if let frameData = userDefaults.data(forKey: UserPreferencesKeys.windowFrame),
           let frame = try? JSONDecoder().decode(CGRect.self, from: frameData) {
            windowFrame = frame
        }
        
        leftPaneWidth = userDefaults.object(forKey: UserPreferencesKeys.leftPaneWidth) as? CGFloat ?? 300
    }
    
    private func saveWindowFrame() {
        if let data = try? JSONEncoder().encode(windowFrame) {
            userDefaults.set(data, forKey: UserPreferencesKeys.windowFrame)
        }
    }
    
    private func loadFileFiltering() {
        // Default to true if not set
        if userDefaults.object(forKey: UserPreferencesKeys.showHiddenFiles) != nil {
            showHiddenFiles = userDefaults.bool(forKey: UserPreferencesKeys.showHiddenFiles)
        } else {
            showHiddenFiles = true
        }
        
        if let extensions = userDefaults.array(forKey: UserPreferencesKeys.fileExtensionFilter) as? [String] {
            fileExtensionFilter = Set(extensions)
        }
    }
    
    private func loadEditorSettings() {
        editorFontSize = userDefaults.object(forKey: UserPreferencesKeys.editorFontSize) as? CGFloat ?? 14
        editorFontFamily = userDefaults.string(forKey: UserPreferencesKeys.editorFontFamily) ?? "SF Mono"
        enableSyntaxHighlighting = userDefaults.object(forKey: UserPreferencesKeys.enableSyntaxHighlighting) as? Bool ?? true
        enableScrollSync = userDefaults.object(forKey: UserPreferencesKeys.enableScrollSync) as? Bool ?? true
    }
    
    private func loadPreviewSettings() {
        if let themeRawValue = userDefaults.string(forKey: UserPreferencesKeys.previewTheme),
           let theme = PreviewTheme(rawValue: themeRawValue) {
            previewTheme = theme
        }
        
        enableMermaidDiagrams = userDefaults.object(forKey: UserPreferencesKeys.enableMermaidDiagrams) as? Bool ?? true
    }
    
    private func loadSessionState() {
        if let bookmarkData = userDefaults.data(forKey: UserPreferencesKeys.lastOpenedDirectory) {
            lastOpenedDirectory = resolveSecurityScopedBookmark(bookmarkData)
        }
        
        if let bookmarkData = userDefaults.data(forKey: UserPreferencesKeys.lastOpenedFile) {
            lastOpenedFile = resolveSecurityScopedBookmark(bookmarkData)
        }
    }
    
    private func saveLastOpenedDirectory() {
        if let url = lastOpenedDirectory,
           let bookmarkData = createSecurityScopedBookmark(for: url) {
            userDefaults.set(bookmarkData, forKey: UserPreferencesKeys.lastOpenedDirectory)
        } else {
            userDefaults.removeObject(forKey: UserPreferencesKeys.lastOpenedDirectory)
        }
    }
    
    private func saveLastOpenedFile() {
        if let url = lastOpenedFile,
           let bookmarkData = createSecurityScopedBookmark(for: url) {
            userDefaults.set(bookmarkData, forKey: UserPreferencesKeys.lastOpenedFile)
        } else {
            userDefaults.removeObject(forKey: UserPreferencesKeys.lastOpenedFile)
        }
    }
    
    // MARK: - Favorite Directory Management
    func addFavoriteDirectory(_ url: URL, name: String? = nil) {
        let displayName = name ?? url.lastPathComponent
        
        // Check if already exists
        if favoriteDirectories.contains(where: { $0.url == url }) {
            return
        }
        
        if let bookmarkData = createSecurityScopedBookmark(for: url) {
            let favorite = FavoriteDirectory(
                id: UUID(),
                name: displayName,
                url: url,
                bookmarkData: bookmarkData,
                keyboardShortcut: assignNextAvailableShortcut()
            )
            favoriteDirectories.append(favorite)
        }
    }
    
    func removeFavoriteDirectory(_ favorite: FavoriteDirectory) {
        favoriteDirectories.removeAll { $0.id == favorite.id }
    }
    
    func reorderFavoriteDirectories(from source: IndexSet, to destination: Int) {
        favoriteDirectories.move(fromOffsets: source, toOffset: destination)
        reassignKeyboardShortcuts()
    }
    
    private func assignNextAvailableShortcut() -> Int? {
        let usedShortcuts = Set(favoriteDirectories.compactMap { $0.keyboardShortcut })
        for i in 1...9 {
            if !usedShortcuts.contains(i) {
                return i
            }
        }
        return nil
    }
    
    private func reassignKeyboardShortcuts() {
        for (index, _) in favoriteDirectories.enumerated() {
            if index < 9 {
                favoriteDirectories[index].keyboardShortcut = index + 1
            } else {
                favoriteDirectories[index].keyboardShortcut = nil
            }
        }
    }
    
    // MARK: - Security-Scoped Bookmarks
    private func createSecurityScopedBookmark(for url: URL) -> Data? {
        do {
            return try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("Failed to create security-scoped bookmark: \(error)")
            return nil
        }
    }
    
    private func resolveSecurityScopedBookmark(_ bookmarkData: Data) -> URL? {
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                // Refresh the bookmark
                if let newBookmarkData = createSecurityScopedBookmark(for: url) {
                    // Update the stored bookmark data
                    updateBookmarkData(for: url, with: newBookmarkData)
                }
            }
            
            return url
        } catch {
            print("Failed to resolve security-scoped bookmark: \(error)")
            return nil
        }
    }
    
    private func updateBookmarkData(for url: URL, with newBookmarkData: Data) {
        // Update favorite directories
        for i in 0..<favoriteDirectories.count {
            if favoriteDirectories[i].url == url {
                favoriteDirectories[i].bookmarkData = newBookmarkData
                break
            }
        }
        
        // Update session state
        if lastOpenedDirectory == url {
            userDefaults.set(newBookmarkData, forKey: UserPreferencesKeys.lastOpenedDirectory)
        }
        
        if lastOpenedFile == url {
            userDefaults.set(newBookmarkData, forKey: UserPreferencesKeys.lastOpenedFile)
        }
    }
    
    // MARK: - Reset Methods
    func resetToDefaults() {
        favoriteDirectories = []
        selectedTheme = .system
        windowFrame = CGRect(x: 100, y: 100, width: 1000, height: 700)
        leftPaneWidth = 300
        showHiddenFiles = true
        fileExtensionFilter = ["md", "markdown", "txt"]
        editorFontSize = 14
        editorFontFamily = "SF Mono"
        enableSyntaxHighlighting = true
        enableScrollSync = true
        previewTheme = .github
        enableMermaidDiagrams = true
        lastOpenedDirectory = nil
        lastOpenedFile = nil
        
        // Clear UserDefaults
        for key in UserPreferencesKeys.allKeys {
            userDefaults.removeObject(forKey: key)
        }
    }
}

// MARK: - Supporting Types
struct FavoriteDirectory: Codable, Identifiable {
    let id: UUID
    var name: String
    let url: URL
    var bookmarkData: Data
    var keyboardShortcut: Int?
    
    var displayName: String {
        return name.isEmpty ? url.lastPathComponent : name
    }
}

enum AppTheme: String, CaseIterable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}

enum PreviewTheme: String, CaseIterable, Codable {
    case github = "github"
    case minimal = "minimal"
    case academic = "academic"
    
    var displayName: String {
        switch self {
        case .github: return "GitHub"
        case .minimal: return "Minimal"
        case .academic: return "Academic"
        }
    }
}

// MARK: - UserDefaults Keys
private struct UserPreferencesKeys {
    static let favoriteDirectories = "favoriteDirectories"
    static let selectedTheme = "selectedTheme"
    static let windowFrame = "windowFrame"
    static let leftPaneWidth = "leftPaneWidth"
    static let showHiddenFiles = "showHiddenFiles"
    static let fileExtensionFilter = "fileExtensionFilter"
    static let editorFontSize = "editorFontSize"
    static let editorFontFamily = "editorFontFamily"
    static let enableSyntaxHighlighting = "enableSyntaxHighlighting"
    static let enableScrollSync = "enableScrollSync"
    static let previewTheme = "previewTheme"
    static let enableMermaidDiagrams = "enableMermaidDiagrams"
    static let lastOpenedDirectory = "lastOpenedDirectory"
    static let lastOpenedFile = "lastOpenedFile"
    
    static let allKeys = [
        favoriteDirectories, selectedTheme, windowFrame, leftPaneWidth,
        showHiddenFiles, fileExtensionFilter, editorFontSize, editorFontFamily,
        enableSyntaxHighlighting, enableScrollSync, previewTheme, enableMermaidDiagrams,
        lastOpenedDirectory, lastOpenedFile
    ]
}

// Note: CGRect is already Codable in CoreGraphics, no extension needed