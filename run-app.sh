#!/bin/bash

# Production build and run script
# Use this to run the app normally (with working keyboard input)

echo "Building and creating app bundle..."
./create-app-bundle.sh

echo "Launching app..."
open MarkdownBrowser.app

echo "Done! The app is now running."