#!/usr/bin/env python3
"""
Simple script to create app icons from SVG
This creates a basic PNG icon since we can't render SVG directly
"""

import os
from PIL import Image, ImageDraw, ImageFont
import math

def create_gradient_background(size, color1, color2):
    """Create a gradient background"""
    image = Image.new('RGB', (size, size))
    draw = ImageDraw.Draw(image)
    
    # Create gradient
    for y in range(size):
        # Calculate blend ratio
        ratio = y / size
        r = int(color1[0] * (1 - ratio) + color2[0] * ratio)
        g = int(color1[1] * (1 - ratio) + color2[1] * ratio)
        b = int(color1[2] * (1 - ratio) + color2[2] * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    return image

def create_edubot_icon(size):
    """Create EduBot app icon"""
    # Colors
    bg_color1 = (79, 70, 229)   # Purple
    bg_color2 = (236, 72, 153)  # Pink
    robot_color = (248, 250, 252)  # Light gray
    accent_color = (99, 102, 241)  # Blue
    
    # Create background with gradient
    image = create_gradient_background(size, bg_color1, bg_color2)
    draw = ImageDraw.Draw(image)
    
    # Add rounded corners
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    corner_radius = size // 6
    mask_draw.rounded_rectangle(
        [(0, 0), (size, size)], 
        radius=corner_radius, 
        fill=255
    )
    
    # Apply mask
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(image, (0, 0))
    output.putalpha(mask)
    
    # Convert back to RGB for drawing
    final_image = Image.new('RGB', (size, size), (79, 70, 229))
    final_image.paste(output, (0, 0), output)
    draw = ImageDraw.Draw(final_image)
    
    # Scale factors
    scale = size / 1024
    
    # Robot head
    head_size = int(120 * scale)
    head_x = size // 2
    head_y = int(350 * scale)
    
    # Draw robot head
    draw.ellipse(
        [head_x - head_size, head_y - head_size, 
         head_x + head_size, head_y + head_size],
        fill=robot_color,
        outline=(203, 213, 225),
        width=max(1, int(4 * scale))
    )
    
    # Robot eyes
    eye_size = int(18 * scale)
    left_eye_x = head_x - int(32 * scale)
    right_eye_x = head_x + int(32 * scale)
    eye_y = head_y - int(20 * scale)
    
    draw.ellipse(
        [left_eye_x - eye_size, eye_y - eye_size,
         left_eye_x + eye_size, eye_y + eye_size],
        fill=accent_color
    )
    draw.ellipse(
        [right_eye_x - eye_size, eye_y - eye_size,
         right_eye_x + eye_size, eye_y + eye_size],
        fill=accent_color
    )
    
    # Eye highlights
    highlight_size = int(6 * scale)
    draw.ellipse(
        [left_eye_x - highlight_size + int(5 * scale), eye_y - highlight_size - int(5 * scale),
         left_eye_x + highlight_size + int(5 * scale), eye_y + highlight_size - int(5 * scale)],
        fill=(255, 255, 255)
    )
    draw.ellipse(
        [right_eye_x - highlight_size + int(5 * scale), eye_y - highlight_size - int(5 * scale),
         right_eye_x + highlight_size + int(5 * scale), eye_y + highlight_size - int(5 * scale)],
        fill=(255, 255, 255)
    )
    
    # Robot mouth/speaker
    mouth_width = int(44 * scale)
    mouth_height = int(16 * scale)
    mouth_y = head_y + int(15 * scale)
    
    draw.rounded_rectangle(
        [head_x - mouth_width//2, mouth_y - mouth_height//2,
         head_x + mouth_width//2, mouth_y + mouth_height//2],
        radius=int(8 * scale),
        fill=accent_color
    )
    
    # Speaker lines
    line_width = int(6 * scale)
    line_height = int(10 * scale)
    for i in range(4):
        x = head_x - mouth_width//2 + int((5 + i * 10) * scale)
        draw.rounded_rectangle(
            [x, mouth_y - line_height//2,
             x + line_width, mouth_y + line_height//2],
            radius=1,
            fill=(255, 255, 255)
        )
    
    # Book/homework symbol
    book_size = int(40 * scale)
    book_x = head_x + int(80 * scale)
    book_y = head_y + int(60 * scale)
    
    draw.rounded_rectangle(
        [book_x - book_size, book_y - book_size//2,
         book_x + book_size, book_y + book_size//2],
        radius=int(4 * scale),
        fill=(245, 158, 11),  # Orange
        outline=(217, 119, 6),
        width=max(1, int(2 * scale))
    )
    
    # Add "?" symbol for questions
    if size >= 64:  # Only add text for larger icons
        try:
            font_size = max(12, int(size // 15))
            font = ImageFont.truetype("/System/Library/Fonts/Arial.ttf", font_size)
        except:
            font = ImageFont.load_default()
        
        question_x = head_x - int(120 * scale)
        question_y = head_y - int(80 * scale)
        draw.text(
            (question_x, question_y), 
            "?", 
            fill=(255, 255, 255), 
            font=font,
            anchor="mm"
        )
    
    return final_image

def main():
    """Generate app icons in various sizes"""
    # Create icons directory if it doesn't exist
    os.makedirs("assets/icons/generated", exist_ok=True)
    
    # iOS sizes
    ios_sizes = [
        (20, "20pt"),
        (29, "29pt"),
        (40, "40pt"),
        (58, "58pt"),
        (60, "60pt"),
        (80, "80pt"),
        (87, "87pt"),
        (120, "120pt"),
        (180, "180pt"),
        (1024, "1024pt")
    ]
    
    # Android sizes
    android_sizes = [
        (36, "ldpi"),
        (48, "mdpi"),
        (72, "hdpi"),
        (96, "xhdpi"),
        (144, "xxhdpi"),
        (192, "xxxhdpi"),
        (512, "playstore")
    ]
    
    # Generate iOS icons
    print("Generating iOS icons...")
    for size, name in ios_sizes:
        icon = create_edubot_icon(size)
        icon.save(f"assets/icons/generated/ios_icon_{size}x{size}_{name}.png")
        print(f"Created iOS icon: {size}x{size}")
    
    # Generate Android icons
    print("Generating Android icons...")
    for size, name in android_sizes:
        icon = create_edubot_icon(size)
        icon.save(f"assets/icons/generated/android_icon_{size}x{size}_{name}.png")
        print(f"Created Android icon: {size}x{size}")
    
    # Generate a main app icon
    main_icon = create_edubot_icon(1024)
    main_icon.save("assets/icons/app_icon_1024.png")
    print("Created main app icon: 1024x1024")
    
    print("\n✅ All app icons generated successfully!")
    print("📁 Icons saved in: assets/icons/generated/")
    print("🎨 Main icon saved as: assets/icons/app_icon_1024.png")

if __name__ == "__main__":
    main()