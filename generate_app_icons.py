#!/usr/bin/env python3
"""
Generate macOS app icons from SolveLog logo.
Extracts only the circuit/C symbol (without text) and creates all required sizes.
"""

from PIL import Image
import os

# Paths
SOURCE_LOGO = "solvelog_logo.png"
ICON_DIR = "macos/Runner/Assets.xcassets/AppIcon.appiconset"

# Required icon sizes for macOS
ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]

def main():
    print("🎨 SolveLog Icon Generator")
    print("=" * 50)
    
    # Load source image
    print(f"\n📂 Loading source logo: {SOURCE_LOGO}")
    try:
        img = Image.open(SOURCE_LOGO)
        print(f"   ✅ Loaded: {img.size[0]}x{img.size[1]} pixels")
    except Exception as e:
        print(f"   ❌ Error loading image: {e}")
        return False
    
    # The logo has the symbol in the upper portion and text in the lower portion
    # We need to crop to get only the circuit/C symbol
    # Adjusting to position the symbol centered vertically in the icon
    width, height = img.size
    
    # Crop to get only the symbol - balanced positioning
    symbol_height = int(height * 0.58)  # Take 58% where symbol is
    top_padding = int(height * 0.06)     # Start slightly lower for better centering
    bottom_crop = top_padding + symbol_height
    
    # Keep it centered with some horizontal padding
    left_padding = int(width * 0.17)
    right_padding = int(width * 0.17)
    
    print(f"\n✂️  Cropping to extract symbol only (removing text)")
    symbol_img = img.crop((left_padding, top_padding, width - right_padding, bottom_crop))
    print(f"   ✅ Symbol extracted: {symbol_img.size[0]}x{symbol_img.size[1]} pixels")
    
    # Make it square by padding with the background color (black)
    # Get the dominant dark color from corners
    symbol_width, symbol_height = symbol_img.size
    max_dim = max(symbol_width, symbol_height)
    
    # Create square canvas with black background
    square_img = Image.new('RGB', (max_dim, max_dim), color=(0, 0, 0))
    
    # Center the symbol
    x_offset = (max_dim - symbol_width) // 2
    y_offset = (max_dim - symbol_height) // 2
    square_img.paste(symbol_img, (x_offset, y_offset))
    
    print(f"   ✅ Made square: {square_img.size[0]}x{square_img.size[1]} pixels")
    
    # Generate all icon sizes
    print(f"\n📦 Generating icon sizes:")
    
    for size in ICON_SIZES:
        output_path = os.path.join(ICON_DIR, f"app_icon_{size}.png")
        
        # Resize with high-quality antialiasing
        resized = square_img.resize((size, size), Image.Resampling.LANCZOS)
        
        # Save with optimization
        resized.save(output_path, "PNG", optimize=True)
        
        file_size = os.path.getsize(output_path)
        file_size_kb = file_size / 1024
        print(f"   ✅ {size}x{size:4} → {output_path} ({file_size_kb:.1f} KB)")
    
    print(f"\n✅ All icons generated successfully!")
    print(f"\nNext steps:")
    print(f"  1. Run: flutter clean")
    print(f"  2. Run: flutter pub get")
    print(f"  3. Run: flutter run -d macos")
    
    return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
