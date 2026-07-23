import os
from PIL import Image

src_path = r'C:\Users\FR Abderrahmane\.gemini\antigravity-ide\brain\91a5d869-5326-4758-9b6d-5c60702182e8\media__1784771911122.png'
img = Image.open(src_path)
width, height = img.size
print(f"Original size: {width}x{height}")

# Crop the center part where the logo emblem and REVO text are located
# Bounding box around logo (excluding transparent checkerboard border)
# The logo is centered: x roughly 350 to 650, y roughly 200 to 800
# Let's auto-crop or crop bounds:
left = int(width * 0.35)
top = int(height * 0.15)
right = int(width * 0.65)
bottom = int(height * 0.85)

cropped = img.crop((left, top, right, bottom))
cropped_width, cropped_height = cropped.size

# Save as clean assets
assets_dir = r'c:\Users\FR Abderrahmane\Documents\Revo app\assets\images'
os.makedirs(assets_dir, exist_ok=True)
cropped.save(os.path.join(assets_dir, 'logo.png'))

# Also create square app icon (512x512)
# Make a dark background or transparent background square
square_size = max(cropped_width, cropped_height) + 40
square_img = Image.new('RGBA', (square_size, square_size), (24, 24, 27, 255)) # sleek dark background
paste_x = (square_size - cropped_width) // 2
paste_y = (square_size - cropped_height) // 2
square_img.paste(cropped, (paste_x, paste_y), cropped if cropped.mode == 'RGBA' else None)

icon_512 = square_img.resize((512, 512), Image.Resampling.LANCZOS)
icon_512.save(os.path.join(assets_dir, 'app_icon.png'))

# Save Android mipmap sizes
res_dir = r'c:\Users\FR Abderrahmane\Documents\Revo app\android\app\src\main\res'
sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

for folder, sz in sizes.items():
    folder_path = os.path.join(res_dir, folder)
    os.makedirs(folder_path, exist_ok=True)
    resized = icon_512.resize((sz, sz), Image.Resampling.LANCZOS)
    resized.save(os.path.join(folder_path, 'ic_launcher.png'))
    print(f"Saved {folder}/ic_launcher.png ({sz}x{sz})")

print("Logo and Android app icons generated successfully!")
