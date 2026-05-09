#!/bin/bash
# VenomOS build script — runs inside Docker container
set -euo pipefail

echo ""
echo "[*] VenomOS Build System (Arch + BlackArch)"
echo ""

PROFILE_SRC="/venomOS/build"
PROFILE_DIR="/tmp/venomos-profile"
WORK_DIR="/tmp/venomos-work"
OUT_DIR="/output"

# Start from archiso's reference profile — gives us working syslinux/grub templates
echo "[*] Initialising profile from archiso releng base..."
rm -rf "$PROFILE_DIR"
cp -r /usr/share/archiso/configs/releng "$PROFILE_DIR"

# Overlay our VenomOS customisations on top
echo "[*] Overlaying VenomOS customisations..."
rsync -a \
    --exclude='Dockerfile' \
    --exclude='build.sh' \
    --exclude='run-build.sh' \
    --exclude='*.log' \
    --exclude='output' \
    "$PROFILE_SRC/" "$PROFILE_DIR/"

# Sanity check
for f in profiledef.sh packages.x86_64 pacman.conf airootfs; do
    [ -e "$PROFILE_DIR/$f" ] || { echo "[-] Missing profile file: $f"; exit 1; }
done

echo "[*] Profile layout:"
ls -la "$PROFILE_DIR/"
echo ""

mkdir -p "$WORK_DIR" "$OUT_DIR"

# Patch boot configs to explicitly name the CD-ROM device.
# Without this, the archiso hook searches by UUID via /dev/disk/by-uuid/,
# which fails in QEMU when modules.devname is absent (depmod not run due to
# Docker post-install hook segfaults). archisodevice overrides the UUID search.
echo "[*] Patching boot configs: adding archisodevice=/dev/sr0..."
find "$PROFILE_DIR/syslinux" -name "*.cfg" 2>/dev/null | while read -r f; do
    sed -i 's/archisobasedir=/archisodevice=\/dev\/sr0 archisobasedir=/' "$f"
done
if [ -f "$PROFILE_DIR/grub/grub.cfg" ]; then
    sed -i 's/archisobasedir=/archisodevice=\/dev\/sr0 archisobasedir=/' \
        "$PROFILE_DIR/grub/grub.cfg"
fi

echo "[*] Building ISO — this takes 20-40 minutes..."
mkarchiso -v -w "$WORK_DIR" -o "$OUT_DIR" "$PROFILE_DIR"

ISO=$(ls "$OUT_DIR"/*.iso 2>/dev/null | head -1)
if [ -z "$ISO" ]; then
    echo "[-] Build failed — no ISO produced."
    exit 1
fi

SIZE=$(du -h "$ISO" | cut -f1)
echo ""
echo "[+] ======================================"
echo "[+] Build successful!"
echo "[+] ISO : $ISO"
echo "[+] Size: $SIZE"
echo "[+] ======================================"
