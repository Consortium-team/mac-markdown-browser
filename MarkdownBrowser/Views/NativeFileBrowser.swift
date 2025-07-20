import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct NativeFileBrowser: View {
    @StateObject private var browserModel = NativeFileBrowserModel()
    @State private var selectedFileURL: URL?
    @State private var columnWidth: CGFloat = 400
    
    var body: some View {
        HSplitView {
            // File browser column
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Button(action: { browserModel.goBack() }) {
                        Image(systemName: "chevron.left")
                    }
                    .disabled(!browserModel.canGoBack)
                    
                    Button(action: { browserModel.goForward() }) {
                        Image(systemName: "chevron.right")
                    }
                    .disabled(!browserModel.canGoForward)
                    
                    Spacer()
                    
                    Text(browserModel.currentPath)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Spacer()
                    
                    Button(action: { browserModel.showOpenPanel() }) {
                        Image(systemName: "folder")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Native file browser view
                NativeFileBrowserRepresentable(
                    currentURL: $browserModel.currentURL,
                    selectedFileURL: $selectedFileURL,
                    showHiddenFiles: browserModel.showHiddenFiles
                )
            }
            .frame(minWidth: 300, idealWidth: columnWidth)
            
            // Markdown preview
            VStack {
                if let url = selectedFileURL {
                    FilePreviewView(fileURL: url)
                } else {
                    VStack {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)
                        Text("Select a Markdown file")
                            .font(.title2)
                            .padding(.top)
                        Text("Choose a file from the browser to preview")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(minWidth: 400)
        }
    }
}

// NSViewRepresentable to wrap NSOutlineView for native file browsing
struct NativeFileBrowserRepresentable: NSViewRepresentable {
    @Binding var currentURL: URL?
    @Binding var selectedFileURL: URL?
    let showHiddenFiles: Bool
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let outlineView = NSOutlineView()
        
        // Configure outline view to look like Finder
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .default
        outlineView.floatsGroupRows = false
        outlineView.indentationPerLevel = 16
        outlineView.allowsMultipleSelection = false
        
        // Set up columns like Finder
        let nameColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Name"))
        nameColumn.title = "Name"
        nameColumn.minWidth = 200
        nameColumn.maxWidth = 400
        outlineView.addTableColumn(nameColumn)
        outlineView.outlineTableColumn = nameColumn
        
        let dateColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DateModified"))
        dateColumn.title = "Date Modified"
        dateColumn.width = 120
        outlineView.addTableColumn(dateColumn)
        
        let sizeColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Size"))
        sizeColumn.title = "Size"
        sizeColumn.width = 80
        outlineView.addTableColumn(sizeColumn)
        
        let kindColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("Kind"))
        kindColumn.title = "Kind"
        kindColumn.width = 100
        outlineView.addTableColumn(kindColumn)
        
        // Set up data source and delegate
        let dataSource = FileDataSource(showHiddenFiles: showHiddenFiles)
        context.coordinator.dataSource = dataSource
        outlineView.dataSource = dataSource
        outlineView.delegate = context.coordinator
        
        // Enable drag and drop
        outlineView.registerForDraggedTypes([.fileURL])
        outlineView.setDraggingSourceOperationMask(.move, forLocal: true)
        
        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = false
        
        context.coordinator.outlineView = outlineView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let outlineView = nsView.documentView as? NSOutlineView else { return }
        
        if let url = currentURL {
            context.coordinator.dataSource?.rootURL = url
            outlineView.reloadData()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, NSOutlineViewDelegate {
        let parent: NativeFileBrowserRepresentable
        weak var outlineView: NSOutlineView?
        var dataSource: FileDataSource?
        
        init(parent: NativeFileBrowserRepresentable) {
            self.parent = parent
        }
        
        // MARK: - NSOutlineViewDelegate
        
        func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
            guard let fileItem = item as? FileSystemItem else { return nil }
            
            let cellIdentifier = tableColumn?.identifier ?? NSUserInterfaceItemIdentifier("Name")
            let cellView = outlineView.makeView(withIdentifier: cellIdentifier, owner: self) as? NSTableCellView
                ?? NSTableCellView()
            
            cellView.identifier = cellIdentifier
            
            switch cellIdentifier.rawValue {
            case "Name":
                cellView.textField?.stringValue = fileItem.name
                cellView.imageView?.image = NSWorkspace.shared.icon(forFile: fileItem.url.path)
            case "DateModified":
                if let date = fileItem.dateModified {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    cellView.textField?.stringValue = formatter.string(from: date)
                }
            case "Size":
                if !fileItem.isDirectory {
                    cellView.textField?.stringValue = ByteCountFormatter.string(fromByteCount: fileItem.size, countStyle: .file)
                }
            case "Kind":
                cellView.textField?.stringValue = fileItem.kind
            default:
                break
            }
            
            return cellView
        }
        
        func outlineViewSelectionDidChange(_ notification: Notification) {
            guard let outlineView = notification.object as? NSOutlineView else { return }
            
            let selectedRow = outlineView.selectedRow
            if selectedRow >= 0,
               let item = outlineView.item(atRow: selectedRow) as? FileSystemItem,
               !item.isDirectory {
                parent.selectedFileURL = item.url
            }
        }
        
        // MARK: - Drag and Drop
        
        func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
            guard let fileItem = item as? FileSystemItem else { return nil }
            return fileItem.url as NSURL
        }
        
        func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
            guard let targetItem = item as? FileSystemItem,
                  targetItem.isDirectory else {
                return []
            }
            return .move
        }
        
        func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
            guard let targetItem = item as? FileSystemItem,
                  targetItem.isDirectory,
                  let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
                return false
            }
            
            // Perform file move operations
            for sourceURL in urls {
                let destinationURL = targetItem.url.appendingPathComponent(sourceURL.lastPathComponent)
                do {
                    try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                } catch {
                    print("Failed to move \(sourceURL): \(error)")
                }
            }
            
            // Reload the outline view
            outlineView.reloadData()
            return true
        }
    }
}

// Data source for the outline view
class FileDataSource: NSObject, NSOutlineViewDataSource {
    var rootURL: URL? {
        didSet {
            rootItem = nil
            if let url = rootURL {
                rootItem = FileSystemItem(url: url)
            }
        }
    }
    
    private var rootItem: FileSystemItem?
    let showHiddenFiles: Bool
    
    init(showHiddenFiles: Bool) {
        self.showHiddenFiles = showHiddenFiles
    }
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item == nil {
            return rootItem?.children.count ?? 0
        }
        guard let fileItem = item as? FileSystemItem else { return 0 }
        return fileItem.children.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil {
            return rootItem?.children[index] ?? FileSystemItem(url: URL(fileURLWithPath: "/"))
        }
        guard let fileItem = item as? FileSystemItem else {
            return FileSystemItem(url: URL(fileURLWithPath: "/"))
        }
        return fileItem.children[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let fileItem = item as? FileSystemItem else { return false }
        return fileItem.isDirectory
    }
}

// File system item for the outline view
class FileSystemItem {
    let url: URL
    let name: String
    let isDirectory: Bool
    let dateModified: Date?
    let size: Int64
    let kind: String
    
    private var _children: [FileSystemItem]?
    var children: [FileSystemItem] {
        if _children == nil {
            loadChildren()
        }
        return _children ?? []
    }
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        let resourceValues = try? url.resourceValues(forKeys: [
            .isDirectoryKey,
            .contentModificationDateKey,
            .fileSizeKey,
            .localizedTypeDescriptionKey
        ])
        
        self.isDirectory = resourceValues?.isDirectory ?? false
        self.dateModified = resourceValues?.contentModificationDate
        self.size = Int64(resourceValues?.fileSize ?? 0)
        self.kind = resourceValues?.localizedTypeDescription ?? "Unknown"
    }
    
    private func loadChildren() {
        guard isDirectory else {
            _children = []
            return
        }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [
                    .isDirectoryKey,
                    .contentModificationDateKey,
                    .fileSizeKey,
                    .localizedTypeDescriptionKey
                ],
                options: [.skipsHiddenFiles]
            )
            
            _children = contents
                .filter { url in
                    // Filter to show only directories and supported document types
                    if let isDirectory = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory,
                       isDirectory {
                        return true
                    }
                    // Check if it's a supported file type
                    return url.isSupportedDocument
                }
                .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
                .map { FileSystemItem(url: $0) }
        } catch {
            _children = []
        }
    }
}

// View model for the native file browser
class NativeFileBrowserModel: ObservableObject {
    @Published var currentURL: URL?
    @Published var currentPath: String = ""
    @Published var showHiddenFiles = false
    @Published var canGoBack = false
    @Published var canGoForward = false
    
    private var history: [URL] = []
    private var historyIndex = -1
    
    init() {
        // Start with the user's Documents folder
        currentURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        updatePath()
    }
    
    func navigateTo(_ url: URL) {
        // Add to history
        if historyIndex < history.count - 1 {
            history.removeSubrange((historyIndex + 1)...)
        }
        history.append(url)
        historyIndex = history.count - 1
        
        currentURL = url
        updatePath()
        updateNavigationState()
    }
    
    func goBack() {
        guard historyIndex > 0 else { return }
        historyIndex -= 1
        currentURL = history[historyIndex]
        updatePath()
        updateNavigationState()
    }
    
    func goForward() {
        guard historyIndex < history.count - 1 else { return }
        historyIndex += 1
        currentURL = history[historyIndex]
        updatePath()
        updateNavigationState()
    }
    
    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.title = "Choose a folder"
        
        if panel.runModal() == .OK, let url = panel.url {
            navigateTo(url)
        }
    }
    
    private func updatePath() {
        currentPath = currentURL?.path ?? ""
    }
    
    private func updateNavigationState() {
        canGoBack = historyIndex > 0
        canGoForward = historyIndex < history.count - 1
    }
}