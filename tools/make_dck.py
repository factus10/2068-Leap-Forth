#!/usr/bin/env python3
"""Wrap a 16K DOCK-cartridge ROM image (a CARTRIDGE build of rom/forth_boot.asm
or rom/forth_demo_blackjack.asm) as a .dck file for emulators.

DCK is the Warajevo/Fuse Timex cartridge container: a 9-byte header --
bank id (0 = DOCK, 254 = EXROM, 255 = HOME) then one type byte per 8K
chunk (0 = absent, 1 = RAM, 2 = ROM data follows, 3 = RAM data follows)
-- followed by 8K of data for every chunk marked 2 or 3. A 16K image
at $0000 is DOCK chunks 0 and 1, so the header is 00 02 02 00 00 00 00 00 00.

Fuse:    fuse --machine ts2068 --dock forth_boot.dck
ZEsarUX: smartload the .dck, then hard reset.

Usage:  tools/make_dck.py build/forth_boot_cart.bin build/forth_boot.dck
"""
import sys

src, dst = sys.argv[1], sys.argv[2]
img = open(src, 'rb').read()
if len(img) != 16384:
    sys.exit(f"{src}: expected a 16384-byte image, got {len(img)}")
if img[1] != 0x01:
    sys.exit(f"{src}: byte 1 is ${img[1]:02X}, not $01 -- this is not an LROS image "
             "(build with -DCARTRIDGE, e.g. make forth-boot-cart)")
with open(dst, 'wb') as f:
    f.write(bytes([0x00, 2, 2, 0, 0, 0, 0, 0, 0]))
    f.write(img)
print(f"wrote {dst} ({len(img) + 9} bytes; LROS start ${img[3]:02X}{img[2]:02X}, chunk spec ${img[4]:02X})")
