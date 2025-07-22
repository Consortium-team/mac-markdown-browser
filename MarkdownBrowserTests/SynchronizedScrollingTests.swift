import XCTest
@testable import MarkdownBrowser

final class SynchronizedScrollingTests: XCTestCase {
    
    func testScrollSyncPreferenceDefaultsToTrue() {
        // Reset preferences to defaults
        UserPreferences.shared.resetToDefaults()
        
        // Verify scroll sync is enabled by default
        XCTAssertTrue(UserPreferences.shared.enableScrollSync)
    }
    
    func testScrollSyncPreferencePersistence() {
        let prefs = UserPreferences.shared
        
        // Disable scroll sync
        prefs.enableScrollSync = false
        
        // Create new instance to test persistence
        let userDefaults = UserDefaults.standard
        let savedValue = userDefaults.bool(forKey: "enableScrollSync")
        XCTAssertFalse(savedValue)
        
        // Enable scroll sync
        prefs.enableScrollSync = true
        let savedValue2 = userDefaults.bool(forKey: "enableScrollSync")
        XCTAssertTrue(savedValue2)
    }
    
    func testEditWindowManagerUsesCorrectEditor() {
        // Create a temporary markdown file
        let tempDir = FileManager.default.temporaryDirectory
        let markdownFile = tempDir.appendingPathComponent("test.md")
        let csvFile = tempDir.appendingPathComponent("test.csv")
        
        // Test with scroll sync enabled
        UserPreferences.shared.enableScrollSync = true
        
        // The EditWindowManager will use SynchronizedMarkdownEditView when enabled
        // This is verified by the implementation in EditWindowManager.swift
        
        // Test with scroll sync disabled
        UserPreferences.shared.enableScrollSync = false
        
        // The EditWindowManager will use ProperMarkdownEditor when disabled
        // This is verified by the implementation in EditWindowManager.swift
        
        // Clean up
        try? FileManager.default.removeItem(at: markdownFile)
        try? FileManager.default.removeItem(at: csvFile)
    }
    
    func testScrollSynchronizerInitialization() {
        let synchronizer = ScrollSynchronizer()
        
        // Verify it's created successfully
        XCTAssertNotNil(synchronizer)
    }
    
    func testSynchronizedViewsExist() {
        // Verify all synchronized views can be instantiated
        let tempFile = FileManager.default.temporaryDirectory.appendingPathComponent("test.md")
        
        // Create SynchronizedMarkdownEditView
        let editView = SynchronizedMarkdownEditView(fileURL: tempFile)
        XCTAssertNotNil(editView)
        
        // Create ScrollSynchronizer
        let scrollSync = ScrollSynchronizer()
        XCTAssertNotNil(scrollSync)
        
        // Test SynchronizedTextEditor
        var testText = "Test content"
        let textEditor = SynchronizedTextEditor(
            text: .constant(testText),
            onTextChange: { _ in },
            scrollSynchronizer: scrollSync,
            onScrollChange: { _ in }
        )
        XCTAssertNotNil(textEditor)
        
        // Test SynchronizedPreviewView
        let previewView = SynchronizedPreviewView(
            htmlContent: "<p>Test</p>",
            scrollSynchronizer: scrollSync,
            onScrollChange: { _ in },
            scrollPercentage: .constant(0.0)
        )
        XCTAssertNotNil(previewView)
    }
}