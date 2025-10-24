# App Icon Requirements for LocalFileConverter

**For App Store Submission**

---

## Required Icon Sizes

The app needs an **AppIcon.appiconset** folder with the following sizes:

| Size | Purpose | Filename |
|------|---------|----------|
| 16x16 | Menu bar, Finder | icon_16x16.png |
| 16x16@2x (32x32) | Menu bar, Finder (Retina) | icon_16x16@2x.png |
| 32x32 | Dock, Finder | icon_32x32.png |
| 32x32@2x (64x64) | Dock, Finder (Retina) | icon_32x32@2x.png |
| 128x128 | Finder, Dock | icon_128x128.png |
| 128x128@2x (256x256) | Finder, Dock (Retina) | icon_128x128@2x.png |
| 256x256 | Finder, Dock | icon_256x256.png |
| 256x256@2x (512x512) | Finder, Dock (Retina) | icon_256x256@2x.png |
| 512x512 | Finder, Dock | icon_512x512.png |
| 512x512@2x (1024x1024) | App Store, Finder | icon_512x512@2x.png |

---

## Design Guidelines

### **Theme**
The app is a **file conversion utility** with a focus on:
- Local processing (privacy-first)
- Multiple file types (images, videos, audio, documents, archives)
- Speed and simplicity

### **Suggested Design Concepts**

#### **Concept 1: Circular Arrows**
- Two curved arrows forming a circle (conversion/transformation)
- Modern gradient: purple to blue (matching app's color scheme)
- Clean, minimal design
- File icon in center (optional)

#### **Concept 2: File Transformation**
- Two file icons with an arrow between them
- Left file shows various format symbols
- Right file shows converted format
- Gradient background

#### **Concept 3: Abstract Converter**
- Funnel or filter shape
- Files entering from top in various forms
- Unified output at bottom
- Modern gradient style

### **Color Palette** (from app)
```
Primary: Blue (#0077FF) to Purple (#AF52DE)
Secondary: Pink to Orange (images), Blue to Cyan (videos)
Background: System adaptive (light/dark mode support)
```

### **Style Requirements**
- ✅ Modern, flat design
- ✅ Clear at 16x16 (smallest size)
- ✅ Works in both light and dark modes
- ✅ Professional appearance
- ✅ Unique (not generic)
- ❌ No text/words in icon
- ❌ Avoid overly complex details

---

## How to Create the Icons

### **Option 1: Design Tool (Recommended)**
1. Use **Figma**, **Sketch**, or **Adobe Illustrator**
2. Create design at 1024x1024
3. Export all required sizes
4. Use **Image2Icon** or **Icon Slate** to generate .icns file

### **Option 2: Online Tool**
1. Design at 1024x1024 in **Canva** or **Photopea**
2. Use **cloudconvert.com** or **iconverticons.com**
3. Upload 1024x1024 PNG
4. Download complete iconset

### **Option 3: macOS Built-in (Quick & Simple)**
1. Create 1024x1024 PNG
2. Open in **Preview**
3. File → Export → Format: .icns
4. Or use `iconutil` command-line tool

---

## Installation Steps

### **Step 1: Create Assets Folder**
```bash
mkdir -p Assets.xcassets/AppIcon.appiconset
```

### **Step 2: Add Contents.json**
Create `Assets.xcassets/AppIcon.appiconset/Contents.json`:
```json
{
  "images" : [
    {
      "filename" : "icon_16x16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_16x16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "icon_32x32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_32x32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "icon_128x128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_128x128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "icon_256x256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_256x256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "icon_512x512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "icon_512x512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### **Step 3: Add Icon Files**
Place all generated PNG files in `Assets.xcassets/AppIcon.appiconset/`

### **Step 4: Update Xcode Project**
1. Open project in Xcode
2. Select project in navigator
3. Go to "General" tab
4. Under "App Icon", select the AppIcon set

---

## Quick Command-Line Generation (macOS)

If you have a 1024x1024 PNG named `icon_1024.png`:

```bash
# Create folder
mkdir -p Assets.xcassets/AppIcon.appiconset

# Generate all sizes using sips
sips -z 16 16 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_16x16.png
sips -z 32 32 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png
sips -z 32 32 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_32x32.png
sips -z 64 64 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png
sips -z 128 128 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_128x128.png
sips -z 256 256 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png
sips -z 256 256 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_256x256.png
sips -z 512 512 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png
sips -z 512 512 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_512x512.png
sips -z 1024 1024 icon_1024.png --out Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png
```

---

## Validation

After adding icons, validate with:
```bash
# Check all files exist
ls -la Assets.xcassets/AppIcon.appiconset/

# Verify sizes
file Assets.xcassets/AppIcon.appiconset/*.png

# Build and check
xcodebuild -showBuildSettings | grep ASSETCATALOG
```

---

## Resources

- **Apple Human Interface Guidelines**: https://developer.apple.com/design/human-interface-guidelines/app-icons
- **Icon Generator Tools**:
  - https://www.appicon.co/
  - https://makeappicon.com/
  - https://iconverticons.com/
- **Free Icon Tools**:
  - Image2Icon (Mac App Store)
  - Icon Slate (Mac App Store)

---

## Testing

1. Build app in Xcode
2. Check Dock icon appearance
3. Check Finder icon at different sizes
4. Test in both light and dark modes
5. Verify menu bar icon (if applicable)

---

**Note:** This is a manual step that requires graphic design work. The files listed above must be created before App Store submission.
