#!/bin/bash
# VenomOS build script — runs inside Docker container
set -e

echo ""
echo "[*] VenomOS Build System (Arch + BlackArch)"
echo ""

BUILD_SRC="/venomOS/build"
WORK_DIR="/tmp/venomos-work"
OUT_DIR="/tmp/venomos-out"

# Stage build files to container filesystem
echo "[*] Staging build profile..."
rm -rf "$WORK_DIR" "$OUT_DIR"
mkdir -p "$WORK_DIR" "$OUT_DIR"
rsync -a "$BUILD_SRC/" "$WORK_DIR/"

cd "$WORK_DIR"

# Build ISO with archiso
echo "[*] Building ISO — this will take 20-40 minutes..."
mkarchiso -v -w "$WORK_DIR/work" -o "$OUT_DIR" "$WORK_DIR"

# Copy to output volume
ISO=$(ls "$OUT_DIR"/*.iso 2>/dev/null | head -1)
if [ -z "$ISO" ]; then
    echo "[-] Build failed — no ISO produced."
    exit 1
fi

ISONAME="venomos-$(date +%Y%m%d)-x86_64.iso"
SIZE=$(du -h "$ISO" | cut -f1)

echo ""
echo "[+] ============================="
echo "[+] Build successful!"
echo "[+] ISO: $ISONAME ($SIZE)"
echo "[+] ============================="

echo "[*] Copying ISO to /output..."
dd if="$ISO" of="/output/$ISONAME" bs=4M conv=fsync status=progress
echo "[+] Done: /output/$ISONAME"
