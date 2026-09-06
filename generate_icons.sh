#!/bin/bash

# SolveLog Icon Generator Script
# This script generates all required macOS app icon sizes from your logo

echo "🎨 SolveLog Icon Generator"
echo "=========================="
echo ""

# Check if source logo exists
if [ ! -f "solvelog_logo.png" ]; then
    echo "❌ Error: solvelog_logo.png not found!"
    echo ""
    echo "Please save your logo image as 'solvelog_logo.png' in this directory first."
    echo "The image should be at least 1024x1024 pixels."
    exit 1
fi

# Check if ImageMagick is installed
if ! command -v convert &> /dev/null; then
    echo "❌ Error: ImageMagick not found!"
    echo ""
    echo "Please install ImageMagick first:"
    echo "  brew install imagemagick"
    echo ""
    echo "Or use one of the online tools mentioned in APP_ICON_SETUP_GUIDE.md"
    exit 1
fi

echo "✅ Found source logo: solvelog_logo.png"
echo "✅ ImageMagick installed"
echo ""

# Icon sizes
ICON_DIR="macos/Runner/Assets.xcassets/AppIcon.appiconset"
SIZES=(16 32 64 128 256 512 1024)

echo "📦 Generating icon files..."
echo ""

# Generate each size
for size in "${SIZES[@]}"; do
    output_file="${ICON_DIR}/app_icon_${size}.png"
    echo "  Creating ${size}x${size} → ${output_file}"
    convert solvelog_logo.png -resize ${size}x${size} "${output_file}"
    
    if [ $? -eq 0 ]; then
        echo "    ✅ Success"
    else
        echo "    ❌ Failed"
    fi
done

echo ""
echo "🎉 Icon generation complete!"
echo ""
echo "Next steps:"
echo "  1. Run: flutter clean"
echo "  2. Run: flutter pub get"
echo "  3. Run: flutter run -d macos --release"
echo ""
echo "Your custom SolveLog icon should now appear in the app! 🚀"
