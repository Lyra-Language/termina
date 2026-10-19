# Termina's icon

`termina.svg` is the source: a prompt and its cursor, and a star of Lyra's, on macOS's icon
grid (an 824-point body, 100 in from each edge of 1024), in the default theme's colours.
The other files are made from it and kept so that a build needs no SVG renderer:

- `Termina.icns` — the app's icon, copied into `Termina.app` by `../build.sh`.
- `termina.png` — 256 square, for the README.

To make them again (macOS, with `rsvg-convert` from Homebrew's `librsvg`):

```bash
mkdir -p /tmp/Termina.iconset
for n in 16 32 128 256 512; do
  rsvg-convert -w $n -h $n termina.svg -o /tmp/Termina.iconset/icon_${n}x${n}.png
  rsvg-convert -w $((n*2)) -h $((n*2)) termina.svg -o /tmp/Termina.iconset/icon_${n}x${n}@2x.png
done
iconutil -c icns /tmp/Termina.iconset -o Termina.icns
rsvg-convert -w 256 -h 256 termina.svg -o termina.png
```
