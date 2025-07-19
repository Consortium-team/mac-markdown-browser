#!/bin/bash

# Development build and run script
# Use this when you want to see console output for debugging

echo "Building MarkdownBrowser..."
swift build

echo "Running MarkdownBrowser with console output..."
.build/debug/MarkdownBrowser