import os
from PIL import Image

icon_512 = Image.open(r'c:\Users\FR Abderrahmane\Documents\Revo app\assets\images\app_icon.png')

web_dir = r'c:\Users\FR Abderrahmane\Documents\Revo app\web'

# Favicon 32x32
fav = icon_512.resize((32, 32), Image.Resampling.LANCZOS)
fav.save(os.path.join(web_dir, 'favicon.png'))

# Icons
icons_dir = os.path.join(web_dir, 'icons')
os.makedirs(icons_dir, exist_ok=True)
icon_512.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, 'Icon-192.png'))
icon_512.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, 'Icon-512.png'))
icon_512.resize((192, 192), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, 'Icon-maskable-192.png'))
icon_512.resize((512, 512), Image.Resampling.LANCZOS).save(os.path.join(icons_dir, 'Icon-maskable-512.png'))

print("Web icons updated successfully!")
