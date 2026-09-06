#!/bin/bash

echo "🎨 Updating SolveLog App Icon"
echo "=============================="
echo ""

# Step 1: Clean Flutter build
echo "1️⃣ Cleaning Flutter build..."
flutter clean

# Step 2: Remove build artifacts
echo "2️⃣ Removing build artifacts..."
rm -rf build/
rm -rf macos/build/

# Step 3: Remove DerivedData (Xcode cache)
echo "3️⃣ Clearing Xcode cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData

# Step 4: Get dependencies
echo "4️⃣ Getting dependencies..."
flutter pub get

# Step 5: Build macOS app
echo "5️⃣ Building macOS app..."
flutter build macos --release

# Step 6: Clear macOS icon cache
echo "6️⃣ Clearing macOS icon cache..."
sudo rm -rf /Library/Caches/com.apple.iconservices.store
killall Dock
killall Finder

echo ""
echo "✅ Done! Your app icon should now be updated."
echo ""
echo "If the icon still doesn't change:"
echo "1. Restart your Mac"
echo "2. Run the app from: build/macos/Build/Products/Release/solveLog.app"
echo ""
