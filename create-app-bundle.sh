#!/bin/bash

# Build the Swift executable
echo "Building MarkdownBrowser..."
swift build -c release

# Remove old app bundle if exists
rm -rf MarkdownBrowser.app

# Create app bundle structure
echo "Creating app bundle..."
mkdir -p MarkdownBrowser.app/Contents/{MacOS,Resources}

# Copy executable
cp .build/release/MarkdownBrowser MarkdownBrowser.app/Contents/MacOS/

# Create Info.plist
cat > MarkdownBrowser.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>com.consortiumteam.MarkdownBrowser</string>
    <key>CFBundleExecutable</key>
    <string>MarkdownBrowser</string>
    <key>CFBundleName</key>
    <string>Markdown Browser</string>
    <key>CFBundleDisplayName</key>
    <string>Markdown Browser</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSSupportsAutomaticTermination</key>
    <false/>
    <key>NSSupportsSuddenTermination</key>
    <false/>
</dict>
</plist>
EOF

# Make executable
chmod +x MarkdownBrowser.app/Contents/MacOS/MarkdownBrowser

echo "App bundle created successfully!"
echo ""
echo "To launch the app, run:"
echo "open MarkdownBrowser.app"