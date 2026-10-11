"""Resize the approved project logo for native launchers and the web (macOS sips)."""
from pathlib import Path
import json
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'assets/images/branding/logo.png'

def save(path, size):
    subprocess.run(['sips', '-z', str(size), str(size), str(SOURCE), '--out', str(ROOT / path)],
                   check=True, capture_output=True)

for density, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    save(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', size)
    save(f'android/app/src/main/res/drawable-{density}/ic_launcher_foreground.png', round(size * 2.25))
for platform in ['ios', 'macos']:
    folder = Path(platform) / 'Runner/Assets.xcassets/AppIcon.appiconset'
    for entry in json.loads((ROOT / folder / 'Contents.json').read_text())['images']:
        if 'filename' in entry:
            size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
            save(folder / entry['filename'], size)
for size in [192, 512]:
    for prefix in ['Icon-', 'Icon-maskable-']:
        save(f'web/icons/{prefix}{size}.png', size)
save('web/favicon.png', 32)
with tempfile.TemporaryDirectory() as temp:
    path = Path(temp) / 'icon.png'
    save(path, 256)
    png = path.read_bytes()
    (ROOT / 'windows/runner/resources/app_icon.ico').write_bytes(
        struct.pack('<HHH', 0, 1, 1) + struct.pack('<BBBBHHII', 0, 0, 0, 0, 1, 32, len(png), 22) + png)
print('Updated native launcher icons and web favicon from', SOURCE)
