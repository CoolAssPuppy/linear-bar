# DMG assets

The release flow builds a styled DMG via `create-dmg`. It expects two files in this folder:

- **`background.tiff`** — the DMG window background. Required. Created by combining the 1x and 2x PNGs:
  ```bash
  tiffutil -cathidpicheck background@1x.png background@2x.png -out background.tiff
  ```
  The @1x version is 600 × 400 and the @2x version is 1200 × 800. Both come from the Paper artboard "DMG Install Background" — update that first and re-export.

- **`VolumeIcon.icns`** — optional. Shown as the mounted volume icon in Finder. Generate from a 1024 × 1024 PNG via:
  ```bash
  mkdir icon.iconset
  sips -z 16 16   source.png --out icon.iconset/icon_16x16.png
  sips -z 32 32   source.png --out icon.iconset/icon_16x16@2x.png
  sips -z 32 32   source.png --out icon.iconset/icon_32x32.png
  sips -z 64 64   source.png --out icon.iconset/icon_32x32@2x.png
  sips -z 128 128 source.png --out icon.iconset/icon_128x128.png
  sips -z 256 256 source.png --out icon.iconset/icon_128x128@2x.png
  sips -z 256 256 source.png --out icon.iconset/icon_256x256.png
  sips -z 512 512 source.png --out icon.iconset/icon_256x256@2x.png
  sips -z 512 512 source.png --out icon.iconset/icon_512x512.png
  cp source.png                     icon.iconset/icon_512x512@2x.png
  iconutil -c icns icon.iconset -o VolumeIcon.icns
  rm -rf icon.iconset
  ```

The build script falls back gracefully if `VolumeIcon.icns` is missing, but `background.tiff` is mandatory.
