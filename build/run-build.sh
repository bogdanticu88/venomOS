#!/bin/bash
# VenomOS build launcher — run this from inside WSL2
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="$PROJECT_ROOT/build.log"
CONTAINER_NAME="venomos-build-$$"
OUTPUT_VOL="venomos-iso-$$"

STAGE_DIR="/tmp/venomos-stage-$$"
OUTPUT_DIR="/tmp/venomos-out-$$"
WIN_OUTPUT="$PROJECT_ROOT/output"

cleanup() {
    docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
    # Do NOT delete OUTPUT_VOL here — only remove it after confirmed ISO copy.
    # If extraction failed, leave the volume so it can be inspected/retried.
    rm -rf "$STAGE_DIR" "$OUTPUT_DIR"
}
trap cleanup EXIT

echo ""
echo " __   _____ _  _  ___  __  __  ___  ___ "
echo " \\ \\ / / __| \\| |/ _ \\|  \\/  |/ _ \\/ __|"
echo "  \\ V /| \`_|| .\` | (_) | |\\/| | (_) \\__ \\"
echo "   \_/ |___|_|\\_|\\___/|_|  |_|\\___/|___/"
echo ""
echo "[*] VenomOS Build Launcher (Arch + BlackArch)"
echo "[*] Project root : $PROJECT_ROOT"
echo "[*] Build log    : $LOG_FILE"
echo ""

command -v docker &>/dev/null || { echo "[-] Docker not found."; exit 1; }

# Persistent pacman cache volume — avoids re-downloading 3.5 GB each build
docker volume create venomos-pacman-cache &>/dev/null || true
# Named volume for ISO output — Docker-managed, survives container Dead state
docker volume create "$OUTPUT_VOL"
echo "[*] Output volume : $OUTPUT_VOL"

mkdir -p "$STAGE_DIR" "$OUTPUT_DIR"

echo "[*] Staging build files..."
rsync -a --exclude='output' --exclude='*.iso' --exclude='*.log' \
    "$SCRIPT_DIR/" "$STAGE_DIR/"

echo "[*] Building Docker image: venomos-builder..."
docker build -t venomos-builder "$STAGE_DIR" 2>&1 | tee "$LOG_FILE"

echo ""
echo "[*] Launching build container (20-40 min)..."
echo ""

# ISO is written to a named Docker volume (/output).
# Named volumes survive container exit/cleanup failures intact — unlike bind
# mounts which can lose data on WSL2 when Docker's --rm cleanup hits the
# resolv.conf chown bug (exit 125).
docker run \
    --name "$CONTAINER_NAME" \
    --privileged \
    -v "$STAGE_DIR:/venomOS/build:ro" \
    -v "venomos-pacman-cache:/var/cache/pacman/pkg" \
    -v "$OUTPUT_VOL:/output" \
    venomos-builder \
    /bin/bash /venomOS/build/build.sh 2>&1 | tee -a "$LOG_FILE" || true

echo "[*] Build container finished. Verifying output volume..."
docker run --rm \
    -v "$OUTPUT_VOL:/iso-src:ro" \
    alpine \
    sh -c 'echo "Volume contents:"; ls -lh /iso-src/'

# Extract ISO using a fresh Alpine container.
# A fresh container starts clean (no resolv.conf chown issue) and can mount
# the named volume directly alongside a bind-mount to the WSL2 host path.
echo "[*] Extracting ISO via helper container..."
docker run --rm \
    --name "venomos-extract-$$" \
    -v "$OUTPUT_VOL:/iso-src:ro" \
    -v "$OUTPUT_DIR:/iso-dest" \
    alpine \
    sh -c 'cp /iso-src/*.iso /iso-dest/ && echo "Extracted OK"' \
    2>&1 || echo "[-] Extraction step failed — check volume $OUTPUT_VOL manually"

ISO=$(find "$OUTPUT_DIR" -maxdepth 1 -name '*.iso' 2>/dev/null | head -1)
if [ -z "$ISO" ]; then
    echo "[-] No ISO found in $OUTPUT_DIR."
    echo "[-] Named volume '$OUTPUT_VOL' preserved for manual inspection."
    echo "[-] Run: docker run --rm -v ${OUTPUT_VOL}:/iso alpine ls /iso"
    echo "[-] Check $LOG_FILE for build errors."
    exit 1
fi

mkdir -p "$WIN_OUTPUT"
ISONAME=$(basename "$ISO")
echo "[*] Copying ISO to $WIN_OUTPUT..."
cp "$ISO" "$WIN_OUTPUT/$ISONAME"
SIZE=$(du -h "$WIN_OUTPUT/$ISONAME" | cut -f1)

# ISO safely on host — now we can remove the Docker volume
docker volume rm "$OUTPUT_VOL" 2>/dev/null || true

echo ""
echo "[+] ========================================="
echo "[+] Done!"
echo "[+] ISO : $WIN_OUTPUT/$ISONAME"
echo "[+] Size: $SIZE"
echo "[+] ========================================="
