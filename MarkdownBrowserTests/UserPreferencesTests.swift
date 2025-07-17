import XCTest
import Foundation
@testable import MarkdownBrowser

final class UserPreferencesTests: XCTestCase {
    
    var preferences: UserPreferences!
    var tempDirectory: URL!
    var testDirectory1: URL!
    var testDirectory2: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create a fresh UserPreferences instance for testing
        preferences = UserPreferences()
        preferences.resetToDefaults()
        
        // Create temporary directories for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        testDirectory1 = tempDirectory.appendingPathComponent("TestDir1")
        testDirectory2 = tempDirectory.appendingPathComponent("TestDir2")
        try FileManager.default.createDirectory(at: testDirectory1, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: testDirectory2, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        preferences.resetToDefaults()
        
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        try await super.tearDown()
    }
    
    func testDefaultValues() {
        XCTAssertTrue(preferences.favoriteDirectories.isEmpty)
        XCTAssertEqual(preferences.selectedTheme, .system)
        XCTAssertEqual(preferences.windowFrame, CGRect(x: 100, y: 100, width: 1000, height: 700))
        XCTAssertEqual(preferences.leftPaneWidth, 300)
        XCTAssertFalse(preferences.showHiddenFiles)
        XCTAssertEqual(preferences.fileExtensionFilter, ["md", "markdown", "txt"])
        XCTAssertEqual(preferences.editorFontSize, 14)
        XCTAssertEqual(preferences.editorFontFamily, "SF Mono")
        XCTAssertTrue(preferences.enableSyntaxHighlighting)
        XCTAssertEqual(preferences.previewTheme, .github)
        XCTAssertTrue(preferences.enableMermaidDiagrams)
        XCTAssertNil(preferences.lastOpenedDirectory)
        XCTAssertNil(preferences.lastOpenedFile)
    }
    
    func testThemeSettings() {
        preferences.selectedTheme = .dark
        XCTAssertEqual(preferences.selectedTheme, .dark)
        
        preferences.selectedTheme = .light
        XCTAssertEqual(preferences.selectedTheme, .light)
        
        preferences.selectedTheme = .system
        XCTAssertEqual(preferences.selectedTheme, .system)
    }
    
    func testWindowState() {
        let newFrame = CGRect(x: 200, y: 150, width: 1200, height: 800)
        preferences.windowFrame = newFrame
        XCTAssertEqual(preferences.windowFrame, newFrame)
        
        preferences.leftPaneWidth = 400
        XCTAssertEqual(preferences.leftPaneWidth, 400)
    }
    
    func testFileFiltering() {
        preferences.showHiddenFiles = true
        XCTAssertTrue(preferences.showHiddenFiles)
        
        let newFilter: Set<String> = ["md", "txt", "rst"]
        preferences.fileExtensionFilter = newFilter
        XCTAssertEqual(preferences.fileExtensionFilter, newFilter)
    }
    
    func testEditorSettings() {
        preferences.editorFontSize = 16
        XCTAssertEqual(preferences.editorFontSize, 16)
        
        preferences.editorFontFamily = "Monaco"
        XCTAssertEqual(preferences.editorFontFamily, "Monaco")
        
        preferences.enableSyntaxHighlighting = false
        XCTAssertFalse(preferences.enableSyntaxHighlighting)
    }
    
    func testPreviewSettings() {
        preferences.previewTheme = .minimal
        XCTAssertEqual(preferences.previewTheme, .minimal)
        
        preferences.enableMermaidDiagrams = false
        XCTAssertFalse(preferences.enableMermaidDiagrams)
    }
    
    func testAddFavoriteDirectory() {
        preferences.addFavoriteDirectory(testDirectory1, name: "Test Directory 1")
        
        XCTAssertEqual(preferences.favoriteDirectories.count, 1)
        XCTAssertEqual(preferences.favoriteDirectories[0].name, "Test Directory 1")
        XCTAssertEqual(preferences.favoriteDirectories[0].url, testDirectory1)
        XCTAssertEqual(preferences.favoriteDirectories[0].keyboardShortcut, 1)
    }
    
    func testAddMultipleFavoriteDirectories() {
        preferences.addFavoriteDirectory(testDirectory1, name: "First")
        preferences.addFavoriteDirectory(testDirectory2, name: "Second")
        
        XCTAssertEqual(preferences.favoriteDirectories.count, 2)
        XCTAssertEqual(preferences.favoriteDirectories[0].keyboardShortcut, 1)
        XCTAssertEqual(preferences.favoriteDirectories[1].keyboardShortcut, 2)
    }
    
    func testAddDuplicateFavoriteDirectory() {
        preferences.addFavoriteDirectory(testDirectory1, name: "First")
        preferences.addFavoriteDirectory(testDirectory1, name: "Duplicate")
        
        // Should not add duplicate
        XCTAssertEqual(preferences.favoriteDirectories.count, 1)
        XCTAssertEqual(preferences.favoriteDirectories[0].name, "First")
    }
    
    func testRemoveFavoriteDirectory() {
        preferences.addFavoriteDirectory(testDirectory1, name: "First")
        preferences.addFavoriteDirectory(testDirectory2, name: "Second")
        
        let firstFavorite = preferences.favoriteDirectories[0]
        preferences.removeFavoriteDirectory(firstFavorite)
        
        XCTAssertEqual(preferences.favoriteDirectories.count, 1)
        XCTAssertEqual(preferences.favoriteDirectories[0].name, "Second")
    }
    
    func testReorderFavoriteDirectories() {
        preferences.addFavoriteDirectory(testDirectory1, name: "First")
        preferences.addFavoriteDirectory(testDirectory2, name: "Second")
        
        let originalFirst = preferences.favoriteDirectories[0].name
        let originalSecond = preferences.favoriteDirectories[1].name
        
        // Move first item to position 1 (after second)
        preferences.reorderFavoriteDirectories(from: IndexSet([0]), to: 2)
        
        XCTAssertEqual(preferences.favoriteDirectories[0].name, originalSecond)
        XCTAssertEqual(preferences.favoriteDirectories[1].name, originalFirst)
        
        // Keyboard shortcuts should be reassigned
        XCTAssertEqual(preferences.favoriteDirectories[0].keyboardShortcut, 1)
        XCTAssertEqual(preferences.favoriteDirectories[1].keyboardShortcut, 2)
    }
    
    func testKeyboardShortcutAssignment() {
        // Add 10 directories (more than available shortcuts)
        for i in 1...10 {
            let dir = tempDirectory.appendingPathComponent("Dir\(i)")
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            preferences.addFavoriteDirectory(dir, name: "Directory \(i)")
        }
        
        XCTAssertEqual(preferences.favoriteDirectories.count, 10)
        
        // First 9 should have shortcuts
        for i in 0..<9 {
            XCTAssertEqual(preferences.favoriteDirectories[i].keyboardShortcut, i + 1)
        }
        
        // 10th should not have a shortcut
        XCTAssertNil(preferences.favoriteDirectories[9].keyboardShortcut)
    }
    
    func testSessionState() {
        preferences.lastOpenedDirectory = testDirectory1
        XCTAssertEqual(preferences.lastOpenedDirectory, testDirectory1)
        
        let testFile = testDirectory1.appendingPathComponent("test.md")
        try? "# Test".write(to: testFile, atomically: true, encoding: .utf8)
        
        preferences.lastOpenedFile = testFile
        XCTAssertEqual(preferences.lastOpenedFile, testFile)
    }
    
    func testFavoriteDirectoryDisplayName() {
        let favorite = FavoriteDirectory(
            id: UUID(),
            name: "Custom Name",
            url: testDirectory1,
            bookmarkData: Data(),
            keyboardShortcut: 1
        )
        
        XCTAssertEqual(favorite.displayName, "Custom Name")
        
        let favoriteWithEmptyName = FavoriteDirectory(
            id: UUID(),
            name: "",
            url: testDirectory1,
            bookmarkData: Data(),
            keyboardShortcut: 1
        )
        
        XCTAssertEqual(favoriteWithEmptyName.displayName, testDirectory1.lastPathComponent)
    }
    
    func testAppThemeDisplayNames() {
        XCTAssertEqual(AppTheme.light.displayName, "Light")
        XCTAssertEqual(AppTheme.dark.displayName, "Dark")
        XCTAssertEqual(AppTheme.system.displayName, "System")
    }
    
    func testPreviewThemeDisplayNames() {
        XCTAssertEqual(PreviewTheme.github.displayName, "GitHub")
        XCTAssertEqual(PreviewTheme.minimal.displayName, "Minimal")
        XCTAssertEqual(PreviewTheme.academic.displayName, "Academic")
    }
    
    func testCGRectCodable() throws {
        let originalRect = CGRect(x: 10.5, y: 20.5, width: 100.5, height: 200.5)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalRect)
        
        let decoder = JSONDecoder()
        let decodedRect = try decoder.decode(CGRect.self, from: data)
        
        XCTAssertEqual(originalRect, decodedRect)
    }
    
    func testFavoriteDirectoryCodable() throws {
        let favorite = FavoriteDirectory(
            id: UUID(),
            name: "Test Directory",
            url: testDirectory1,
            bookmarkData: Data([1, 2, 3, 4]),
            keyboardShortcut: 5
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(favorite)
        
        let decoder = JSONDecoder()
        let decodedFavorite = try decoder.decode(FavoriteDirectory.self, from: data)
        
        XCTAssertEqual(favorite.id, decodedFavorite.id)
        XCTAssertEqual(favorite.name, decodedFavorite.name)
        XCTAssertEqual(favorite.url, decodedFavorite.url)
        XCTAssertEqual(favorite.bookmarkData, decodedFavorite.bookmarkData)
        XCTAssertEqual(favorite.keyboardShortcut, decodedFavorite.keyboardShortcut)
    }
    
    func testResetToDefaults() {
        // Modify all settings
        preferences.addFavoriteDirectory(testDirectory1, name: "Test")
        preferences.selectedTheme = .dark
        preferences.windowFrame = CGRect(x: 500, y: 500, width: 800, height: 600)
        preferences.leftPaneWidth = 250
        preferences.showHiddenFiles = true
        preferences.fileExtensionFilter = ["txt"]
        preferences.editorFontSize = 18
        preferences.editorFontFamily = "Monaco"
        preferences.enableSyntaxHighlighting = false
        preferences.previewTheme = .minimal
        preferences.enableMermaidDiagrams = false
        preferences.lastOpenedDirectory = testDirectory1
        
        // Reset to defaults
        preferences.resetToDefaults()
        
        // Verify all settings are back to defaults
        XCTAssertTrue(preferences.favoriteDirectories.isEmpty)
        XCTAssertEqual(preferences.selectedTheme, .system)
        XCTAssertEqual(preferences.windowFrame, CGRect(x: 100, y: 100, width: 1000, height: 700))
        XCTAssertEqual(preferences.leftPaneWidth, 300)
        XCTAssertFalse(preferences.showHiddenFiles)
        XCTAssertEqual(preferences.fileExtensionFilter, ["md", "markdown", "txt"])
        XCTAssertEqual(preferences.editorFontSize, 14)
        XCTAssertEqual(preferences.editorFontFamily, "SF Mono")
        XCTAssertTrue(preferences.enableSyntaxHighlighting)
        XCTAssertEqual(preferences.previewTheme, .github)
        XCTAssertTrue(preferences.enableMermaidDiagrams)
        XCTAssertNil(preferences.lastOpenedDirectory)
        XCTAssertNil(preferences.lastOpenedFile)
    }
    
    func testThemeEnumCases() {
        let allThemes = AppTheme.allCases
        XCTAssertEqual(allThemes.count, 3)
        XCTAssertTrue(allThemes.contains(.light))
        XCTAssertTrue(allThemes.contains(.dark))
        XCTAssertTrue(allThemes.contains(.system))
    }
    
    func testPreviewThemeEnumCases() {
        let allThemes = PreviewTheme.allCases
        XCTAssertEqual(allThemes.count, 3)
        XCTAssertTrue(allThemes.contains(.github))
        XCTAssertTrue(allThemes.contains(.minimal))
        XCTAssertTrue(allThemes.contains(.academic))
    }
}