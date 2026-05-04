#!/bin/bash
# Runs inside the Docker build container.
set -e

cd /venomOS/build

echo ""
echo "[*] VenomOS Build System — Stage ${VENOM_STAGE:-1}"
echo "[*] Working directory: $(pwd)"
echo ""

# Clean any previous build state
echo "[*] Cleaning previous build artifacts..."
lb clean --purge 2>/dev/null || true

# Initialize live-build config from auto/config
echo "[*] Initializing live-build configuration..."
bash auto/config

# Run the build
echo "[*] Building ISO — this will take 20-40 minutes..."
lb build 2>&1 | tee /tmp/lb-build.log

# Copy log to output
cp /tmp/lb-build.log /output/build.log 2>/dev/null || true

# Check for output
if ls /venomOS/build/*.iso 1>/dev/null 2>&1; then
    ISO=$(ls /venomOS/build/*.iso | head -1)
    ISONAME=$(basename "$ISO")
    SIZE=$(du -h "$ISO" | cut -f1)

    echo ""
    echo "[+] ============================="
    echo "[+] Build successful!"
    echo "[+] ISO: $ISONAME ($SIZE)"
    echo "[+] ============================="

    mkdir -p /output
    cp "$ISO" "/output/$ISONAME"
    echo "[+] ISO copied to /output/$ISONAME"
else
    echo "[-] Build failed — no ISO produced."
    echo "[-] Check /output/build.log for details."
    exit 1
fi
