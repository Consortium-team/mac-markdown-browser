import SwiftUI
import UniformTypeIdentifiers

// MARK: - Main Explorer View
struct VSCodeStyleExplorer: View {
    @StateObject private var explorerModel = VSCodeExplorerModel()
    @State private var selectedFile: FileNode?
    
    var body: some View {
        HSplitView {
            // VSCode-style sidebar
            VStack(spacing: 0) {
                // Explorer header
                HStack {
                    Text("EXPLORER")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(action: { explorerModel.refreshRoot() }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                
                Divider()
                
                // File tree
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let root = explorerModel.rootNode {
                            FileTreeView(
                                node: root,
                                selectedFile: $selectedFile,
                                expandedNodes: $explorerModel.expandedNodes,
                                explorerModel: explorerModel,
                                level: 0
                            )
                        } else {
                            Button(action: { explorerModel.openFolder() }) {
                                Text("Open a folder to start")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .padding()
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .frame(minWidth: 200, idealWidth: 250)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Content area
            VStack {
                if let file = selectedFile, !file.isDirectory {
                    // Tab bar (VSCode style)
                    HStack(spacing: 0) {
                        HStack(spacing: 4) {
                            Image(systemName: file.iconName)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            Text(file.name)
                                .font(.system(size: 12))
                            Button(action: { selectedFile = nil }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 10))
                            }
                            .buttonStyle(.plain)
                            .opacity(0.6)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.selectedControlColor))
                        
                        Spacer()
                    }
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    // File preview
                    FilePreviewView(fileURL: file.url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    // Empty state
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 64))
                            .foregroundColor(Color(NSColor.quaternaryLabelColor))
                        Text("Select a file to preview")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(NSColor.textBackgroundColor))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: { explorerModel.openFolder() }) {
                    Label("Open Folder", systemImage: "folder")
                }
            }
        }
    }
}

// MARK: - File Tree View
struct FileTreeView: View {
    let node: FileNode
    @Binding var selectedFile: FileNode?
    @Binding var expandedNodes: Set<URL>
    let explorerModel: VSCodeExplorerModel
    let level: Int
    
    @State private var isHovered = false
    @State private var isDropTargeted = false
    
    var isExpanded: Bool {
        expandedNodes.contains(node.url)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Node row
            HStack(spacing: 4) {
                // Indentation
                ForEach(0..<level, id: \.self) { _ in
                    Spacer()
                        .frame(width: 20)
                }
                
                // Chevron for directories
                if node.isDirectory {
                    Button(action: toggleExpanded) {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)
                } else {
                    Spacer()
                        .frame(width: 12)
                }
                
                // Icon
                Image(systemName: node.iconName)
                    .font(.system(size: 14))
                    .foregroundColor(node.isDirectory ? .accentColor : fileIconColor)
                
                // Name
                Text(node.name)
                    .font(.system(size: 13))
                    .foregroundColor(selectedFile?.url == node.url ? .white : .primary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(backgroundColor)
            )
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                if node.isDirectory {
                    toggleExpanded()
                } else {
                    selectedFile = node
                }
            }
            .onDrag {
                NSItemProvider(object: node.url as NSURL)
            }
            .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
                guard node.isDirectory else { return false }
                
                for provider in providers {
                    _ = provider.loadObject(ofClass: URL.self) { url, _ in
                        guard let sourceURL = url else { return }
                        
                        Task { @MainActor in
                            do {
                                let destinationURL = node.url.appendingPathComponent(sourceURL.lastPathComponent)
                                try FileManager.default.moveItem(at: sourceURL, to: destinationURL)
                                
                                // Refresh the explorer
                                explorerModel.refreshRoot()
                            } catch {
                                print("Failed to move file: \(error)")
                            }
                        }
                    }
                }
                return true
            }
            
            // Children
            if node.isDirectory && isExpanded {
                ForEach(node.children) { child in
                    FileTreeView(
                        node: child,
                        selectedFile: $selectedFile,
                        expandedNodes: $expandedNodes,
                        explorerModel: explorerModel,
                        level: level + 1
                    )
                }
            }
        }
    }
    
    private func toggleExpanded() {
        if isExpanded {
            expandedNodes.remove(node.url)
        } else {
            expandedNodes.insert(node.url)
        }
    }
    
    private var backgroundColor: Color {
        if selectedFile?.url == node.url {
            return Color.accentColor
        } else if isDropTargeted && node.isDirectory {
            return Color.accentColor.opacity(0.3)
        } else if isHovered {
            return Color(NSColor.selectedControlColor).opacity(0.5)
        } else {
            return Color.clear
        }
    }
    
    private var fileIconColor: Color {
        // VSCode-style file icon colors
        switch node.fileExtension.lowercased() {
        case "md", "markdown":
            return Color(red: 66/255, green: 165/255, blue: 245/255) // Blue
        case "html", "htm":
            return Color(red: 227/255, green: 79/255, blue: 38/255) // Orange
        case "css":
            return Color(red: 86/255, green: 156/255, blue: 214/255) // Light blue
        case "js", "jsx":
            return Color(red: 240/255, green: 219/255, blue: 79/255) // Yellow
        case "json":
            return Color(red: 251/255, green: 193/255, blue: 60/255) // Gold
        default:
            return .secondary
        }
    }
}

// MARK: - File Node Model
struct FileNode: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let name: String
    let isDirectory: Bool
    let fileExtension: String
    
    var children: [FileNode] = []
    
    init(url: URL) {
        self.url = url
        self.name = url.lastPathComponent
        
        var isDir: ObjCBool = false
        self.isDirectory = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) && isDir.boolValue
        self.fileExtension = url.pathExtension
        
        if isDirectory {
            loadChildren()
        }
    }
    
    mutating func loadChildren() {
        guard isDirectory else { return }
        
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: url,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles]
            )
            
            children = contents
                .sorted { $0.lastPathComponent.localizedCaseInsensitiveCompare($1.lastPathComponent) == .orderedAscending }
                .filter { url in
                    // Filter to show relevant files
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        return true
                    }
                    let ext = url.pathExtension.lowercased()
                    return ext == "md" || ext == "markdown" || ext == "html" || ext == "htm" || 
                           ext == "txt" || ext == "json" || ext == "yml" || ext == "yaml"
                }
                .map { FileNode(url: $0) }
        } catch {
            children = []
        }
    }
    
    var iconName: String {
        if isDirectory {
            return "folder.fill"
        }
        
        // File type specific icons
        switch fileExtension.lowercased() {
        case "md", "markdown":
            return "doc.text"
        case "html", "htm":
            return "globe"
        case "json":
            return "curlybraces"
        case "yml", "yaml":
            return "doc.badge.gearshape"
        default:
            return "doc"
        }
    }
    
    static func == (lhs: FileNode, rhs: FileNode) -> Bool {
        lhs.url == rhs.url
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}

// MARK: - Explorer Model
class VSCodeExplorerModel: ObservableObject {
    @Published var rootNode: FileNode?
    @Published var expandedNodes: Set<URL> = []
    
    init() {
        // Start with home directory
        let homeURL = FileManager.default.homeDirectoryForCurrentUser
        rootNode = FileNode(url: homeURL)
        expandedNodes = [homeURL] // Auto-expand root
    }
    
    func openFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to explore"
        
        if panel.runModal() == .OK, let url = panel.url {
            rootNode = FileNode(url: url)
            expandedNodes = [url] // Auto-expand root
        }
    }
    
    func refreshRoot() {
        if let root = rootNode {
            rootNode = FileNode(url: root.url)
        }
    }
}

// MARK: - Preview
#Preview {
    VSCodeStyleExplorer()
        .frame(width: 1200, height: 800)
}