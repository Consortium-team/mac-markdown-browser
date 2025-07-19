# Build Scripts

## run-app.sh
**Use this for normal app usage**
- Creates a proper macOS app bundle
- Keyboard input works correctly
- App runs independently from terminal

## run.sh  
**Use this for development/debugging**
- Runs directly from terminal
- Shows console output
- Keyboard input goes to terminal (not the app)

## create-app-bundle.sh
**Internal script used by run-app.sh**
- Builds release version
- Creates .app bundle with proper Info.plist
- Don't need to run directly