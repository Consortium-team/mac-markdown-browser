import Foundation

/// Generates HTML with Mermaid.js support embedded
class MermaidHTMLGenerator {
    
    /// Wraps the rendered HTML with Mermaid.js support
    static func wrapHTMLWithMermaid(_ html: String, mermaidBlocks: [MermaidBlock]) -> String {
        // If no Mermaid blocks, return original HTML
        guard !mermaidBlocks.isEmpty else {
            return html
        }
        
        // Prepare Mermaid diagram replacements with unique IDs
        var enhancedHTML = html
        for (index, block) in mermaidBlocks.enumerated() {
            let extractedCode = extractMermaidCode(from: block.code)
            let uniqueId = "mermaid-diagram-\(UUID().uuidString)"
            
            let mermaidDiv = """
            <div class="mermaid-container" id="container-\(uniqueId)">
                <pre class="mermaid" data-diagram-id="\(uniqueId)">\(extractedCode.escapedForHTML())</pre>
            </div>
            """
            enhancedHTML = enhancedHTML.replacingOccurrences(of: block.placeholder, with: mermaidDiv)
        }
        
        // Find insertion point for Mermaid script
        let mermaidScript = """
        <script type="module">
            import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
            
            // Initialize Mermaid with configuration
            mermaid.initialize({
                startOnLoad: false,  // We'll manually run it
                theme: window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'default',
                securityLevel: 'loose',
                themeVariables: {
                    fontFamily: '-apple-system, BlinkMacSystemFont, sans-serif'
                },
                flowchart: {
                    useMaxWidth: true,
                    htmlLabels: true,
                    curve: 'basis'
                },
                sequence: {
                    useMaxWidth: true,
                    diagramMarginX: 50,
                    diagramMarginY: 10,
                    actorMargin: 50,
                    width: 150,
                    height: 65,
                    boxMargin: 10,
                    boxTextMargin: 5,
                    noteMargin: 10,
                    messageMargin: 35
                },
                gantt: {
                    numberSectionStyles: 4,
                    axisFormat: '%Y-%m-%d'
                },
                c4: {
                    useMaxWidth: true,
                    diagramMarginX: 50,
                    diagramMarginY: 10,
                    c4ShapeMargin: 50,
                    width: 216,
                    height: 60,
                    boxMargin: 10,
                    c4ShapeInRow: 4,
                    c4BoundaryInRow: 2
                },
                state: {
                    useMaxWidth: true
                },
                er: {
                    useMaxWidth: true
                },
                pie: {
                    useMaxWidth: true
                }
            });
            
            // Render all Mermaid diagrams
            async function renderMermaidDiagrams() {
                const diagrams = document.querySelectorAll('.mermaid');
                console.log('Found ' + diagrams.length + ' Mermaid diagrams to render');
                
                // Process each diagram individually
                for (let i = 0; i < diagrams.length; i++) {
                    const diagram = diagrams[i];
                    const diagramId = diagram.getAttribute('data-diagram-id') || 'mermaid-' + i;
                    const container = diagram.parentElement;
                    
                    try {
                        // Create a unique element for this diagram
                        const tempDiv = document.createElement('div');
                        tempDiv.id = diagramId;
                        tempDiv.className = 'mermaid';
                        tempDiv.textContent = diagram.textContent;
                        
                        // Replace the pre with the div temporarily
                        diagram.style.display = 'none';
                        container.appendChild(tempDiv);
                        
                        // Run mermaid on this specific node
                        await mermaid.run({
                            nodes: [tempDiv],
                            suppressErrors: false
                        });
                        
                        // Remove the original pre element
                        diagram.remove();
                        
                        console.log('Successfully rendered diagram ' + (i + 1));
                        
                        // Enable interactions for this diagram
                        enableMermaidInteractions(tempDiv);
                        
                    } catch (error) {
                        console.error('Failed to render diagram ' + (i + 1) + ':', error);
                        // Show error message
                        diagram.style.display = 'block';
                        diagram.innerHTML = '<div class="mermaid-error">Failed to render diagram: ' + error.message + '</div>';
                    }
                }
            }
            
            // Wait for DOM to be ready
            if (document.readyState === 'loading') {
                document.addEventListener('DOMContentLoaded', renderMermaidDiagrams);
            } else {
                // DOM is already ready
                renderMermaidDiagrams();
            }
            
            // Enable zoom and pan for Mermaid diagrams
            function enableMermaidInteractions(diagramElement) {
                const svg = diagramElement.querySelector('svg');
                if (!svg) return;
                
                let isPanning = false;
                let startX, startY;
                let viewBox = svg.viewBox.baseVal;
                
                // Store original viewBox values
                const originalViewBox = {
                    x: viewBox.x,
                    y: viewBox.y,
                    width: viewBox.width,
                    height: viewBox.height
                };
                
                // Enable pointer events
                svg.style.cursor = 'grab';
                
                // Function to zoom
                function zoomDiagram(scaleFactor) {
                    const rect = svg.getBoundingClientRect();
                    const centerX = rect.width / 2;
                    const centerY = rect.height / 2;
                    
                    const viewX = (centerX / rect.width) * viewBox.width + viewBox.x;
                    const viewY = (centerY / rect.height) * viewBox.height + viewBox.y;
                    
                    viewBox.x = viewX - (viewX - viewBox.x) * scaleFactor;
                    viewBox.y = viewY - (viewY - viewBox.y) * scaleFactor;
                    viewBox.width *= scaleFactor;
                    viewBox.height *= scaleFactor;
                    
                    svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
                }
                
                // Pan functionality
                svg.addEventListener('mousedown', (e) => {
                    isPanning = true;
                    startX = e.clientX;
                    startY = e.clientY;
                    svg.style.cursor = 'grabbing';
                    e.preventDefault();
                });
                
                svg.addEventListener('mousemove', (e) => {
                    if (!isPanning) return;
                    
                    const dx = e.clientX - startX;
                    const dy = e.clientY - startY;
                    const rect = svg.getBoundingClientRect();
                    
                    viewBox.x -= (dx / rect.width) * viewBox.width;
                    viewBox.y -= (dy / rect.height) * viewBox.height;
                    
                    svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
                    
                    startX = e.clientX;
                    startY = e.clientY;
                });
                
                svg.addEventListener('mouseup', () => {
                    isPanning = false;
                    svg.style.cursor = 'grab';
                });
                
                svg.addEventListener('mouseleave', () => {
                    isPanning = false;
                    svg.style.cursor = 'grab';
                });
                
                // Double-click to reset
                svg.addEventListener('dblclick', () => {
                    viewBox.x = originalViewBox.x;
                    viewBox.y = originalViewBox.y;
                    viewBox.width = originalViewBox.width;
                    viewBox.height = originalViewBox.height;
                    svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
                });
                
                // Add zoom controls
                const container = diagramElement.closest('.mermaid-container');
                if (container) {
                    container.style.position = 'relative';
                    
                    // Create zoom controls container
                    const controls = document.createElement('div');
                    controls.className = 'mermaid-controls';
                    controls.style.cssText = `
                        position: absolute;
                        top: 8px;
                        right: 8px;
                        display: flex;
                        gap: 4px;
                        background: rgba(255, 255, 255, 0.9);
                        border-radius: 6px;
                        padding: 4px;
                        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
                        z-index: 10;
                    `;
                    
                    // Dark mode support
                    if (window.matchMedia('(prefers-color-scheme: dark)').matches) {
                        controls.style.background = 'rgba(30, 30, 30, 0.9)';
                    }
                    
                    // Zoom out button
                    const zoomOutBtn = document.createElement('button');
                    zoomOutBtn.innerHTML = '−';
                    zoomOutBtn.title = 'Zoom out';
                    zoomOutBtn.style.cssText = `
                        width: 28px;
                        height: 28px;
                        border: none;
                        background: transparent;
                        cursor: pointer;
                        border-radius: 4px;
                        font-size: 18px;
                        font-weight: bold;
                        display: flex;
                        align-items: center;
                        justify-content: center;
                        transition: background 0.2s;
                    `;
                    zoomOutBtn.onmouseover = () => zoomOutBtn.style.background = 'rgba(0, 0, 0, 0.1)';
                    zoomOutBtn.onmouseout = () => zoomOutBtn.style.background = 'transparent';
                    zoomOutBtn.onclick = () => zoomDiagram(1.2);
                    
                    // Zoom in button
                    const zoomInBtn = document.createElement('button');
                    zoomInBtn.innerHTML = '+';
                    zoomInBtn.title = 'Zoom in';
                    zoomInBtn.style.cssText = zoomOutBtn.style.cssText;
                    zoomInBtn.onmouseover = () => zoomInBtn.style.background = 'rgba(0, 0, 0, 0.1)';
                    zoomInBtn.onmouseout = () => zoomInBtn.style.background = 'transparent';
                    zoomInBtn.onclick = () => zoomDiagram(0.8);
                    
                    // Reset button
                    const resetBtn = document.createElement('button');
                    resetBtn.innerHTML = '⟲';
                    resetBtn.style.cssText = zoomOutBtn.style.cssText;
                    resetBtn.title = 'Reset zoom';
                    resetBtn.onmouseover = () => resetBtn.style.background = 'rgba(0, 0, 0, 0.1)';
                    resetBtn.onmouseout = () => resetBtn.style.background = 'transparent';
                    resetBtn.onclick = () => {
                        viewBox.x = originalViewBox.x;
                        viewBox.y = originalViewBox.y;
                        viewBox.width = originalViewBox.width;
                        viewBox.height = originalViewBox.height;
                        svg.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${viewBox.width} ${viewBox.height}`);
                    };
                    
                    controls.appendChild(zoomOutBtn);
                    controls.appendChild(zoomInBtn);
                    controls.appendChild(resetBtn);
                    container.appendChild(controls);
                    
                    // Add hint text
                    const hint = document.createElement('div');
                    hint.style.cssText = `
                        position: absolute;
                        bottom: 8px;
                        right: 8px;
                        font-size: 11px;
                        color: var(--text-color, #666);
                        opacity: 0.5;
                        pointer-events: none;
                        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    `;
                    hint.textContent = 'Drag to pan • Double-click to reset';
                    container.appendChild(hint);
                }
            }
        </script>
        
        <style>
            .mermaid-container {
                position: relative;
                display: flex;
                justify-content: center;
                align-items: center;
                margin: 16px 0;
                padding: 16px;
                background-color: var(--code-bg, #f6f8fa);
                border-radius: 6px;
                overflow: hidden;
                min-height: 200px;
            }
            
            @media (prefers-color-scheme: dark) {
                .mermaid-container {
                    background-color: var(--code-bg, #161b22);
                }
            }
            
            .mermaid {
                text-align: center;
                max-width: 100%;
                width: 100%;
                height: 100%;
            }
            
            .mermaid svg {
                max-width: 100%;
                height: auto;
                user-select: none;
                -webkit-user-select: none;
            }
            
            /* Prevent text selection in diagrams */
            .mermaid text {
                user-select: none;
                -webkit-user-select: none;
            }
            
            /* Hide the pre element after Mermaid renders */
            .mermaid[data-processed="true"] {
                background: transparent !important;
                border: none !important;
                padding: 0 !important;
            }
            
            /* Ensure the container doesn't interfere with interactions */
            .mermaid-container * {
                pointer-events: auto;
            }
            
            .mermaid-error {
                color: #d73a49;
                background-color: #ffeef0;
                border: 1px solid #ffdce0;
                border-radius: 6px;
                padding: 12px;
                font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                font-size: 14px;
            }
            
            @media (prefers-color-scheme: dark) {
                .mermaid-error {
                    color: #f85149;
                    background-color: #2d1f1f;
                    border-color: #4d2d2d;
                }
            }
        </style>
        """
        
        // Insert before </body> or append at end
        if let range = enhancedHTML.range(of: "</body>", options: .caseInsensitive) {
            enhancedHTML.insert(contentsOf: mermaidScript, at: range.lowerBound)
        } else if let range = enhancedHTML.range(of: "</html>", options: .caseInsensitive) {
            enhancedHTML.insert(contentsOf: mermaidScript, at: range.lowerBound)
        } else {
            enhancedHTML += mermaidScript
        }
        
        return enhancedHTML
    }
    
    private static func extractMermaidCode(from block: String) -> String {
        // Remove the ```mermaid and ``` markers
        let lines = block.components(separatedBy: .newlines)
        
        // Skip empty lines at the beginning and end
        let trimmedLines = lines.drop(while: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
            .reversed()
            .drop(while: { $0.trimmingCharacters(in: .whitespaces).isEmpty })
            .reversed()
        
        // Find the start (skip ```mermaid line)
        var startIndex = 0
        for (index, line) in trimmedLines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") && trimmed.lowercased().contains("mermaid") {
                startIndex = index + 1
                break
            }
        }
        
        // Find the end (skip ``` line)
        var endIndex = trimmedLines.count
        for (index, line) in trimmedLines.enumerated().reversed() {
            if line.trimmingCharacters(in: .whitespaces) == "```" {
                endIndex = index
                break
            }
        }
        
        // Extract only the diagram content
        if startIndex < endIndex {
            let diagramLines = Array(trimmedLines)[startIndex..<endIndex]
            return diagramLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Fallback: if we couldn't parse properly, try a simpler approach
        let simplified = block
            .replacingOccurrences(of: "```mermaid", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return simplified
    }
}

private extension String {
    func escapedForHTML() -> String {
        return self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}