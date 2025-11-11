# App Icon Instructions

The app icon has been removed from version control for licensing reasons.

## How to Add Your Own App Icon

### Option 1: Use a Free Icon Generator
1. Visit [AppIcon.co](https://www.appicon.co/) or [MakeAppIcon](https://makeappicon.com/)
2. Upload a 1024x1024 image (you can use a simple train emoji or DCC-themed design)
3. Download the generated icon set
4. Drag the PNG files into `MYDCC/Assets.xcassets/AppIcon.appiconset/`

### Option 2: Find Free Licensed Icons
Use icons from these sources with proper licensing:
- **The Noun Project** (with attribution or paid license)
- **Flaticon** (free with attribution)
- **Icons8** (free with link back)
- **Canva** (create your own using their free elements)

### Option 3: Create Your Own
1. Open any graphics editor (Preview, GIMP, Photoshop)
2. Create a 1024x1024 pixel square
3. Add a simple train icon, DCC text, or railroad-themed design
4. Export as PNG
5. Use Option 1 above to generate all required sizes

## Current Icon Location
The icon files should be placed in:
```
MYDCC/Assets.xcassets/AppIcon.appiconset/
```

## Important Notes
- App icons are **not tracked in git** (see `.gitignore`)
- You must add your own icon before building for distribution
- The current icon file on your local machine is fine for development
- Only add icons you have rights to use commercially

## Recommended Icon Content
For a DCC controller app, consider:
- Train silhouette
- Railroad tracks
- DCC command station graphic
- Throttle control icon
- Combination of the above

Make it simple, recognizable, and related to model railroading!
