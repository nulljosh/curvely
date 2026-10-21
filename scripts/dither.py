# usage: dither.py <engraving.jpg> <out.png> <x0,y0,x1,y1 crop fractions> <width>
# landing/art/apollo.png: Met Lafreri engraving, crop 0.12,0.10,0.95,0.475, width 1800
# Halftone mask from a public domain engraving: bright areas become dots (opaque), dark areas stay clear.
import sys
from PIL import Image, ImageOps, ImageFilter
src, out, box, width = sys.argv[1], sys.argv[2], [float(v) for v in sys.argv[3].split(',')], int(sys.argv[4])
im = Image.open(src).convert('L')
w, h = im.size
im = im.crop((int(box[0]*w), int(box[1]*h), int(box[2]*w), int(box[3]*h)))
im = im.resize((width, int(im.height * width / im.width)), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.1))
im = ImageOps.autocontrast(im, cutoff=1)
im = im.point(lambda v: int(255 * (v / 255) ** 1.35))
bw = im.convert('1')  # Floyd-Steinberg
mask = bw.convert('L')
Image.merge('LA', (Image.new('L', mask.size, 255), mask)).save(out, optimize=True)
print(out, mask.size)
