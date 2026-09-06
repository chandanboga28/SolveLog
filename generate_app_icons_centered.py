#!/usr/bin/env python3
"""
Generate macOS app icons from SolveLog logo - PROPERLY CENTERED AND SCALED.
Extracts the circuit/C symbol, scales to 88-92% of canvas, centers precisely.
"""

from PIL import Image, ImageDraw
import os

# Paths
SOURCE_LOGO = "solvelog_logo.png"
ICON_DIR = "macos/Runner/Assets.xcassets/AppIcon.appiconset"

# Required icon sizes for macOS
ICON_SIZES = [16, 32, 64, 128, 256, 512, 1024]

def find_symbol_bounds(img):
    """Find the actual bounds of the gold symbol (non-black pixels)"""
    pixels = img.load()
    width, height = img.size
    
    min_x, min_y = width, height
    max_x, max_y = 0, 0
    
    # Threshold for considering a pixel as part of the symbol (not pure black)
    threshold = 20
    
    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            # If pixel is brighter than threshold, it's part of the symbol
            if r > threshold or g > threshold or b > threshold:
                min_x = min(min_x, x)
                max_x = max(max_x, x)
                min_y = min(min_y, y)
                max_y = max(max_y, y)
    
    return (min_x, min_y, max_x, max_y)

def main():
    print("🎨 SolveLog Icon Generator - CENTERED & SCALED")
    print("=" * 60)
    
    # Load source image
    print(f"\n📂 Loading source logo: {SOURCE_LOGO}")
    try:
        img = Image.open(SOURCE_LOGO)
        print(f"   ✅ Loaded: {img.size[0]}x{img.size[1]} pixels")
    except Exception as e:
        print(f"   ❌ Error loading image: {e}")
        return False
    
    # Find the actual bounds of the symbol (excluding black background)
    print(f"\n🔍 Detecting symbol boundaries...")
    bounds = find_symbol_bounds(img)
    min_x, min_y, max_x, max_y = bounds
    symbol_width = max_x - min_x
    symbol_height = max_y - min_y
    print(f"   ✅ Symbol found at: ({min_x}, {min_y}) to ({max_x}, {max_y})")
    print(f"   ✅ Symbol dimensions: {symbol_width}x{symbol_height} pixels")
    
    # Crop to the symbol bounds with small buffer
    buffer = 10  # Small buffer to avoid cutting off edges
    crop_box = (
        max(0, min_x - buffer),
        max(0, min_y - buffer),
        min(img.size[0], max_x + buffer),
        min(img.size[1], max_y + buffer)
    )
    
    print(f"\n✂️  Cropping to symbol with buffer...")
    symbol_img = img.crop(crop_box)
    print(f"   ✅ Cropped: {symbol_img.size[0]}x{symbol_img.size[1]} pixels")
    
    # Calculate the target size for the symbol (88-92% of canvas)
    # We'll use 92% as the target for maximum size with minimal padding
    target_scale = 0.92
    
    # Determine the largest dimension of the cropped symbol
    symbol_w, symbol_h = symbol_img.size
    max_symbol_dim = max(symbol_w, symbol_h)
    
    # Create square canvas (using the max dimension as base)
    # The canvas should be sized so the symbol occupies ~90% of it
    canvas_size = int(max_symbol_dim / target_scale)
    
    # Create black canvas
    canvas = Image.new('RGB', (canvas_size, canvas_size), color=(0, 0, 0))
    
    # Calculate padding to center the symbol precisely
    # The symbol should fill target_scale of the canvas
    padding_x = (canvas_size - symbol_w) // 2
    padding_y = (canvas_size - symbol_h) // 2
    
    # Paste the symbol centered on the canvas
    canvas.paste(symbol_img, (padding_x, padding_y))
    
    print(f"   ✅ Centered on {canvas_size}x{canvas_size} canvas")
    print(f"   ✅ Symbol fills ~{target_scale*100:.0f}% of icon space")
    print(f"   ✅ Padding: {padding_x}px horizontal, {padding_y}px vertical")
    
    # Generate all icon sizes
    print(f"\n📦 Generating perfectly centered icon sizes:")
    
    for size in ICON_SIZES:
        output_path = os.path.join(ICON_DIR, f"app_icon_{size}.png")
        
        # Resize with high-quality antialiasing
        resized = canvas.resize((size, size), Image.Resampling.LANCZOS)
        
        # Save with optimization
        resized.save(output_path, "PNG", optimize=True)
        
        file_size = os.path.getsize(output_path)
        file_size_kb = file_size / 1024
        
        # Calculate actual padding percentage at this size
        actual_padding_pct = (padding_x / canvas_size) * 100
        
        print(f"   ✅ {size:4}x{size:<4} → {output_path}")
        print(f"      ({file_size_kb:5.1f} KB, {actual_padding_pct:.1f}% edge padding)")
    
    print(f"\n✅ All icons generated with precise centering!")
    print(f"\n📊 Final specs:")
    print(f"   • Symbol occupies ~{target_scale*100:.0f}% of icon")
    print(f"   • Edge padding: ~{(1-target_scale)*100/2:.1f}% on all sides")
    print(f"   • Perfectly centered vertically and horizontally")
    print(f"\nNext steps:")
    print(f"  1. Run: flutter clean")
    print(f"  2. Run: flutter pub get")
    print(f"  3. Run: flutter run -d macos")
    
    return True

if __name__ == "__main__":
    success = main()
    exit(0 if success else 1)
