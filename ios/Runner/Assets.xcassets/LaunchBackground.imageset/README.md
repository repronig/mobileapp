# Launch screen (native)

Full-bleed art matches the Flutter splash (`assets/backgrounds/bg_12.png`). From the **`mobile.repronig`** directory, regenerate if that asset changes:

```bash
SRC="assets/backgrounds/bg_12.png"
DEST="ios/Runner/Assets.xcassets/LaunchBackground.imageset"
sips --resampleWidth 430 "$SRC" --out "$DEST/LaunchBackground.png"
sips --resampleWidth 860 "$SRC" --out "$DEST/LaunchBackground@2x.png"
sips --resampleWidth 1290 "$SRC" --out "$DEST/LaunchBackground@3x.png"
for f in LaunchBackground.png LaunchBackground@2x.png LaunchBackground@3x.png; do
  sips -s format png "$DEST/$f" --out "$DEST/${f}.converted" && mv "$DEST/${f}.converted" "$DEST/$f"
done
```
