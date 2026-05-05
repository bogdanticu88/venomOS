#!/bin/bash
# Run this from WSL2 to build the VenomOS ISO using Docker.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_ROOT/output"

echo ""
echo " __   _____ _  _  ___  __  __  ___  ___ "
echo " \ \ / / __| \| |/ _ \|  \/  |/ _ \/ __|"
echo "  \ V /| _|| .\` | (_) | |\/| | (_) \__ \\"
echo "   \_/ |___|_|\_|\___/|_|  |_|\___/|___/"
echo ""
echo "[*] VenomOS Build Launcher"
echo "[*] Project root: $PROJECT_ROOT"
echo ""

# Ensure Docker is available
if ! command -v docker &>/dev/null; then
    echo "[-] Docker not found. Install Docker Desktop with WSL2 backend."
    exit 1
fi

echo "[*] Building Docker image: venomos-builder..."
docker build -t venomos-builder "$SCRIPT_DIR"

mkdir -p "$OUTPUT_DIR"

echo "[*] Launching build container..."
MSYS_NO_PATHCONV=1 docker run --rm \
    --privileged \
    -v "$PROJECT_ROOT:/venomOS" \
    -v "$OUTPUT_DIR:/output" \
    venomos-builder \
    /bin/bash /venomOS/build/build.sh

echo ""
echo "[+] Build complete. ISO saved to: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"/*.iso 2>/dev/null || echo "No ISO files found in output."
