# Curvely brand kit and design system

a sine wave with one plotted point

## The mark
One bold flat white glyph on an accent gradient tile. No text, no outline, no emblem.

- `../Curvely.icon` is the source of truth (Icon Composer). Light and dark fills are set in it.
- `../icon.svg` is the flat copy for READMEs (shown at 80 px). `icon-1024.png` is the App Store icon, no alpha.
- `mark.svg` is the glyph alone in `currentColor` for your own background.
- Clear space equal to the width of the glyph's thickest stroke. Smallest size 16 px.

## Colour
| Role | Value |
|---|---|
| Accent | `#0f86c9` |
| Gradient top | `#38c8f0` |
| Text | `#1d1d1f` light, `#f5f5f7` dark |
| Background | `#ffffff` light, `#000000` dark |
| Surface | `#f5f5f7` light, `#1c1c1e` dark |

The accent is for actions, links and the icon. Never brown, beige, purple or teal.

## Type
**Curvely Sans**, in `fonts/`: Inter (SIL OFL 1.1) renamed, with the curly quotes redrawn as waves, a crest to open and a trough to close. `../scripts/gen_font.py` builds it and `--check` verifies it. Weights ExtraLight 200 (display caps), Regular, Medium, Semibold, Bold. The system stack is the fallback: `-apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", Helvetica, Arial, sans-serif`. Scale 34/41 bold, 22/28, 17/24, 15/20, 13/18.

## Glass
Floating panes are Liquid Glass: `glassEffect` on iOS 26 and macOS 26, a blurred material before that, `backdrop-filter: blur(28px) saturate(180%)` on the web. A lit top edge and a hairline, never a drop shadow.

## Space and shape
- Space on the 8 point grid: 4, 8, 12, 16, 24, 32, 48. Side margin 20. Reading column 680.
- Radii: cards 28, grouped lists 20, controls fully round, icon 22 percent.
- Controls are 48 points tall capsules, one height in a row. Focus is a 4 point ring at 30 percent accent.
- Motion is 0.2 s ease and honours reduced motion.

`tokens.css` holds the app's accent. Everything else comes from the shared token file.
