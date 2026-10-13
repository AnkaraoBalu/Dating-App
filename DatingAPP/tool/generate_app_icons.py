"""Export Just2 logo sizes and platform icons from approved masters.
Run: python DatingAPP/tool/generate_app_icons.py (requires Pillow).
Masters: DatingAPP/tool/brand-masters. Never redraws the artwork.
"""
from pathlib import Path
import json
from PIL import Image, ImageOps

APP = Path(__file__).resolve().parents[1]
REPO = APP.parent
MASTERS = APP / 'tool/brand-masters'
WEB = REPO / 'frontend/public'
CREAM, FOREST = '#FFF9EF', '#102D26'
LANCZOS = Image.Resampling.LANCZOS


def save(image, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def fit(image, size):
    return ImageOps.contain(image, size, LANCZOS)


def centered(image, size, background=None, fraction=1.0):
    canvas = Image.new('RGBA', size, background or (0, 0, 0, 0))
    layer = fit(image, (round(size[0] * fraction), round(size[1] * fraction)))
    canvas.alpha_composite(layer, ((size[0] - layer.width) // 2,
                                  (size[1] - layer.height) // 2))
    return canvas


def main():
    mark = Image.open(MASTERS / 'mark.png').convert('RGBA')
    wordmark = Image.open(MASTERS / 'wordmark.png').convert('RGBA')
    inverse = Image.open(MASTERS / 'wordmark-light.png').convert('RGBA')
    # Opaque squares: each OS applies its own launcher corner mask.
    icon = centered(mark, (1024, 1024), CREAM, .88).convert('RGB')
    dark_icon = centered(mark, (1024, 1024), FOREST, .88).convert('RGB')
    foreground = centered(mark, (1024, 1024), fraction=.60)
    monochrome = Image.new('RGBA', foreground.size, 'white')
    monochrome.putalpha(foreground.getchannel('A'))
    assets = {
        'just2-wordmark.png': fit(wordmark, (1200, 600)),
        'just2-wordmark-light.png': fit(inverse, (1200, 600)),
        'just2-mark.png': fit(mark, (1024, 1024)),
        'just2-icon-light.png': icon,
        'just2-icon-dark.png': dark_icon,
        'just2-icon-peach.png': centered(mark, (1024, 1024), '#FFD9C1', .88).convert('RGB'),
    }
    for suffix, logo in [('', wordmark), ('-light', inverse)]:
        stacked = Image.new('RGBA', (1024, 1024))
        symbol, label = fit(mark, (640, 640)), fit(logo, (680, 340))
        stacked.alpha_composite(symbol, ((1024 - symbol.width) // 2, 18))
        stacked.alpha_composite(label, ((1024 - label.width) // 2, 650))
        assets[f'just2-stacked{suffix}.png'] = stacked
    for name, asset in assets.items():
        for folder in [WEB / 'images/branding', APP / 'assets/images/branding/just2']:
            save(asset, folder / name)
    for density, size in [('mdpi',48), ('hdpi',72), ('xhdpi',96), ('xxhdpi',144), ('xxxhdpi',192)]:
        res = APP / 'android/app/src/main/res'
        save(icon.resize((size, size), LANCZOS), res / f'mipmap-{density}/ic_launcher.png')
        adaptive_size = round(size * 2.25)
        for name, source in [('ic_launcher_foreground', foreground), ('ic_launcher_monochrome', monochrome)]:
            save(source.resize((adaptive_size, adaptive_size), LANCZOS), res / f'drawable-{density}/{name}.png')
    for platform in ['ios', 'macos']:
        folder = APP / platform / 'Runner/Assets.xcassets/AppIcon.appiconset'
        for entry in json.loads((folder / 'Contents.json').read_text())['images']:
            if 'filename' in entry:
                size = round(float(entry['size'].split('x')[0]) * float(entry['scale'].rstrip('x')))
                save(icon.resize((size, size), LANCZOS), folder / entry['filename'])
    for size in [192, 512]:
        for prefix in ['Icon-', 'Icon-maskable-']:
            source = centered(mark, (1024, 1024), CREAM, .66).convert('RGB') if 'maskable' in prefix else icon
            save(source.resize((size, size), LANCZOS), APP / f'web/icons/{prefix}{size}.png')
        save(icon.resize((size, size), LANCZOS), WEB / f'images/branding/icon-{size}.png')
    for size in [16, 32, 48]:
        save(icon.resize((size, size), LANCZOS), WEB / f'favicon-{size}.png')
    save(icon.resize((32, 32), LANCZOS), APP / 'web/favicon.png')
    save(icon.resize((180, 180), LANCZOS), WEB / 'apple-touch-icon.png')
    icon.save(WEB / 'favicon.ico', sizes=[(16,16), (32,32), (48,48), (64,64)])
    icon.save(APP / 'windows/runner/resources/app_icon.ico', sizes=[(16,16), (32,32), (48,48), (64,64), (128,128), (256,256)])
    save(centered(wordmark, (1200,630), CREAM, .78).convert('RGB'), WEB / 'images/branding/just2-social.png')
    print('Exported Just2 brand assets, native icons, favicons and social image.')


if __name__ == '__main__':
    main()
